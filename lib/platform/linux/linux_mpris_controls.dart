import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/audio/playback_controller.dart';
import '../../domain/remote_track.dart';

CloudLinuxAudioHandler? _linuxHandler;

/// MPRIS is optional: a machine without a D-Bus session must still play audio.
Future<void> initializeLinuxMprisControls() async {
  if (!Platform.isLinux) return;
  try {
    _linuxHandler = await AudioService.init(
      builder: CloudLinuxAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'cloudmail_player.mpris',
        androidNotificationChannelName: 'teStPlaYclouDE',
        androidNotificationOngoing: false,
      ),
    );
  } catch (_) {
    _linuxHandler = null;
  }
}

/// Do not expose authenticated remote paths as MPRIS track identifiers.
MediaItem linuxMediaItemForTrack(RemoteTrack track) {
  final opaqueId = sha256
      .convert(
        utf8.encode('${track.path}|${track.etag ?? ''}|${track.sizeBytes}'),
      )
      .toString();
  return MediaItem(
    id: '/com/cloudmail_player/track/t$opaqueId',
    title: track.displayTitle,
    artist: track.displayArtist,
    album: track.displayAlbum,
    duration: track.duration,
  );
}

/// Linux D-Bus MPRIS actions delegate to the same queue and audio engine.
class CloudLinuxAudioHandler extends BaseAudioHandler {
  PlaybackView _view = const PlaybackView();
  String? _mediaIdentity;

  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onStop;
  Future<void> Function()? onNext;
  Future<void> Function()? onPrevious;
  Future<void> Function(Duration position)? onSeek;

  void synchronize(PlaybackView view) {
    _view = view;
    final track = view.track;
    final identity = track == null
        ? null
        : '${track.path}|${track.etag ?? ''}|${track.sizeBytes}';
    if (identity != _mediaIdentity) {
      _mediaIdentity = identity;
      mediaItem.add(track == null ? null : linuxMediaItemForTrack(track));
      queue.add(
        track == null ? <MediaItem>[] : [linuxMediaItemForTrack(track)],
      );
    }

    final available = track != null;
    playbackState.add(
      PlaybackState(
        controls: available
            ? [
                MediaControl.skipToPrevious,
                view.playing ? MediaControl.pause : MediaControl.play,
                MediaControl.skipToNext,
                MediaControl.stop,
              ]
            : <MediaControl>[],
        systemActions: available ? const {MediaAction.seek} : const {},
        processingState: !available
            ? AudioProcessingState.idle
            : view.failed
            ? AudioProcessingState.error
            : view.loading
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
        playing: view.playing,
        updatePosition: view.position,
        speed: 1.0,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (_view.track != null && !_view.playing) await onPlay?.call();
  }

  @override
  Future<void> pause() async {
    if (_view.playing) await onPause?.call();
  }

  @override
  Future<void> stop() async {
    await onStop?.call();
  }

  @override
  Future<void> skipToNext() async {
    await onNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    await onPrevious?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    await onSeek?.call(position);
  }

  void unbind() {
    onPlay = null;
    onPause = null;
    onStop = null;
    onNext = null;
    onPrevious = null;
    onSeek = null;
  }
}

/// D-Bus callbacks operate through Riverpod's existing PlaybackController.
class LinuxMprisBridge extends ConsumerStatefulWidget {
  const LinuxMprisBridge({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<LinuxMprisBridge> createState() => _LinuxMprisBridgeState();
}

class _LinuxMprisBridgeState extends ConsumerState<LinuxMprisBridge> {
  @override
  void initState() {
    super.initState();
    final handler = _linuxHandler;
    if (handler == null) return;
    final controller = ref.read(playbackControllerProvider.notifier);
    handler.onPlay = () async {
      if (!ref.read(playbackControllerProvider).playing) {
        await controller.pauseOrResume();
      }
    };
    handler.onPause = () async {
      if (ref.read(playbackControllerProvider).playing) {
        await controller.pauseOrResume();
      }
    };
    handler.onStop = controller.stop;
    handler.onNext = () => controller.next();
    handler.onPrevious = controller.previous;
    handler.onSeek = controller.seek;
    handler.synchronize(ref.read(playbackControllerProvider));
  }

  @override
  Widget build(BuildContext context) {
    final handler = _linuxHandler;
    if (handler != null) {
      ref.listen<PlaybackView>(
        playbackControllerProvider,
        (previous, next) => handler.synchronize(next),
      );
    }
    return widget.child;
  }

  @override
  void dispose() {
    _linuxHandler?.unbind();
    super.dispose();
  }
}
