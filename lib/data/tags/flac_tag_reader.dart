import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

typedef FlacRangeReader =
    Future<Uint8List> Function(String path, int offset, int length);

class FlacTags {
  const FlacTags({
    this.title,
    this.artist,
    this.albumArtist,
    this.album,
    this.trackNumber,
    this.discNumber,
    this.duration,
  });

  final String? title;
  final String? artist;
  final String? albumArtist;
  final String? album;
  final int? trackNumber;
  final int? discNumber;
  final Duration? duration;
}

/// Reads only bounded metadata byte ranges; embedded artwork payloads can be
/// skipped without downloading them during the initial index.
class FlacTagReader {
  FlacTagReader(this.readRange);

  final FlacRangeReader readRange;

  static const int maximumReadBytes = 64 * 1024;
  static const int maximumCommentBytes = 512 * 1024;
  static const int maximumMetadataOffset = 32 * 1024 * 1024;

  Future<Uint8List> _read(
    String path,
    int offset,
    int count,
    int fileSize,
  ) async {
    if (offset < 0 || count < 0 || offset + count > fileSize) {
      throw const FormatException('FLAC metadata is outside the file');
    }
    if (count == 0) return Uint8List(0);
    final result = BytesBuilder(copy: false);
    var remaining = count;
    var cursor = offset;
    while (remaining > 0) {
      final take = math.min(remaining, maximumReadBytes);
      final piece = await readRange(path, cursor, take);
      if (piece.length != take) throw const FormatException('Short FLAC read');
      result.add(piece);
      cursor += take;
      remaining -= take;
    }
    return result.takeBytes();
  }

  Future<FlacTags> parse(String path, int fileSize) async {
    if (fileSize < 8) throw const FormatException('Too short for FLAC');
    // The first 8 KiB is fetched once and shared by all header/metadata
    // reads. Normally this means just one Range GET per FLAC file.
    final headLength = math.min(fileSize, 8192);
    final head = await _read(path, 0, headLength, fileSize);
    Future<Uint8List> readAt(int offset, int count) async {
      if (offset >= 0 && offset + count <= head.length) {
        return Uint8List.sublistView(head, offset, offset + count);
      }
      return _read(path, offset, count, fileSize);
    }

    final signature = Uint8List.sublistView(head, 0, 4);
    if (ascii.decode(signature) != 'fLaC') {
      throw const FormatException('Not a FLAC stream');
    }

    final tags = <String, String>{};
    Duration? duration;
    var position = 4;
    var lastBlock = false;
    var blockCount = 0;

    while (!lastBlock) {
      if (++blockCount > 128 || position > maximumMetadataOffset) {
        throw const FormatException('FLAC metadata limit exceeded');
      }
      final header = await readAt(position, 4);
      lastBlock = (header[0] & 0x80) != 0;
      final type = header[0] & 0x7f;
      final length = (header[1] << 16) | (header[2] << 8) | header[3];
      position += 4;
      if (position + length > fileSize ||
          position + length > maximumMetadataOffset) {
        throw const FormatException('FLAC block exceeds bounds');
      }

      if (type == 0) {
        if (length != 34) throw const FormatException('Bad STREAMINFO');
        final data = await readAt(position, 34);
        final packed = ByteData.sublistView(data).getUint64(10, Endian.big);
        final sampleRate = packed >> 44;
        final samples = packed & ((1 << 36) - 1);
        if (sampleRate > 0 && samples > 0) {
          duration = Duration(microseconds: (samples * 1000000) ~/ sampleRate);
        }
      } else if (type == 4) {
        if (length > maximumCommentBytes) {
          throw const FormatException('Oversized FLAC comments');
        }
        final data = await readAt(position, length);
        _readComments(data, tags);
      }
      // PICTURE (type 6) and other blocks are skipped by metadata offset;
      // their contents are not downloaded.
      position += length;
    }
    return FlacTags(
      title: tags['TITLE'],
      artist: tags['ARTIST'],
      albumArtist: tags['ALBUMARTIST'] ?? tags['ALBUM ARTIST'],
      album: tags['ALBUM'],
      trackNumber: _number(tags['TRACKNUMBER']),
      discNumber: _number(tags['DISCNUMBER']),
      duration: duration,
    );
  }

  static int? _number(String? text) {
    if (text == null) return null;
    return int.tryParse(text.split('/').first.trim());
  }

  static void _readComments(Uint8List bytes, Map<String, String> output) {
    final data = ByteData.sublistView(bytes);
    var cursor = 0;

    int nextLength() {
      if (cursor + 4 > bytes.length) {
        throw const FormatException('Truncated Vorbis comment');
      }
      final length = data.getUint32(cursor, Endian.little);
      cursor += 4;
      if (length > bytes.length - cursor) {
        throw const FormatException('Invalid Vorbis comment length');
      }
      return length;
    }

    final vendorSize = nextLength();
    cursor += vendorSize;
    if (cursor + 4 > bytes.length) {
      throw const FormatException('Missing Vorbis field count');
    }
    final entries = data.getUint32(cursor, Endian.little);
    cursor += 4;
    if (entries > 4096) throw const FormatException('Too many FLAC tags');

    for (var index = 0; index < entries; index++) {
      final length = nextLength();
      final line = utf8.decode(bytes.sublist(cursor, cursor + length));
      cursor += length;
      final equal = line.indexOf('=');
      if (equal <= 0) continue;
      final key = line.substring(0, equal).trim().toUpperCase();
      final value = line.substring(equal + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        output.putIfAbsent(key, () => value);
      }
    }
  }
}
