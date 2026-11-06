import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

// Top-level isolate entry prevents capturing the cache instance and Futures.
Future<Uint8List?> _encodeInWorker(Uint8List source) =>
    Isolate.run(() => encodeCoverThumbnail(source));

/// Persistent, bounded, resized cover images. Only hashed names reach disk.
/// Callers include the account, remote ETag and size in the source identity.
class CoverThumbnailCache {
  CoverThumbnailCache(this.directory, {this.maxBytes = 64 * 1024 * 1024});

  final Directory directory;
  final int maxBytes;
  final Map<String, Future<Uint8List?>> _pending = {};
  Future<void> _maintenance = Future<void>.value();

  static const int _maximumSourceBytes = 5 * 1024 * 1024;
  static const int _maximumThumbnailBytes = 1024 * 1024;

  Future<Uint8List?> read(
    String identity,
    Future<Uint8List?> Function() fetchSource,
  ) {
    final id = sha256.convert(identity.codeUnits).toString();
    final existing = _pending[id];
    if (existing != null) return existing;
    final request = _read(id, fetchSource);
    _pending[id] = request;
    return request.whenComplete(() {
      if (identical(_pending[id], request)) _pending.remove(id);
    });
  }

  Future<Uint8List?> _read(
    String id,
    Future<Uint8List?> Function() fetchSource,
  ) async {
    try {
      await directory.create(recursive: true);
      final destination = File(p.join(directory.path, '$id.jpg'));
      if (await destination.exists()) {
        try {
          final length = await destination.length();
          if (length > 0 && length <= _maximumThumbnailBytes) {
            final bytes = await destination.readAsBytes();
            await destination.setLastModified(DateTime.now());
            return bytes;
          }
          await destination.delete();
        } on FileSystemException {
          // A corrupt or concurrently removed cache entry is a miss.
        }
      }

      final source = await fetchSource();
      if (source == null ||
          source.isEmpty ||
          source.length > _maximumSourceBytes) {
        return null;
      }

      final bytes = await _encodeInWorker(source);
      if (bytes == null || bytes.length > _maximumThumbnailBytes) return null;
      final temporary = File(p.join(directory.path, '$id.tmp'));
      await temporary.writeAsBytes(bytes, flush: true);
      try {
        await temporary.rename(destination.path);
      } on FileSystemException {
        if (await destination.exists()) {
          await temporary.delete();
        } else {
          rethrow;
        }
      }
      _maintenance = _maintenance.catchError((Object _) {}).then((_) async {
        try {
          await _trimToBudget();
        } on FileSystemException {
          // The OS or a disconnect can remove the directory while trimming.
        }
      });
      unawaited(_maintenance);
      return bytes;
    } on FileSystemException {
      // Artwork may still be read later even when device storage is blocked.
      return null;
    } on img.ImageException {
      return null;
    }
  }

  Future<void> _trimToBudget() async {
    if (maxBytes < 1 || !await directory.exists()) return;
    final entries = <File>[];
    var total = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.jpg')) continue;
      try {
        total += await entity.length();
        entries.add(entity);
      } on FileSystemException {
        // Concurrent removal is harmless.
      }
    }
    if (total <= maxBytes) return;
    final ordered = <(File, DateTime, int)>[];
    for (final file in entries) {
      try {
        final stat = await file.stat();
        ordered.add((file, stat.modified, stat.size));
      } on FileSystemException {
        // Concurrent removal is harmless.
      }
    }
    ordered.sort((a, b) => a.$2.compareTo(b.$2));
    for (final (file, _, size) in ordered) {
      if (total <= maxBytes) break;
      try {
        await file.delete();
        total -= size;
      } on FileSystemException {
        // A concurrent writer or reader may already have removed this file.
      }
    }
  }
}

/// Pure and isolate-safe converter: JPEG/PNG only, no accidental huge decode.
Uint8List? encodeCoverThumbnail(Uint8List source) {
  const maxPixels = 20 * 1024 * 1024;
  img.Image? picture;
  if (source.length >= 3 && source[0] == 0xff && source[1] == 0xd8) {
    picture = img.JpegDecoder(maxPixels: maxPixels).decode(source, frame: 0);
  } else if (source.length >= 8 &&
      source[0] == 0x89 &&
      source[1] == 0x50 &&
      source[2] == 0x4e &&
      source[3] == 0x47) {
    picture = img.PngDecoder(maxPixels: maxPixels).decode(source, frame: 0);
  } else {
    return null;
  }
  if (picture == null || picture.width < 1 || picture.height < 1) return null;
  const maxEdge = 640;
  final larger = picture.width > picture.height
      ? picture.width
      : picture.height;
  if (larger > maxEdge) {
    picture = picture.width >= picture.height
        ? img.copyResize(picture, width: maxEdge)
        : img.copyResize(picture, height: maxEdge);
  } else {
    picture = img.bakeOrientation(picture);
  }
  return img.encodeJpg(picture, quality: 85);
}
