import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../cloud/cloud_mail_webdav.dart';
import '../../domain/remote_track.dart';
import '../../domain/track_queue.dart';
import '../library/cloud_music_service.dart';
import 'cloud_range_audio_source.dart';
import 'media_tag_factory.dart';
import 'two_track_cache.dart';

class PlaybackView {
  const PlaybackView({
    this.track,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.loading = false,
    this.failed = false,
    this.failureCode,
    this.cacheFraction,
    this.shuffled = false,
    this.repeatMode = PlayerRepeatMode.off,
  });

  final RemoteTrack? track;
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool loading;
  final bool failed;

  /// Privacy-safe diagnostic classification, never an exception message.
  final String? failureCode;
  /// Fraction of the current file downloaded to temporary disk, if cached.
  final double? cacheFraction;
  final bool shuffled;
  final PlayerRepeatMode repeatMode;

  PlaybackView withPlaybackFailure(String fallbackCode) => withUpdates(
    failed: true,
    playing: false,
    loading: false,
    failureCode: failureCode ?? fallbackCode,
  );

  PlaybackView withUpdates({
    RemoteTrack? track,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
    bool? failed,
    String? failureCode,
    double? cacheFraction,
    bool? shuffled,
    PlayerRepeatMode? repeatMode,
  }) => PlaybackView(
    track: track ?? this.track,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    failureCode: failureCode ?? this.failureCode,
    cacheFraction: cacheFraction ?? this.cacheFraction,
    shuffled: shuffled ?? this.shuffled,
    repeatMode: repeatMode ?? this.repeatMode,
  );
}

/// Pure lifecycle guard for asynchronous platform playback events.
/// Events that arrive after Stop or during a source replacement must not
/// resurrect a cleared/transitioning player state.
bool acceptsPlaybackEvent({
  required bool disposed,
  required bool switching,
  required bool hasQueue,
  required bool hasTrack,
}) => !disposed && !switching && hasQueue && hasTrack;

class PlaybackController extends Notifier<PlaybackView> {
  AudioPlayer? _player;
  Future<TwoTrackAudioCache>? _cacheFuture;
  TrackQueue? _queue;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _closed = false;
  bool _changingTrack = false;
  RemoteTrack? _pendingTrack;
  int _operationGeneration = 0;
  bool _streamDeliveredBytes = false;

  @override
  PlaybackView build() {
    ref.onDispose(() {
      _closed = true;
      _pendingTrack = null;
      _operationGeneration++;
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      final player = _player;
      if (player != null) unawaited(player.dispose());
      final cacheFuture = _cacheFuture;
      if (cacheFuture != null) {
        unawaited(
          cacheFuture
              .then((cache) => cache.close())
              .onError((Object _, StackTrace _) {}),
        );
      }
    });
    return const PlaybackView();
  }

  bool get _acceptPlaybackEvent => acceptsPlaybackEvent(
    disposed: _closed,
    switching: _changingTrack,
    hasQueue: _queue != null,
    hasTrack: state.track != null,
  );

  void _onCacheProgress(RemoteTrack track, int downloadedBytes) {
    if (!_acceptPlaybackEvent || _queue?.current.path != track.path ||
        state.track?.etag != track.etag ||
        state.track?.sizeBytes != track.sizeBytes) return;
    final fraction = track.sizeBytes > 0
        ? (downloadedBytes / track.sizeBytes).clamp(0.0, 1.0)
        : 0.0;
    state = state.withUpdates(cacheFraction: fraction);
  }

  AudioPlayer _ensurePlayer() {
    if (_player != null) return _player!;
    final audio = AudioPlayer();
    _subscriptions.add(
      audio.positionStream.listen((position) {
        if (_acceptPlaybackEvent) state = state.withUpdates(position: position);
      }),
    );
    _subscriptions.add(
      audio.durationStream.listen((duration) {
        if (_acceptPlaybackEvent && duration != null) {
          state = state.withUpdates(duration: duration);
        }
      }),
    );
    _subscriptions.add(
      audio.playingStream.listen((playing) {
        // A stale false event emitted while replacing the source must not
        // overwrite the requested Play state or flash the Play icon.
        if (_acceptPlaybackEvent) {
          state = state.withUpdates(playing: playing);
        }
      }),
    );
    _subscriptions.add(
      audio.processingStateStream.listen((processing) {
        if (!_acceptPlaybackEvent) return;
        state = state.withUpdates(
          loading:
              processing == ProcessingState.loading ||
              processing == ProcessingState.buffering,
        );
        if (processing == ProcessingState.completed) {
          unawaited(next(manual: false));
        }
      }),
    );
    _subscriptions.add(
      audio.errorStream.listen((error) {
        if (_acceptPlaybackEvent) {
          // Do not expose native error messages, URLs or HTTP headers.
          state = state.withUpdates(
            failed: true,
            playing: false,
            loading: false,
            failureCode:
                state.failureCode ??
                'P03-${error.code}-${_streamDeliveredBytes ? 'data' : 'no-data'}',
          );
        }
      }),
    );
    return _player = audio;
  }

  Future<void> _open(RemoteTrack track) async {
    if (_closed) return;
    if (_changingTrack) {
      // The most recent user selection wins while an earlier source opens.
      _pendingTrack = track;
      _operationGeneration++;
      state = PlaybackView(
        track: track,
        loading: true,
        shuffled: _queue?.shuffled ?? false,
        repeatMode: _queue?.repeatMode ?? PlayerRepeatMode.off,
      );
      return;
    }
    _changingTrack = true;
    final generation = ++_operationGeneration;
    _streamDeliveredBytes = false;
    state = PlaybackView(
      track: track,
      loading: true,
      shuffled: _queue?.shuffled ?? false,
      repeatMode: _queue?.repeatMode ?? PlayerRepeatMode.off,
    );
    try {
      final reader = ref.read(cloudMusicServiceProvider);
      TwoTrackAudioCache? activeCache;
      try {
        _cacheFuture ??= TwoTrackAudioCache.open(
          fetch:
              (
                String path,
                int offset,
                int length, {
                WebDavRequestCancellation? cancellation,
              }) => reader.readRange(
                path,
                offset,
                length,
                cancellation: cancellation,
              ),
          onProgress: _onCacheProgress,
        );
        activeCache = await _cacheFuture!;
        await activeCache.configure(track, _queue?.nextForPrefetch());
      } catch (_) {
        // A read-only cache is an optimization; playback can stream directly.
        final abandoned = _cacheFuture;
        _cacheFuture = null;
        if (abandoned != null) {
          unawaited(
            abandoned
                .then((cache) => cache.close())
                .onError((Object _, StackTrace _) {}),
          );
        }
        activeCache = null;
      }
      if (_closed || generation != _operationGeneration) return;
      final cache = activeCache;
      final player = _ensurePlayer();
      await player.setAudioSource(
        CloudRangeAudioSource(
          track,
          cache == null
              ? reader.readRange
              : (path, offset, length) => cache.read(path, offset, length),
          mediaTag: ref.read(mediaTagFactoryProvider)(track),
          onRangeSuccess: () {
            if (!_closed && generation == _operationGeneration) {
              _streamDeliveredBytes = true;
            }
          },
          onRangeFailure: (code) {
            if (!_closed && generation == _operationGeneration) {
              state = state.withUpdates(
                failed: true,
                playing: false,
                loading: false,
                failureCode: code,
              );
            }
          },
        ),
      );
      if (_closed || generation != _operationGeneration) {
        await player.stop();
        return;
      }
      // Reflect the user's requested Play immediately. Some backends emit a
      // delayed/duplicate "playing=false" while replacing their source.
      state = state.withUpdates(
        playing: true,
        loading: false,
        failed: false,
        cacheFraction: cache?.fractionFor(track),
      );
      unawaited(
        player.play().catchError((Object _) {
          if (!_closed && generation == _operationGeneration) {
            state = state.withUpdates(
              playing: false,
              loading: false,
              failed: true,
              failureCode: state.failureCode ?? 'P02',
            );
          }
        }),
      );
    } catch (_) {
      // A cancelled open must not resurrect a failed state after Stop.
      if (!_closed && generation == _operationGeneration) {
        state = state.withUpdates(
          failed: true,
          playing: false,
          loading: false,
          failureCode: state.failureCode ?? 'P01',
        );
      }
    } finally {
      _changingTrack = false;
      final pending = _pendingTrack;
      _pendingTrack = null;
      if (!_closed && pending != null && _queue != null) {
        unawaited(_open(pending));
      }
    }
  }

  Future<void> playFromList(List<RemoteTrack> tracks, int index) async {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;
    _queue = TrackQueue(tracks, index);
    await _open(_queue!.current);
  }

  Future<void> playTrack(RemoteTrack track) async {
    await playFromList([track], 0);
  }

  Future<void> next({bool manual = true}) async {
    if (_closed) return;
    final newTrack = _queue?.next(manual: manual);
    if (newTrack != null) {
      await _open(newTrack);
    } else if (!manual) {
      await stop();
    }
  }

  Future<void> previous() async {
    if (_closed) return;
    final newTrack = _queue?.previous();
    if (newTrack != null) {
      await _open(newTrack);
    } else {
      await seek(Duration.zero);
    }
  }

  void setShuffle(bool enabled) {
    _queue?.setShuffled(enabled);
    state = state.withUpdates(shuffled: _queue?.shuffled ?? enabled);
  }

  void cycleRepeat() {
    final repeatMode = _queue?.cycleRepeat() ?? PlayerRepeatMode.off;
    state = state.withUpdates(repeatMode: repeatMode);
  }

  Future<void> retry() async {
    if (_closed || _changingTrack || _queue == null) return;
    await _open(_queue!.current);
  }

  Future<void> pauseOrResume() async {
    // Do not resume an old audio source after Stop has cleared the queue.
    if (_closed || _changingTrack) return;
    if (_queue == null || state.track == null) return;
    if (state.failed) {
      await retry();
      return;
    }
    final player = _player;
    if (player == null) return;
    final generation = _operationGeneration;
    void recordFailure() {
      // Ignore a failed resume if Stop or track replacement happened first.
      if (!_acceptPlaybackEvent || generation != _operationGeneration) return;
      state = state.withPlaybackFailure('P02');
    }

    try {
      if (player.playing) {
        await player.pause();
      } else {
        unawaited(
          player.play().catchError((Object _) {
            recordFailure();
          }),
        );
      }
    } catch (_) {
      recordFailure();
    }
  }

  Future<void> seek(Duration position) async {
    if (_closed || _changingTrack) return;
    if (_queue == null || state.track == null) return;
    await _player?.seek(position);
  }

  Future<void> stop() async {
    // Invalidate any pending setAudioSource before waiting for I/O.
    final generation = ++_operationGeneration;
    _pendingTrack = null;
    _queue = null;
    final cacheFuture = _cacheFuture;
    _cacheFuture = null;
    await _player?.stop();
    if (cacheFuture != null) {
      try {
        await (await cacheFuture).close();
      } catch (_) {
        // Stopping playback must succeed even when temporary storage fails.
      }
    }
    if (!_closed && generation == _operationGeneration) {
      state = const PlaybackView();
    }
  }
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackView>(PlaybackController.new);
