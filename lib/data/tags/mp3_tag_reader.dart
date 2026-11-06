import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

typedef Mp3RangeReader =
    Future<Uint8List> Function(String path, int offset, int length);

class Mp3Tags {
  const Mp3Tags({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.duration,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final Duration? duration;
}

/// A bounded ID3v2.3/v2.4 and ID3v1 reader. Skips APIC picture frames by
/// seeking to their declared offset; no whole MP3 file download occurs.
class Mp3TagReader {
  Mp3TagReader(this.readRange);

  final Mp3RangeReader readRange;
  static const int maximumReadBytes = 64 * 1024;
  static const int maximumTagBytes = 32 * 1024 * 1024;
  static const int maximumTextBytes = 128 * 1024;

  Future<Uint8List> _get(
    String path,
    int offset,
    int count,
    int fileSize,
  ) async {
    if (offset < 0 || count < 0 || offset + count > fileSize) {
      throw const FormatException('ID3 range outside file');
    }
    if (count == 0) return Uint8List(0);
    final bytes = BytesBuilder(copy: false);
    for (var cursor = 0; cursor < count;) {
      final take = math.min(maximumReadBytes, count - cursor);
      final chunk = await readRange(path, offset + cursor, take);
      if (chunk.length != take) throw const FormatException('Short ID3 read');
      bytes.add(chunk);
      cursor += take;
    }
    return bytes.takeBytes();
  }

  Future<Mp3Tags> parse(String path, int fileSize) async {
    if (fileSize < 10) return const Mp3Tags();
    final head = await _get(path, 0, math.min(fileSize, 16384), fileSize);
    Future<Uint8List> at(int offset, int count) async {
      if (offset >= 0 && offset + count <= head.length) {
        return Uint8List.sublistView(head, offset, offset + count);
      }
      return _get(path, offset, count, fileSize);
    }

    if (head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) {
      final version = head[3];
      if (version != 3 && version != 4) {
        return const Mp3Tags();
      }
      final flags = head[5];
      // Global unsynchronisation needs a separate de-escaping pass.
      if (flags & 0x80 != 0) return const Mp3Tags();
      final tagSize = _syncSafe(head, 6);
      if (tagSize > maximumTagBytes || tagSize + 10 > fileSize) {
        throw const FormatException('Invalid ID3 metadata size');
      }
      final end = 10 + tagSize;
      var cursor = 10;
      if (flags & 0x40 != 0) {
        final ext = await at(cursor, 4);
        final extraSize = version == 4
            ? _syncSafe(ext, 0)
            : ByteData.sublistView(ext).getUint32(0, Endian.big);
        cursor += version == 4 ? extraSize : extraSize + 4;
      }
      final values = <String, String>{};
      var frames = 0;
      while (cursor + 10 <= end && ++frames <= 1024) {
        final header = await at(cursor, 10);
        if (header[0] == 0) break;
        final id = ascii.decode(header.sublist(0, 4), allowInvalid: true);
        if (!RegExp(r'^[A-Z0-9]{4}$').hasMatch(id)) break;
        final length = version == 4
            ? _syncSafe(header, 4)
            : ByteData.sublistView(header).getUint32(4, Endian.big);
        cursor += 10;
        if (length < 0 || cursor + length > end) {
          throw const FormatException('ID3 frame outside tag');
        }
        if (const {
          'TIT2',
          'TPE1',
          'TPE2',
          'TALB',
          'TRCK',
          'TPOS',
          'TLEN',
        }.contains(id)) {
          if (length > maximumTextBytes) {
            throw const FormatException('Oversized ID3 text frame');
          }
          final raw = await at(cursor, length);
          if (raw.isNotEmpty) {
            final decoded = _decodeText(raw);
            if (decoded.isNotEmpty) values.putIfAbsent(id, () => decoded);
          }
        }
        // APIC and all other frames skip by offset, never downloading image.
        cursor += length;
      }
      final elapsedMs = int.tryParse(values['TLEN'] ?? '');
      return Mp3Tags(
        title: values['TIT2'],
        artist: values['TPE1'],
        albumArtist: values['TPE2'],
        album: values['TALB'],
        trackNumber: _number(values['TRCK']),
        discNumber: _number(values['TPOS']),
        duration: elapsedMs != null && elapsedMs > 0
            ? Duration(milliseconds: elapsedMs)
            : null,
      );
    }
    if (fileSize < 128) return const Mp3Tags();
    final tail = await _get(path, fileSize - 128, 128, fileSize);
    if (ascii.decode(tail.sublist(0, 3)) != 'TAG') return const Mp3Tags();
    return Mp3Tags(
      title: _id3v1(tail.sublist(3, 33)),
      artist: _id3v1(tail.sublist(33, 63)),
      album: _id3v1(tail.sublist(63, 93)),
      trackNumber: tail[125] == 0 && tail[126] != 0 ? tail[126] : null,
    );
  }

  static int _syncSafe(Uint8List bytes, int offset) {
    if (offset + 4 > bytes.length) throw const FormatException('Truncated ID3');
    for (var i = 0; i < 4; i++) {
      if (bytes[offset + i] & 0x80 != 0) {
        throw const FormatException('Non-syncsafe ID3 size');
      }
    }
    return (bytes[offset] << 21) |
        (bytes[offset + 1] << 14) |
        (bytes[offset + 2] << 7) |
        bytes[offset + 3];
  }

  static int? _number(String? value) =>
      value == null ? null : int.tryParse(value.split('/').first.trim());

  static String _id3v1(List<int> bytes) =>
      _latin1OrCp1251(bytes).replaceAll('\u0000', '').trim();

  static String _decodeText(Uint8List frame) {
    final encoding = frame[0];
    final raw = frame.sublist(1);
    switch (encoding) {
      case 0:
        return _latin1OrCp1251(raw).replaceAll('\u0000', '').trim();
      case 3:
        return utf8.decode(raw).replaceAll('\u0000', '').trim();
      case 1:
      case 2:
        if (raw.length < 2) return '';
        var bigEndian = encoding == 2;
        var offset = 0;
        if (encoding == 1 && raw[0] == 0xfe && raw[1] == 0xff) {
          bigEndian = true;
          offset = 2;
        } else if (encoding == 1 && raw[0] == 0xff && raw[1] == 0xfe) {
          bigEndian = false;
          offset = 2;
        }
        final units = <int>[];
        for (var i = offset; i + 1 < raw.length; i += 2) {
          final code = bigEndian
              ? (raw[i] << 8) | raw[i + 1]
              : raw[i] | (raw[i + 1] << 8);
          if (code != 0) units.add(code);
        }
        return String.fromCharCodes(units).trim();
      default:
        return '';
    }
  }

  static String _latin1OrCp1251(List<int> bytes) {
    final significant = bytes
        .where((byte) => byte >= 0xc0 || byte == 0xa8 || byte == 0xb8)
        .length;
    if (significant < 3) return latin1.decode(bytes);
    return String.fromCharCodes([
      for (final b in bytes)
        if (b >= 0xc0)
          b - 0xc0 + 0x0410
        else if (b == 0xa8)
          0x0401
        else if (b == 0xb8)
          0x0451
        else
          b,
    ]);
  }
}
