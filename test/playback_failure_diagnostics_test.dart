import 'dart:typed_data';

import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:cloudmail_player/data/audio/cloud_range_audio_source.dart';
import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const track = RemoteTrack(path: 'sample.flac', sizeBytes: 12);

  test('resume error uses P02 unless a native P03 is already known', () {
    const active = PlaybackView(track: track, playing: true);
    final failed = active.withPlaybackFailure('P02');
    expect(failed.failed, isTrue);
    expect(failed.playing, isFalse);
    expect(failed.loading, isFalse);
    expect(failed.failureCode, 'P02');

    const nativeFailure = PlaybackView(
      track: track,
      failureCode: 'P03-2-no-data',
    );
    expect(
      nativeFailure.withPlaybackFailure('P02').failureCode,
      'P03-2-no-data',
    );
  });

  test('late native events cannot reactivate stopped playback', () {
    expect(
      acceptsPlaybackEvent(
        disposed: false,
        switching: false,
        hasQueue: false,
        hasTrack: false,
      ),
      isFalse,
    );
    expect(
      acceptsPlaybackEvent(
        disposed: false,
        switching: false,
        hasQueue: false,
        hasTrack: true,
      ),
      isFalse,
    );
    expect(
      acceptsPlaybackEvent(
        disposed: false,
        switching: true,
        hasQueue: true,
        hasTrack: true,
      ),
      isFalse,
    );
    expect(
      acceptsPlaybackEvent(
        disposed: true,
        switching: false,
        hasQueue: true,
        hasTrack: true,
      ),
      isFalse,
    );
    expect(
      acceptsPlaybackEvent(
        disposed: false,
        switching: false,
        hasQueue: true,
        hasTrack: true,
      ),
      isTrue,
    );
  });

  test('WebDAV error is classified without leaking exception text', () async {
    String? diagnostic;
    final source = CloudRangeAudioSource(
      track,
      (path, offset, length) async =>
          throw const CloudMailException(CloudMailErrorCode.timeout),
      onRangeFailure: (code) => diagnostic = code,
    );
    final response = await source.request(0, 12);
    await expectLater(
      response.stream.toList(),
      throwsA(isA<CloudMailException>()),
    );
    expect(diagnostic, 'P11-timeout');
  });

  test('unexpected range length has an actionable safe code', () async {
    final diagnostics = <String>[];
    final source = CloudRangeAudioSource(
      track,
      (path, offset, length) async => Uint8List(2),
      onRangeFailure: diagnostics.add,
    );
    final response = await source.request(0, 12);
    await expectLater(response.stream.toList(), throwsA(isA<StateError>()));
    expect(diagnostics, ['P12']);
  });

  test(
    'playback view retains diagnostic classification across status updates',
    () {
      const initial = PlaybackView(
        track: track,
        failed: true,
        playing: false,
        failureCode: 'P01',
      );
      final next = initial.withUpdates(loading: false, playing: false);
      expect(next.failed, isTrue);
      expect(next.playing, isFalse);
      expect(next.failureCode, 'P01');
    },
  );
  test(
    'successful upstream chunk is observable without exposing bytes',
    () async {
      var chunksReceived = 0;
      final source = CloudRangeAudioSource(
        track,
        (path, offset, length) async => Uint8List(length),
        onRangeSuccess: () => chunksReceived++,
      );
      final response = await source.request(0, 12);
      final received = await response.stream.toList();
      expect(received, hasLength(1));
      expect(received.single.length, 12);
      expect(chunksReceived, 1);
    },
  );
}
