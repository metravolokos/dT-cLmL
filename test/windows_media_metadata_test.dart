import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/platform/windows/windows_media_controls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows SMTC metadata includes Cyrillic album and artist tags', () {
    const track = RemoteTrack(
      path: 'Песня.flac',
      sizeBytes: 90000,
      title: 'Песня',
      artist: 'Исполнитель',
      album: 'Альбом',
      albumArtist: 'Группа',
    );
    final metadata = windowsMetadataForTrack(track);
    expect(metadata.title, 'Песня');
    expect(metadata.artist, 'Исполнитель');
    expect(metadata.album, 'Альбом');
    expect(metadata.albumArtist, 'Группа');
    expect(metadata.thumbnail, isNull);
  });

  test('Windows SMTC metadata uses filename fallback for missing tags', () {
    const track = RemoteTrack(
      path: 'Неизвестная композиция.flac',
      sizeBytes: 1,
    );
    final metadata = windowsMetadataForTrack(track);
    expect(metadata.title, 'Неизвестная композиция');
    expect(metadata.artist, 'Неизвестный исполнитель');
  });
}
