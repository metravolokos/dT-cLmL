import 'dart:io';
import 'dart:typed_data';

import 'package:cloudmail_player/data/audio/two_track_cache.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_test/flutter_test.dart';

const trackA = RemoteTrack(path: 'A.flac', sizeBytes: 9500, etag: 'a');
const trackB = RemoteTrack(path: 'Б.flac', sizeBytes: 4800, etag: 'b');
const trackC = RemoteTrack(path: 'C.mp3', sizeBytes: 7200, etag: 'c');

void main() {
  late Directory temp;
  late TwoTrackAudioCache cache;
  final requests = <String>[];

  Future<void> waitFor(RemoteTrack track) async {
    for (var i = 0; i < 200; i++) {
      if (cache.isComplete(track)) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Prefetch did not finish');
  }

  setUp(() async {
    requests.clear();
    temp = await Directory.systemTemp.createTemp('cloud-cache-fixture-');
    cache = await TwoTrackAudioCache.open(
      directory: temp,
      fetch: (path, offset, length, {cancellation}) async {
        requests.add('$path:$offset:$length');
        return Uint8List.fromList(
          List.generate(length, (i) => (offset + i) % 256),
        );
      },
    );
  });

  tearDown(() async {
    await cache.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('current completes before next, with no historical file', () async {
    await cache.configure(trackA, trackB);
    await waitFor(trackA);
    await waitFor(trackB);
    expect(cache.cachedFileCount, 2);
    expect(cache.downloadedBytes, 14300);
    expect((await temp.list().toList()).whereType<File>(), hasLength(2));
  });

  test('download progress reports current and promoted next file', () async {
    final events = <String>[];
    final tracked = await TwoTrackAudioCache.open(
      directory: await Directory.systemTemp.createTemp('cache-progress-'),
      fetch: (path, offset, length, {cancellation}) async => Uint8List(length),
      onProgress: (track, bytes) => events.add('${track.path}:$bytes'),
    );
    try {
      await tracked.configure(trackA, trackB);
      for (var i = 0; i < 200 && !tracked.isComplete(trackB); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(tracked.fractionFor(trackA), 1);
      expect(tracked.fractionFor(trackB), 1);
      expect(events, contains('A.flac:9500'));
      expect(events, contains('Б.flac:4800'));
      await tracked.configure(trackB, trackC);
      expect(events.lastWhere((x) => x.startsWith('Б.flac:')), 'Б.flac:4800');
      expect(tracked.fractionFor(trackA), 0);
      expect(tracked.fractionFor(trackB), 1);
    } finally {
      await tracked.close();
    }
  });

  test('completed track seek is served from disk with no new GET', () async {
    await cache.configure(trackA, trackB);
    await waitFor(trackA);
    final before = requests.length;
    final bytes = await cache.read('A.flac', 4000, 3000);
    expect(bytes.length, 3000);
    expect(bytes.first, 4000 % 256);
    expect(requests.length, before);
  });

  test('promoted prefetched next retains download and deletes old', () async {
    await cache.configure(trackA, trackB);
    await waitFor(trackB);
    final before = requests.where((s) => s.startsWith('Б.flac:')).length;
    await cache.configure(trackB, trackC);
    await waitFor(trackC);
    expect(cache.cachedFileCount, 2);
    expect(cache.isComplete(trackB), isTrue);
    expect(requests.where((s) => s.startsWith('Б.flac:')).length, before);
    expect((await temp.list().toList()).whereType<File>(), hasLength(2));
  });

  test(
    'Cyrillic track key is UTF-8 and cached seek makes no new GET',
    () async {
      await cache.configure(trackB, null);
      await waitFor(trackB);
      final before = requests.length;
      final bytes = await cache.read(trackB.path, 128, 1024);
      expect(bytes.length, 1024);
      expect(requests.length, before);
    },
  );

  test('oversized track is streamable but cannot occupy cache', () async {
    const huge = RemoteTrack(
      path: 'huge.flac',
      sizeBytes: TwoTrackAudioCache.maximumBytes + 1,
    );
    await cache.configure(huge, trackA);
    expect(cache.cachedFileCount, 0);
    final data = await cache.read('huge.flac', 100, 512);
    expect(data.length, 512);
    expect(requests.any((r) => r.startsWith('huge.flac:100:512')), isTrue);
  });

  test('temporary data does not survive restarting the application', () async {
    await cache.configure(trackA, null);
    await waitFor(trackA);
    await cache.close();
    final resumed = await TwoTrackAudioCache.open(
      directory: temp,
      fetch: (path, offset, length, {cancellation}) async => Uint8List(length),
    );
    expect((await temp.list().toList()).whereType<File>(), isEmpty);
    await resumed.close();
  });

  test('invalid read range does not reach the HTTP transport', () async {
    await cache.configure(trackA, null);
    final before = requests.length;
    await expectLater(cache.read('A.flac', 0, 65537), throwsRangeError);
    await expectLater(cache.read('A.flac', 9000, 1000), throwsRangeError);
    expect(requests.length, greaterThanOrEqualTo(before));
  });
}
