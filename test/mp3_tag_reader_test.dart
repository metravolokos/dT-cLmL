import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudmail_player/data/tags/mp3_tag_reader.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> frame(String id, List<int> content) {
  final count = content.length;
  return [
    ...ascii.encode(id),
    (count >> 24) & 255,
    (count >> 16) & 255,
    (count >> 8) & 255,
    count & 255,
    0,
    0,
    ...content,
  ];
}

List<int> tag(List<int> body) {
  final count = body.length;
  return [
    ...ascii.encode('ID3'),
    3,
    0,
    0,
    (count >> 21) & 127,
    (count >> 14) & 127,
    (count >> 7) & 127,
    count & 127,
    ...body,
  ];
}

Mp3TagReader fromBytes(Uint8List contents, List<(int, int)> accesses) {
  return Mp3TagReader((_, offset, length) async {
    accesses.add((offset, length));
    return Uint8List.sublistView(contents, offset, offset + length);
  });
}

void main() {
  test('ID3v2.3 reads Cyrillic text and track/disc fields', () async {
    final contents = Uint8List.fromList([
      ...tag([
        ...frame('TIT2', [3, ...utf8.encode('Привет')]),
        ...frame('TPE1', [3, ...utf8.encode('Тестовый артист')]),
        ...frame('TALB', [3, ...utf8.encode('Мой альбом')]),
        ...frame('TRCK', [3, ...ascii.encode('2/12')]),
        ...frame('TPOS', [3, ...ascii.encode('1/2')]),
        ...frame('TLEN', [3, ...ascii.encode('90000')]),
      ]),
      ...Uint8List(33000),
    ]);
    final calls = <(int, int)>[];
    final tags = await fromBytes(
      contents,
      calls,
    ).parse('file.mp3', contents.length);
    expect(tags.title, 'Привет');
    expect(tags.artist, 'Тестовый артист');
    expect(tags.album, 'Мой альбом');
    expect(tags.trackNumber, 2);
    expect(tags.discNumber, 1);
    expect(tags.duration, const Duration(seconds: 90));
    expect(calls.length, 1);
    expect(calls.single.$2, 16384);
  });

  test(
    'large APIC cover skips to following title without downloading art',
    () async {
      final contents = Uint8List.fromList([
        ...tag([
          ...frame('APIC', Uint8List(110000)),
          ...frame('TIT2', [3, ...utf8.encode('После обложки')]),
        ]),
        ...Uint8List(32000),
      ]);
      final calls = <(int, int)>[];
      final tags = await fromBytes(
        contents,
        calls,
      ).parse('cover.mp3', contents.length);
      expect(tags.title, 'После обложки');
      expect(calls.fold<int>(0, (sum, call) => sum + call.$2), lessThan(17000));
    },
  );

  test('ID3v1 falls back to cp1251 for Russian text', () async {
    final tail = Uint8List(128);
    tail.setRange(0, 3, ascii.encode('TAG'));
    tail.setRange(3, 9, [0xcf, 0xf0, 0xe8, 0xe2, 0xe5, 0xf2]);
    tail.setRange(33, 39, [0xc0, 0xf0, 0xf2, 0xe8, 0xf1, 0xf2]);
    tail[125] = 0;
    tail[126] = 7;
    final file = Uint8List.fromList([...Uint8List(33000), ...tail]);
    final calls = <(int, int)>[];
    final tags = await fromBytes(file, calls).parse('old.mp3', file.length);
    expect(tags.title, 'Привет');
    expect(tags.artist, 'Артист');
    expect(tags.trackNumber, 7);
    expect(calls.fold<int>(0, (sum, c) => sum + c.$2), lessThan(20000));
  });

  test('corrupt syncsafe and out-of-bounds ID3 headers fail closed', () async {
    final malformed = Uint8List.fromList([
      ...ascii.encode('ID3'),
      3,
      0,
      0,
      255,
      255,
      255,
      255,
      ...Uint8List(24),
    ]);
    final calls = <(int, int)>[];
    await expectLater(
      fromBytes(malformed, calls).parse('bad.mp3', malformed.length),
      throwsFormatException,
    );
  });
}
