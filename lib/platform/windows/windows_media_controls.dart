import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../../data/audio/playback_controller.dart';
import '../../domain/remote_track.dart';

bool _windowsMediaControlsInitialized = false;

Future<void> initializeWindowsMediaControls() async {
  if (!Platform.isWindows) return;
  try {
    await SMTCWindows.initialize();
    _windowsMediaControlsInitialized = true;
  } catch (_) {
    // System media controls are optional; audio playback must still start.
    _windowsMediaControlsInitialized = false;
  }
}

MusicMetadata windowsMetadataForTrack(RemoteTrack track) => MusicMetadata(
  title: track.displayTitle,
  artist: track.displayArtist,
  album: track.displayAlbum,
  albumArtist: track.albumArtist ?? track.displayArtist,
);

/// Connect Windows media keys and SMTC to the existing single player.
class WindowsMediaControlsBridge extends ConsumerStatefulWidget {
  const WindowsMediaControlsBridge({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<WindowsMediaControlsBridge> createState() =>
      _WindowsMediaControlsBridgeState();
}

class _WindowsMediaControlsBridgeState
    extends ConsumerState<WindowsMediaControlsBridge> {
  SMTCWindows? _smtc;
  StreamSubscription<PressedButton>? _buttons;
  String? _trackIdentity;
  bool? _wasPlaying;
  int _lastPositionMs = -1;
  int _lastDurationMs = -1;
  Future<void> _operations = Future<void>.value();

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows || !_windowsMediaControlsInitialized) return;
    try {
      _smtc = SMTCWindows(
        metadata: const MusicMetadata(title: 'teStPlaYclouDE'),
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
        enabled: false,
      );
    } catch (_) {
      // A native SMTC failure must not prevent the player from running.
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _buttons = _smtc?.buttonPressStream.listen(_handleButton);
      _refresh(ref.read(playbackControllerProvider));
    });
  }

  void _handleButton(PressedButton button) {
    if (!mounted) return;
    final controller = ref.read(playbackControllerProvider.notifier);
    final view = ref.read(playbackControllerProvider);
    if (button == PressedButton.play && !view.playing) {
      unawaited(controller.pauseOrResume());
    } else if (button == PressedButton.pause && view.playing) {
      unawaited(controller.pauseOrResume());
    } else if (button == PressedButton.next) {
      unawaited(controller.next());
    } else if (button == PressedButton.previous) {
      unawaited(controller.previous());
    } else if (button == PressedButton.stop) {
      unawaited(controller.stop());
    }
  }

  void _refresh(PlaybackView view) {
    final smtc = _smtc;
    if (smtc == null) return;
    final track = view.track;
    final identity = track == null
        ? null
        : '${track.path}\u0000${track.etag ?? ''}\u0000${track.sizeBytes}';
    final changedTrack = identity != _trackIdentity;
    final changedStatus = _wasPlaying != view.playing;
    final position = view.position.inMilliseconds;
    final duration = view.duration.inMilliseconds;
    final changedPosition = (position - _lastPositionMs).abs() >= 1000;
    final changedDuration = duration != _lastDurationMs;
    if (!changedTrack &&
        !changedStatus &&
        !changedPosition &&
        !changedDuration) {
      return;
    }

    _trackIdentity = identity;
    _wasPlaying = view.playing;
    _lastPositionMs = position;
    _lastDurationMs = duration;
    _operations = _operations
        .then((_) async {
          if (track == null) {
            await smtc.setPlaybackStatus(PlaybackStatus.stopped);
            await smtc.disableSmtc();
            return;
          }
          if (changedTrack) {
            await smtc.updateMetadata(windowsMetadataForTrack(track));
            await smtc.enableSmtc();
          }
          if (changedDuration || changedTrack || changedPosition) {
            final endMs = duration > 0 ? duration : 1;
            await smtc.updateTimeline(
              PlaybackTimeline(
                startTimeMs: 0,
                endTimeMs: endMs,
                positionMs: position.clamp(0, endMs).toInt(),
                minSeekTimeMs: 0,
                maxSeekTimeMs: endMs,
              ),
            );
          }
          if (changedStatus || changedTrack) {
            await smtc.setPlaybackStatus(
              view.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
            );
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          // Native SMTC is an optional system integration, never fatal to audio.
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_smtc != null) {
      ref.listen<PlaybackView>(
        playbackControllerProvider,
        (previous, next) => _refresh(next),
      );
    }
    return widget.child;
  }

  @override
  void dispose() {
    unawaited(_buttons?.cancel());
    final smtc = _smtc;
    if (smtc != null) {
      unawaited(_operations.then((_) => smtc.dispose()));
    }
    super.dispose();
  }
}
