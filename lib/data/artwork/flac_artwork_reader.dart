import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

typedef ArtworkRangeReader =
    Future<Uint8List> Function(String path, int offset, int length);

/// A verified embedded FLAC image, returned only on explicit artwork lookup.
class FlacEmbeddedArtwork {
  const FlacEmbeddedArtwork({
    required this.bytes,
    required this.mimeType,
    required this.pictureType,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final String mimeType;
  final int pictureType;
  final int width;
  final int height;
}

/// Reads FLAC PICTURE blocks without fetching audio frames or large metadata
/// blocks that are not PICTURE. Every network read is <= 64 KiB.
class FlacArtworkReader {
  FlacArtworkReader(this.readRange);

  final ArtworkRangeReader readRange;

  static const int maximumRangeBytes = 64 * 1024;
  static const int maximumMetadataOffset = 32 * 1024 * 1024;
  static const int maximumPictureBlockBytes = 8 * 1024 * 1024;
  static const int maximumImageBytes = 5 * 1024 * 1024;
  static const int maximumDimension = 12000;

  Future<Uint8List> _read(
    String path,
    int offset,
    int length,
    int fileSize,
  ) async {
    if (offset < 0 ||
        length < 0 ||
        offset + length > fileSize ||
        offset + length > maximumMetadataOffset) {
      throw const FormatException('FLAC artwork metadata outside bounds');
    }
    final builder = BytesBuilder(copy: false);
    for (var cursor = 0; cursor < length;) {
      final take = math.min(maximumRangeBytes, length - cursor);
      final bytes = await readRange(path, offset + cursor, take);
      if (bytes.length != take) {
        throw const FormatException('Short FLAC artwork Range response');
      }
      builder.add(bytes);
      cursor += take;
    }
    return builder.takeBytes();
  }

  Future<FlacEmbeddedArtwork?> read(String path, int fileSize) async {
    if (fileSize < 8) return null;
    final signature = await _read(path, 0, 4, fileSize);
    if (ascii.decode(signature) != 'fLaC') return null;
    FlacEmbeddedArtwork? fallback;
    var offset = 4;
    for (var index = 0; index < 128; index++) {
      final header = await _read(path, offset, 4, fileSize);
      final last = (header[0] & 0x80) != 0;
      final type = header[0] & 0x7f;
      final length = (header[1] << 16) | (header[2] << 8) | header[3];
      offset += 4;
      if (offset + length > fileSize ||
          offset + length > maximumMetadataOffset) {
        throw const FormatException('Invalid FLAC artwork block length');
      }
      if (type == 6 && length <= maximumPictureBlockBytes) {
        // Read only one bounded PICTURE block, not the audio stream.
        final block = await _read(path, offset, length, fileSize);
        final candidate = _parsePicture(block);
        if (candidate != null) {
          if (candidate.pictureType == 3) return candidate;
          fallback ??= candidate;
        }
      }
      offset += length;
      if (last) return fallback;
    }
    throw const FormatException('Too many FLAC metadata blocks');
  }

  static FlacEmbeddedArtwork? _parsePicture(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    var cursor = 0;
    int takeInt() {
      if (cursor + 4 > bytes.length) {
        throw const FormatException('Truncated FLAC picture header');
      }
      final value = view.getUint32(cursor, Endian.big);
      cursor += 4;
      return value;
    }

    try {
      final type = takeInt();
      final mimeLength = takeInt();
      if (mimeLength > 256 || cursor + mimeLength > bytes.length) return null;
      final mime = ascii
          .decode(
            Uint8List.sublistView(bytes, cursor, cursor + mimeLength),
            allowInvalid: true,
          )
          .toLowerCase();
      cursor += mimeLength;
      if (mime != 'image/jpeg' && mime != 'image/png') return null;
      final descriptionLength = takeInt();
      if (descriptionLength > 64 * 1024 ||
          cursor + descriptionLength > bytes.length) {
        return null;
      }
      cursor += descriptionLength;
      final width = takeInt();
      final height = takeInt();
      takeInt(); // color depth
      takeInt(); // indexed palette count
      final imageLength = takeInt();
      if (width < 1 ||
          height < 1 ||
          width > maximumDimension ||
          height > maximumDimension ||
          imageLength < 1 ||
          imageLength > maximumImageBytes ||
          cursor + imageLength != bytes.length) {
        return null;
      }
      final image = Uint8List.sublistView(bytes, cursor, cursor + imageLength);
      // Reject corrupt MIME declarations without relying on image decoding.
      final jpeg =
          image.length >= 3 &&
          image[0] == 0xff &&
          image[1] == 0xd8 &&
          image[2] == 0xff;
      final png =
          image.length >= 8 &&
          image[0] == 0x89 &&
          image[1] == 0x50 &&
          image[2] == 0x4e &&
          image[3] == 0x47 &&
          image[4] == 0x0d &&
          image[5] == 0x0a &&
          image[6] == 0x1a &&
          image[7] == 0x0a;
      if ((mime == 'image/jpeg' && !jpeg) || (mime == 'image/png' && !png)) {
        return null;
      }
      return FlacEmbeddedArtwork(
        bytes: Uint8List.fromList(image),
        mimeType: mime,
        pictureType: type,
        width: width,
        height: height,
      );
    } on FormatException {
      return null;
    }
  }
}
