import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudmail_player/data/tags/flac_tag_reader.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List metadataBlock(int type, List<int> payload, {bool last = false}) {
  final length = payload.length;
  return Uint8List.fromList([
    type | (last ? 0x80 : 0),
    (length >> 16) & 0xff,
    (length >> 8) & 0xff,
    length & 0xff,
    ...payload,
  ]);
}

Uint8List streamInfo(Duration duration, {int sampleRate = 44100}) {
  final block = Uint8List(34);
  final count = (duration.inMicroseconds * sampleRate) ~/ 1000000;
  final packed = (sampleRate << 44) | (1 << 41) | (15 << 36) | count;
  ByteData.sublistView(block).setUint64(10, packed, Endian.big);
  return block;
}

Uint8List vorbisFields(List<String> entries) {
  final builder = BytesBuilder(copy: false);
  void addCount(int number) {
    final b = ByteData(4)..setUint32(0, number, Endian.little);
    builder.add(b.buffer.asUint8List());
  }

  final vendor = utf8.encode('test');
  addCount(vendor.length);
  builder.add(vendor);
  addCount(entries.length);
  for (final value in entries) {
    final encoded = utf8.encode(value);
    addCount(encoded.length);
    builder.add(encoded);
  }
  return builder.takeBytes();
}

void main() {
  test('FLAC extracts Cyrillic Vorbis tags and precise duration', () async {
    final source = Uint8List.fromList([
      ...ascii.encode('fLaC'),
      ...metadataBlock(0, streamInfo(const Duration(seconds: 90))),
      ...metadataBlock(
        4,
        vorbisFields([
          'TITLE=Тихая ночь',
          'ARTIST=Мой артист',
          'ALBUM=Альбом №1',
          'ALBUMARTIST=Альбомный исполнитель',
          'TRACKNUMBER=03/12',
          'DISCNUMBER=2',
        ]),
        last: true,
      ),
      ...Uint8List(16000),
    ]);
    var requested = 0;
    final parser = FlacTagReader((_, offset, length) async {
      requested += length;
      return Uint8List.sublistView(source, offset, offset + length);
    });
    final tags = await parser.parse('test.flac', source.length);
    expect(tags.title, 'Тихая ночь');
    expect(tags.artist, 'Мой артист');
    expect(tags.album, 'Альбом №1');
    expect(tags.albumArtist, 'Альбомный исполнитель');
    expect(tags.trackNumber, 3);
    expect(tags.discNumber, 2);
    expect(tags.duration, const Duration(seconds: 90));
    expect(requested, lessThan(source.length));
  });

  test(
    'large embedded picture is skipped without reading image bytes',
    () async {
      final source = Uint8List.fromList([
        ...ascii.encode('fLaC'),
        ...metadataBlock(0, streamInfo(const Duration(seconds: 2))),
        ...metadataBlock(6, Uint8List(120000)),
        ...metadataBlock(4, vorbisFields(['TITLE=After artwork']), last: true),
        ...Uint8List(700),
      ]);
      var requested = 0;
      final parser = FlacTagReader((_, offset, length) async {
        requested += length;
        return Uint8List.sublistView(source, offset, offset + length);
      });
      final tags = await parser.parse('track.flac', source.length);
      expect(tags.title, 'After artwork');
      expect(requested, lessThan(9000));
    },
  );

  test(
    'malformed block length is rejected without a network overflow',
    () async {
      final source = Uint8List.fromList([
        ...ascii.encode('fLaC'),
        0x84,
        0xff,
        0xff,
        0xff,
      ]);
      final parser = FlacTagReader((_, offset, length) async {
        return Uint8List.sublistView(source, offset, offset + length);
      });
      await expectLater(
        parser.parse('broken.flac', source.length),
        throwsFormatException,
      );
    },
  );

  test('Vorbis parser rejects malformed length and too-many entries', () async {
    final source = Uint8List.fromList([
      ...ascii.encode('fLaC'),
      ...metadataBlock(0, streamInfo(const Duration(seconds: 1))),
      ...metadataBlock(4, [0xff, 0xff, 0xff, 0xff], last: true),
    ]);
    final parser = FlacTagReader((_, offset, length) async {
      return Uint8List.sublistView(source, offset, offset + length);
    });
    await expectLater(
      parser.parse('bad.flac', source.length),
      throwsFormatException,
    );
  });
}
