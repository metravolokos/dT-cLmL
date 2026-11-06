// Dart's upstream just_audio StreamAudioSource is explicitly marked
// experimental. This narrowly scoped opt-in is documented in ADR-0003.
// ignore_for_file: experimental_member_use

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import '../../domain/remote_track.dart';
import '../../cloud/cloud_mail_webdav.dart';

typedef RangeFetcher =
    Future<Uint8List> Function(String path, int offset, int length);

/// Converts authenticated, fixed-size WebDAV GETs into a seekable byte stream.
/// Never embeds the user's Authorization header in a URL or local proxy.
class CloudRangeAudioSource extends StreamAudioSource {
  CloudRangeAudioSource(
    this.track,
    this.fetcher, {
    Object? mediaTag,
    this.onRangeFailure,
    this.onRangeSuccess,
  }) : super(tag: mediaTag);

  static const int chunkSize = 64 * 1024;

  final RemoteTrack track;
  final RangeFetcher fetcher;

  /// Emits only fixed error codes, never authenticated URLs or exceptions.
  final void Function(String code)? onRangeFailure;

  /// Signals a successfully received byte chunk, never exposing media bytes.
  final void Function()? onRangeSuccess;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final first = start ?? 0;
    final last = end ?? track.sizeBytes;
    if (first < 0 || last < first || last > track.sizeBytes) {
      throw RangeError('Out-of-bounds streaming request');
    }

    return StreamAudioResponse(
      rangeRequestsSupported: true,
      sourceLength: track.sizeBytes,
      contentLength: last - first,
      offset: first,
      contentType: _mediaType(track.fileName),
      stream: _rangeBytes(first, last),
    );
  }

  Stream<List<int>> _rangeBytes(int start, int end) async* {
    for (var offset = start; offset < end;) {
      final length = math.min(chunkSize, end - offset);
      try {
        final part = await fetcher(track.path, offset, length);
        if (part.length != length) {
          throw StateError('Remote response has unexpected byte count');
        }
        onRangeSuccess?.call();
        yield part;
      } on CloudMailException catch (error) {
        // P11 means an authenticated WebDAV range failed; suffix is a safe
        // enum name, not the original server response or a user file path.
        onRangeFailure?.call('P11-${error.code.name}');
        rethrow;
      } catch (_) {
        onRangeFailure?.call('P12');
        rethrow;
      }
      offset += length;
    }
  }

  static String _mediaType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.flac')) return 'audio/flac';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.ogg') || lower.endsWith('.opus')) return 'audio/ogg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    return 'application/octet-stream';
  }
}
