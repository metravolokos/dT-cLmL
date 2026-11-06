import 'package:cloudmail_player/domain/library_search.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const track = RemoteTrack(
    path: '/AllMusic/Ёжик в тумане.flac',
    sizeBytes: 100,
    title: 'Ёжик',
    artist: 'Сергей',
    album: 'Тёплый вечер',
  );

  test('Russian е and ё are equivalent in all indexed fields', () {
    expect(matchesLibraryQuery(track, 'ЕЖИК'), isTrue);
    expect(matchesLibraryQuery(track, 'ТЕПЛЫЙ'), isTrue);
    expect(matchesLibraryQuery(track, 'ежик в тумане.flac'), isTrue);
    expect(matchesLibraryQuery(track, 'сергей'), isTrue);
  });

  test('empty input shows all and unknown query is rejected', () {
    expect(matchesLibraryQuery(track, '   '), isTrue);
    expect(matchesLibraryQuery(track, 'несуществующий'), isFalse);
  });

  test('search normalization does not mutate actual tag casing', () {
    expect(track.title, 'Ёжик');
    expect(normalizeLibraryQuery('  ЁЖ  '), 'еж');
  });
}
