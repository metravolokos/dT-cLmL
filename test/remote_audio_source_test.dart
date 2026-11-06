import 'dart:typed_data';

import 'package:cloudmail_player/data/audio/cloud_range_audio_source.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform media tag is carried by the authenticated stream source', () {
    final metadata = Object();
    final source = CloudRangeAudioSource(
      const RemoteTrack(path: 'metadata.flac', sizeBytes: 4),
      (_, _, length) async => Uint8List(length),
      mediaTag: metadata,
    );
    expect(source.tag, same(metadata));
  });

  test(
    'FLAC remote source requests exact 64 KiB chunks and accepts seek',
    () async {
      final calls = <(int, int)>[];
      final track = RemoteTrack(path: 'Аудио.flac', sizeBytes: 150000);
      final source = CloudRangeAudioSource(track, (path, offset, length) async {
        expect(path, 'Аудио.flac');
        calls.add((offset, length));
        return Uint8List(length);
      });
      final response = await source.request(50000, 150000);
      var bytes = 0;
      await for (final chunk in response.stream) {
        bytes += chunk.length;
      }
      expect(response.sourceLength, 150000);
      expect(response.offset, 50000);
      expect(response.contentType, 'audio/flac');
      expect(bytes, 100000);
      expect(calls, [(50000, 65536), (115536, 34464)]);
    },
  );

  test('StreamAudioSource prevents offsets outside file size', () async {
    final source = CloudRangeAudioSource(
      const RemoteTrack(path: 'file.mp3', sizeBytes: 8),
      (_, _, length) async => Uint8List(length),
    );
    expect(() => source.request(9, 10), throwsRangeError);
    final bytes = <int>[];
    await for (final part in (await source.request(3, 8)).stream) {
      bytes.addAll(part);
    }
    expect(bytes.length, 5);
  });

  test('file title and artist are derived without guessing metadata', () {
    const track = RemoteTrack(path: 'Музыка №1.flac', sizeBytes: 40);
    expect(track.displayTitle, 'Музыка №1');
    expect(track.displayArtist, 'Неизвестный исполнитель');
    expect(track.displayAlbum, 'Без альбома');
  });
}
