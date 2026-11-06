import 'dart:io';
import 'dart:typed_data';

import 'package:cloudmail_player/data/artwork/cover_thumbnail_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('resized thumbnail persists without another source download', () async {
    final directory = await Directory.systemTemp.createTemp('cover-cache-');
    addTearDown(() => directory.delete(recursive: true));
    final original = img.Image(width: 1200, height: 600);
    final source = Uint8List.fromList(img.encodePng(original));
    var fetches = 0;
    Future<Uint8List?> fetch() async {
      fetches++;
      return source;
    }

    final cache = CoverThumbnailCache(directory);
    final first = await cache.read('account:flac:etag:1', fetch);
    expect(first, isNotNull);
    final preview = img.decodeJpg(first!);
    expect(preview, isNotNull);
    expect(preview!.width, 640);
    expect(preview.height, 320);

    final reopened = CoverThumbnailCache(directory);
    final second = await reopened.read('account:flac:etag:1', fetch);
    expect(second, isNotNull);
    expect(fetches, 1);
    expect(second, first);
    await reopened.read('account:flac:etag:2', fetch);
    expect(fetches, 2);
  });

  test(
    'unsupported image and missing artwork never write thumbnails',
    () async {
      final directory = await Directory.systemTemp.createTemp('empty-cover-');
      addTearDown(() => directory.delete(recursive: true));
      final cache = CoverThumbnailCache(directory);
      expect(await cache.read('none', () async => null), isNull);
      expect(
        await cache.read('invalid', () async => Uint8List.fromList([1, 2, 3])),
        isNull,
      );
      expect(
        directory.listSync().whereType<File>().where(
          (file) => file.path.endsWith('.jpg'),
        ),
        isEmpty,
      );
    },
  );
}
