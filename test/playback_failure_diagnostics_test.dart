import 'dart:typed_data';

import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:cloudmail_player/data/audio/cloud_range_audio_source.dart';
import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const track = RemoteTrack(path: 'sample.flac', sizeBytes: 12);

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
    String? diagnostic;
    final source = CloudRangeAudioSource(
      track,
      (path, offset, length) async => Uint8List(2),
      onRangeFailure: (code) => diagnostic = code,
    );
    final response = await source.request(0, 12);
    await expectLater(response.stream.toList(), throwsA(isA<StateError>()));
    expect(diagnostic, 'P12');
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
