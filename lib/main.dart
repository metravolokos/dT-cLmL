import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app/app.dart';
import 'platform/linux/linux_mpris_controls.dart';
import 'platform/windows/windows_media_controls.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  await initializeWindowsMediaControls();
  await initializeLinuxMprisControls();
  runApp(
    const ProviderScope(
      child: LinuxMprisBridge(
        child: WindowsMediaControlsBridge(child: CloudMailApp()),
      ),
    ),
  );
}
