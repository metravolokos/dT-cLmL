import 'package:cloudmail_player/domain/album_track_order.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disc and track tags determine album playback and cover order', () {
    final tracks = <RemoteTrack>[
      const RemoteTrack(
        path: 'z-track.flac',
        sizeBytes: 100,
        discNumber: 2,
        trackNumber: 1,
      ),
      const RemoteTrack(
        path: 'b-track.flac',
        sizeBytes: 100,
        discNumber: 1,
        trackNumber: 2,
      ),
      const RemoteTrack(
        path: 'a-track.flac',
        sizeBytes: 100,
        discNumber: 1,
        trackNumber: 1,
      ),
    ]..sort(compareAlbumTracks);
    expect(tracks.map((track) => track.path), [
      'a-track.flac',
      'b-track.flac',
      'z-track.flac',
    ]);
  });

  test('unindexed album tracks retain stable filename fallback', () {
    final tracks = <RemoteTrack>[
      const RemoteTrack(path: 'Вторая.flac', sizeBytes: 100),
      const RemoteTrack(path: 'Первая.flac', sizeBytes: 100),
    ]..sort(compareAlbumTracks);
    expect(tracks.map((track) => track.path), ['Вторая.flac', 'Первая.flac']);
  });

  test('numbered tracks precede missing numbers on the same disc', () {
    final tracks = <RemoteTrack>[
      const RemoteTrack(path: 'unknown.flac', sizeBytes: 100),
      const RemoteTrack(path: 'numbered.flac', sizeBytes: 100, trackNumber: 3),
    ]..sort(compareAlbumTracks);
    expect(tracks.first.path, 'numbered.flac');
  });
}
