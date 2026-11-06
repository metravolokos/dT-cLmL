import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudmail_player/data/artwork/flac_artwork_reader.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _u32(int number) {
  final buffer = ByteData(4)..setUint32(0, number, Endian.big);
  return buffer.buffer.asUint8List();
}

List<int> _picture(
  int pictureType,
  List<int> bytes, {
  String mime = 'image/jpeg',
}) {
  return [
    ..._u32(pictureType),
    ..._u32(mime.length),
    ...ascii.encode(mime),
    ..._u32(0), // description
    ..._u32(320),
    ..._u32(320),
    ..._u32(24),
    ..._u32(0), // palette
    ..._u32(bytes.length),
    ...bytes,
  ];
}

List<int> _block(int type, List<int> payload, {bool last = false}) => [
  (last ? 0x80 : 0) | type,
  (payload.length >> 16) & 0xff,
  (payload.length >> 8) & 0xff,
  payload.length & 0xff,
  ...payload,
];

void main() {
  test('front cover takes precedence and reads no audio frames', () async {
    const jpeg = [0xff, 0xd8, 0xff, 0xd9];
    final stream = Uint8List.fromList([
      ...ascii.encode('fLaC'),
      ..._block(0, List.filled(34, 0)),
      ..._block(6, _picture(0, jpeg)),
      ..._block(6, _picture(3, jpeg), last: true),
      ...List.filled(100000, 77), // audio must never be fetched
    ]);
    var bytesRead = 0;
    final reader = FlacArtworkReader((path, offset, length) async {
      expect(length, lessThanOrEqualTo(64 * 1024));
      bytesRead += length;
      return Uint8List.sublistView(stream, offset, offset + length);
    });
    final artwork = await reader.read('Трек.flac', stream.length);
    expect(artwork?.pictureType, 3);
    expect(artwork?.mimeType, 'image/jpeg');
    expect(artwork?.bytes, jpeg);
    expect(bytesRead, lessThan(1000));
  });

  test('large embedded JPEG is split into bounded Range GETs', () async {
    final jpeg = [0xff, 0xd8, 0xff, ...List.filled(150000, 1)];
    final stream = Uint8List.fromList([
      ...ascii.encode('fLaC'),
      ..._block(6, _picture(3, jpeg), last: true),
    ]);
    final reads = <int>[];
    final reader = FlacArtworkReader((path, offset, length) async {
      reads.add(length);
      return Uint8List.sublistView(stream, offset, offset + length);
    });
    final artwork = await reader.read('large.flac', stream.length);
    expect(artwork?.bytes.length, jpeg.length);
    expect(reads.every((n) => n <= 65536), isTrue);
    expect(reads.where((n) => n == 65536).length, greaterThanOrEqualTo(2));
  });

  test(
    'untrusted picture dimensions and invalid signature are rejected',
    () async {
      final fake = Uint8List.fromList([
        ...ascii.encode('fLaC'),
        ..._block(6, _picture(3, [1, 2, 3]), last: true),
      ]);
      final reader = FlacArtworkReader(
        (path, offset, length) async =>
            Uint8List.sublistView(fake, offset, offset + length),
      );
      expect(await reader.read('invalid.flac', fake.length), isNull);
      expect(await reader.read('invalid.flac', 3), isNull);
    },
  );
}
