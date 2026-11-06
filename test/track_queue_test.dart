import 'dart:math';

import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/domain/track_queue.dart';
import 'package:flutter_test/flutter_test.dart';

final tracks = [
  for (var i = 0; i < 5; i++) RemoteTrack(path: '$i.flac', sizeBytes: 100),
];

void main() {
  test('queue next/prev stops at boundaries when repeat is off', () {
    final queue = TrackQueue(tracks, 2);
    expect(queue.current.path, '2.flac');
    expect(queue.previous()!.path, '1.flac');
    expect(queue.previous()!.path, '0.flac');
    expect(queue.previous(), isNull);
    expect(queue.next()!.path, '1.flac');
  });

  test('repeat all wraps; repeat one affects auto but not manual next', () {
    final queue = TrackQueue(tracks, 4);
    expect(queue.next(manual: false), isNull);
    expect(queue.cycleRepeat(), PlayerRepeatMode.all);
    expect(queue.next(manual: false)!.path, '0.flac');
    expect(queue.previous()!.path, '4.flac');
    expect(queue.cycleRepeat(), PlayerRepeatMode.one);
    expect(queue.next(manual: false)!.path, '4.flac');
    expect(queue.next(manual: true), isNull);
    expect(queue.nextForPrefetch()!.path, '4.flac');
  });

  test('shuffle preserves current selection and restoring original order', () {
    final queue = TrackQueue(tracks, 2);
    queue.setShuffled(true, random: Random(42));
    expect(queue.current.path, '2.flac');
    expect(queue.count, 5);
    final seen = <String>{queue.current.path};
    while (true) {
      final track = queue.next();
      if (track == null) break;
      seen.add(track.path);
    }
    expect(seen, tracks.map((track) => track.path).toSet());
    queue.setShuffled(false);
    expect(queue.current.path, '4.flac');
    expect(queue.previous()!.path, '3.flac');
  });

  test('repeat cycles through off / all / one', () {
    final queue = TrackQueue(tracks, 0);
    expect(queue.repeatMode, PlayerRepeatMode.off);
    expect(queue.cycleRepeat(), PlayerRepeatMode.all);
    expect(queue.cycleRepeat(), PlayerRepeatMode.one);
    expect(queue.cycleRepeat(), PlayerRepeatMode.off);
  });
}
