import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:cloudmail_player/presentation/now_playing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Playing extends PlaybackController {
  @override
  PlaybackView build() => const PlaybackView(
    track: RemoteTrack(
      path: '/AllMusic/Песня.flac',
      sizeBytes: 100000,
      title: 'Песня',
      artist: 'Исполнитель',
      album: 'Альбом',
    ),
    duration: Duration(minutes: 4),
    position: Duration(minutes: 1),
    playing: true,
  );
}

void main() {
  for (final width in [393.0, 1100.0]) {
    testWidgets('Now Playing adapts at ${width.toInt()} dp', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [playbackControllerProvider.overrideWith(_Playing.new)],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const NowPlayingPage(),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('now-playing-play-pause')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('now-playing-seek')), findsOneWidget);
      expect(find.byKey(const ValueKey('now-playing-artist')), findsOneWidget);
      expect(find.byKey(const ValueKey('now-playing-album')), findsOneWidget);
      expect(
        find.byKey(
          ValueKey(width >= 850 ? 'now-playing-wide' : 'now-playing-portrait'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
