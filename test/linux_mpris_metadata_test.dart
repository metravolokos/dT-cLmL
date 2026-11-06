import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/platform/linux/linux_mpris_controls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux MPRIS metadata preserves Unicode but hides cloud paths', () {
    const track = RemoteTrack(
      path: '/AllMusic/Демо.flac',
      sizeBytes: 90000,
      title: 'Песня',
      artist: 'Исполнитель',
      album: 'Альбом',
    );
    final mediaItem = linuxMediaItemForTrack(track);
    expect(mediaItem.title, 'Песня');
    expect(mediaItem.artist, 'Исполнитель');
    expect(mediaItem.album, 'Альбом');
    expect(
      mediaItem.id,
      matches(RegExp(r'^/com/cloudmail_player/track/t[a-f0-9]{64}$')),
    );
    expect(mediaItem.id, isNot(contains('AllMusic')));
    expect(mediaItem.id, isNot(contains('Демо')));
  });

  test('MPRIS track ID changes when the remote resource version changes', () {
    const a = RemoteTrack(path: '/AllMusic/demo.flac', sizeBytes: 20);
    const b = RemoteTrack(path: '/AllMusic/demo.flac', sizeBytes: 21);
    expect(linuxMediaItemForTrack(a).id, isNot(linuxMediaItemForTrack(b).id));
  });
}
