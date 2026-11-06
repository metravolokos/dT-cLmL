import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app/app.dart';
import 'data/audio/media_tag_factory.dart';
import 'platform/android/android_audio_session.dart';
import 'platform/android/android_background_audio.dart';
import 'platform/linux/linux_mpris_controls.dart';
import 'platform/windows/windows_media_controls.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAndroidPlaybackControls();
  await initializeWindowsMediaControls();
  await initializeLinuxMprisControls();
  // Registers the native libmpv backend for Windows and Linux. Android keeps
  // just_audio's standard Media3 ExoPlayer implementation.
  JustAudioMediaKit.ensureInitialized();
  await configureAndroidMusicAudioSession();
  runApp(
    ProviderScope(
      overrides: [mediaTagFactoryProvider.overrideWithValue(androidMediaTag)],
      child: const LinuxMprisBridge(
        child: WindowsMediaControlsBridge(
          child: AndroidMediaSessionBridge(child: CloudMailApp()),
        ),
      ),
    ),
  );
}
