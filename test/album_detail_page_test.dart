import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:cloudmail_player/presentation/album_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('album opens as a full page, with tracks in disc order', (
    tester,
  ) async {
    final tracks = [
      const RemoteTrack(
        path: '/AllMusic/02.flac',
        sizeBytes: 100,
        title: 'Вторая',
        artist: 'Исполнитель',
        album: 'Наш альбом',
        trackNumber: 2,
        discNumber: 1,
      ),
      const RemoteTrack(
        path: '/AllMusic/01.flac',
        sizeBytes: 100,
        title: 'Первая',
        artist: 'Исполнитель',
        album: 'Наш альбом',
        trackNumber: 1,
        discNumber: 1,
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: AlbumDetailPage(tracks: tracks),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('album-detail-title')), findsOneWidget);
    expect(find.text('Наш альбом'), findsWidgets);
    expect(find.byKey(const ValueKey('album-play-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('album-shuffle')), findsOneWidget);
    expect(find.text('Первая'), findsOneWidget);
    expect(find.text('Вторая'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('album-track-/AllMusic/01.flac')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('album-track-/AllMusic/02.flac')),
      findsOneWidget,
    );
  });
}
