import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:cloudmail_player/presentation/library_page.dart';
import 'package:cloudmail_player/presentation/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PlaybackFixture extends PlaybackController {
  @override
  PlaybackView build() => const PlaybackView(
    track: RemoteTrack(path: 'sample.flac', sizeBytes: 100, title: 'Песня'),
    playing: true,
    duration: Duration(minutes: 3),
    position: Duration(seconds: 10),
  );
}

const _tracks = [
  RemoteTrack(
    path: 'one.flac',
    sizeBytes: 100,
    title: 'Первый трек',
    artist: 'Артист',
    album: 'Первый альбом',
    trackNumber: 1,
  ),
  RemoteTrack(
    path: 'two.flac',
    sizeBytes: 200,
    title: 'Второй трек',
    artist: 'Артист',
    album: 'Второй альбом',
    trackNumber: 2,
  ),
];

Widget _app(Widget child) => ProviderScope(
  overrides: [playbackControllerProvider.overrideWith(_PlaybackFixture.new)],
  child: MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('mini-player has one control row and no stop/shuffle/repeat', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const MiniPlayer()));
    await tester.pump();
    expect(find.byTooltip('Пауза'), findsOneWidget);
    expect(find.byTooltip('Предыдущий трек'), findsOneWidget);
    expect(find.byTooltip('Следующий трек'), findsOneWidget);
    expect(find.byTooltip('Стоп'), findsNothing);
    expect(find.byTooltip('Перемешивание выключено'), findsNothing);
    expect(find.byTooltip('Повтор выключен'), findsNothing);
    expect(find.text('Песня'), findsOneWidget);
  });

  testWidgets('artist detail shows album cards above the track list', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ArtistDetailPage(artist: 'Артист', tracks: _tracks)),
    );
    await tester.pump();
    expect(find.text('Артист'), findsOneWidget);
    expect(find.byKey(const ValueKey('artist-album-grid')), findsOneWidget);
    expect(find.text('Первый альбом'), findsOneWidget);
    expect(find.text('Второй альбом'), findsOneWidget);
    expect(find.text('Первый трек'), findsOneWidget);
    expect(find.text('Второй трек'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
