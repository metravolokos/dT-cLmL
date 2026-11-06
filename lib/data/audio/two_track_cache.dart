import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../cloud/cloud_mail_webdav.dart';
import '../../domain/remote_track.dart';

typedef CacheRangeFetch =
    Future<Uint8List> Function(
      String path,
      int offset,
      int length, {
      WebDavRequestCancellation? cancellation,
    });

/// Keeps only the current and next audio files as temporary storage.
class TwoTrackAudioCache {
  TwoTrackAudioCache._(this._directory, this._fetch, this._onProgress);

  static const int maximumBytes = 512 * 1024 * 1024;
  static const int rangeBytes = 64 * 1024;

  final Directory _directory;
  final CacheRangeFetch _fetch;
  final void Function(RemoteTrack track, int downloadedBytes)? _onProgress;
  final Map<String, _CacheSlot> _slots = {};
  bool _closed = false;

  static Future<TwoTrackAudioCache> open({
    required CacheRangeFetch fetch,
    Directory? directory,
    void Function(RemoteTrack track, int downloadedBytes)? onProgress,
  }) async {
    final target =
        directory ??
        Directory(p.join((await getTemporaryDirectory()).path, 'cloud_audio'));
    await target.create(recursive: true);
    for (final entry in target.listSync(followLinks: false)) {
      if (entry is File &&
          (entry.path.endsWith('.part') || entry.path.endsWith('.ready'))) {
        await entry.delete();
      }
    }
    return TwoTrackAudioCache._(target, fetch, onProgress);
  }

  String _key(RemoteTrack track) {
    final source =
        '${track.path}\u0000${track.etag ?? ''}\u0000${track.sizeBytes}';
    return sha256.convert(utf8.encode(source)).toString();
  }

  _CacheSlot _create(RemoteTrack track) {
    final id = _key(track);
    return _CacheSlot(track, File(p.join(_directory.path, '$id.part')));
  }

  /// Reuses a prefetched next-track file during promotion.
  Future<void> configure(RemoteTrack current, RemoteTrack? next) async {
    if (_closed) throw StateError('Audio cache closed');
    final candidates = <RemoteTrack>[];
    if (current.sizeBytes > 0 && current.sizeBytes <= maximumBytes) {
      candidates.add(current);
      if (next != null &&
          next.path != current.path &&
          next.sizeBytes > 0 &&
          next.sizeBytes <= maximumBytes - current.sizeBytes) {
        candidates.add(next);
      }
    }
    final allowed = candidates.map(_key).toSet();
    final retired = <_CacheSlot>[];
    for (final entry in _slots.entries.toList()) {
      if (!allowed.contains(entry.key)) {
        _slots.remove(entry.key);
        entry.value.cancel();
        retired.add(entry.value);
      }
    }
    for (final slot in retired) {
      await slot.task;
      if (await slot.file.exists()) await slot.file.delete();
    }
    for (final track in candidates) {
      _slots.putIfAbsent(_key(track), () => _create(track));
    }
    final now = _slots[_key(current)];
    if (now != null) _onProgress?.call(current, now.downloaded);
    final following = next == null ? null : _slots[_key(next)];
    if (now != null) unawaited(_warmInOrder(now, following));
  }

  Future<void> _warmInOrder(_CacheSlot current, _CacheSlot? next) async {
    await _warm(current);
    if (!_closed &&
        !current.cancelled &&
        current.complete &&
        next != null &&
        !next.cancelled &&
        _slots.containsValue(next)) {
      await _warm(next);
    }
  }

  Future<void> _warm(_CacheSlot slot) {
    if (slot.task != null) return slot.task!;
    final task = _download(slot);
    slot.task = task;
    return task;
  }

  Future<void> _download(_CacheSlot slot) async {
    if (slot.complete || slot.cancelled) return;
    RandomAccessFile? file;
    try {
      file = await slot.file.open(mode: FileMode.write);
      for (var offset = 0; offset < slot.track.sizeBytes;) {
        if (slot.cancelled || _closed) return;
        final length = math.min(rangeBytes, slot.track.sizeBytes - offset);
        final token = WebDavRequestCancellation();
        slot.cancellation = token;
        final bytes = await _fetch(
          slot.track.path,
          offset,
          length,
          cancellation: token,
        );
        if (slot.cancelled || _closed) return;
        if (bytes.length != length) {
          throw const FormatException('Unexpected remote chunk length');
        }
        await file.writeFrom(bytes);
        slot.downloaded += length;
        if (!slot.cancelled && !_closed) {
          _onProgress?.call(slot.track, slot.downloaded);
        }
        offset += length;
        slot.cancellation = null;
      }
      await file.flush();
      await file.close();
      file = null;
      if (slot.cancelled || _closed) return;
      final readyPath = slot.file.path.replaceFirst(
        RegExp(r'\.part$'),
        '.ready',
      );
      slot.file = await slot.file.rename(readyPath);
      slot.complete = true;
    } catch (_) {
      // Foreground playback can fall back to verified remote Range requests.
    } finally {
      slot.cancellation = null;
      await file?.close();
    }
  }

  /// Locally reads any downloaded byte interval, including after seek.
  Future<Uint8List> read(String path, int offset, int length) async {
    if (_closed) throw StateError('Audio cache closed');
    if (offset < 0 || length < 1 || length > rangeBytes) {
      throw RangeError('Invalid bounded audio read');
    }
    _CacheSlot? slot;
    for (final current in _slots.values) {
      if (current.track.path == path) {
        slot = current;
        break;
      }
    }
    if (slot != null && offset + length > slot.track.sizeBytes) {
      throw RangeError('Audio offset beyond end of file');
    }
    if (slot != null && slot.downloaded >= offset + length && !slot.cancelled) {
      RandomAccessFile? file;
      try {
        file = await slot.file.open(mode: FileMode.read);
        await file.setPosition(offset);
        final bytes = await file.read(length);
        if (bytes.length == length) return Uint8List.fromList(bytes);
      } on FileSystemException {
        // File may have been removed on a concurrent track switch.
      } finally {
        await file?.close();
      }
    }
    return _fetch(path, offset, length);
  }

  bool isComplete(RemoteTrack track) => _slots[_key(track)]?.complete ?? false;

  /// Progress is scoped by path, ETag and length, not just the track title.
  double fractionFor(RemoteTrack track) {
    if (track.sizeBytes <= 0) return 0;
    final loaded = _slots[_key(track)]?.downloaded ?? 0;
    return (loaded / track.sizeBytes).clamp(0.0, 1.0);
  }

  int get cachedFileCount => _slots.length;
  int get downloadedBytes =>
      _slots.values.fold<int>(0, (total, slot) => total + slot.downloaded);

  Future<void> clear() async {
    final old = _slots.values.toList();
    _slots.clear();
    for (final slot in old) {
      slot.cancel();
    }
    for (final slot in old) {
      await slot.task;
      if (await slot.file.exists()) await slot.file.delete();
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await clear();
  }
}

class _CacheSlot {
  _CacheSlot(this.track, this.file);

  final RemoteTrack track;
  File file;
  int downloaded = 0;
  bool complete = false;
  bool cancelled = false;
  WebDavRequestCancellation? cancellation;
  Future<void>? task;

  void cancel() {
    cancelled = true;
    cancellation?.cancel();
  }
}
