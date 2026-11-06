import 'package:cloudmail_player/data/audio/playback_controller.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:cloudmail_player/presentation/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlayback extends PlaybackController {
  @override
  PlaybackView build() => const PlaybackView(
    track: RemoteTrack(
      path: '/AllMusic/Тест.flac',
      sizeBytes: 3000,
      title: 'Очень длинное название музыкального произведения',
      artist: 'Исполнитель',
    ),
    duration: Duration(minutes: 4),
    position: Duration(minutes: 1),
    playing: true,
  );
}

void main() {
  testWidgets('mini-player stays one-row at 320 dp and scales text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [playbackControllerProvider.overrideWith(_FakePlayback.new)],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            bottomNavigationBar: MiniPlayer(),
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('mini-player-play-pause')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mini-player-next')), findsOneWidget);
    expect(find.byKey(const ValueKey('mini-player-previous')), findsNothing);
    expect(find.byKey(const ValueKey('mini-player-progress')), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
