import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/playback_controller.dart';
import '../data/library/cloud_music_service.dart';
import '../domain/remote_track.dart';
import '../domain/track_queue.dart';
import '../l10n/app_localizations.dart';
import 'album_detail_page.dart';
import 'library_page.dart';

/// Responsive single-session player: portrait on phones, two columns on desktop.
class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  List<RemoteTrack> _catalog(WidgetRef ref) {
    final catalog = ref.read(cloudCatalogProvider);
    return switch (catalog) {
      AsyncData<List<RemoteTrack>>(:final value) => value,
      _ => const <RemoteTrack>[],
    };
  }

  void _openAlbum(BuildContext context, WidgetRef ref, RemoteTrack track) {
    final albumTracks = _catalog(
      ref,
    ).where((candidate) => candidate.albumKey == track.albumKey).toList();
    if (albumTracks.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AlbumDetailPage(tracks: albumTracks),
      ),
    );
  }

  void _openArtist(BuildContext context, WidgetRef ref, RemoteTrack track) {
    final artistTracks = _catalog(ref)
        .where((candidate) => candidate.displayArtist == track.displayArtist)
        .toList();
    if (artistTracks.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ArtistDetailPage(artist: track.displayArtist, tracks: artistTracks),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider);
    final labels = AppLocalizations.of(context)!;
    final track = playback.track;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(labels.nowPlaying)),
      body: track == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_off, size: 64, color: colors.outline),
                  const SizedBox(height: 16),
                  Text(labels.noTrackPlaying),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;
                final coverSize = wide
                    ? math.min(
                        360.0,
                        math.max(160.0, constraints.maxHeight - 64),
                      )
                    : math.min(360.0, math.max(0.0, constraints.maxWidth - 48));
                final cover = Center(
                  child: SizedBox(
                    width: coverSize,
                    height: coverSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _TrackArtwork(
                        key: ValueKey(
                          '${track.path}:${track.etag}:${track.sizeBytes}',
                        ),
                        track: track,
                        size: coverSize,
                      ),
                    ),
                  ),
                );
                final details = ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    key: const ValueKey('expanded-player-controls'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.displayTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        key: const ValueKey('now-playing-artist'),
                        onPressed: () => _openArtist(context, ref, track),
                        child: Text(track.displayArtist),
                      ),
                      TextButton(
                        key: const ValueKey('now-playing-album'),
                        onPressed: () => _openAlbum(context, ref, track),
                        child: Text(
                          track.displayAlbum,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (playback.failed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Text(
                                labels.playbackError,
                                style: TextStyle(color: colors.error),
                                textAlign: TextAlign.center,
                              ),
                              if (playback.failureCode != null)
                                Text(
                                  labels.playbackErrorCode(
                                    playback.failureCode!,
                                  ),
                                  key: const ValueKey(
                                    'playback-diagnostic-code',
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      if (playback.loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        ),
                      const SizedBox(height: 12),
                      _PlayerSeekBar(
                        key: ValueKey('seek-${track.path}'),
                        trackPath: track.path,
                        position: playback.position,
                        duration: playback.duration,
                        cacheFraction: playback.cacheFraction,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: playback.shuffled
                                ? labels.shuffleOn
                                : labels.shuffleOff,
                            icon: Icon(
                              playback.shuffled
                                  ? Icons.shuffle_on_outlined
                                  : Icons.shuffle,
                            ),
                            color: playback.shuffled ? colors.primary : null,
                            onPressed: () => ref
                                .read(playbackControllerProvider.notifier)
                                .setShuffle(!playback.shuffled),
                          ),
                          IconButton(
                            tooltip: labels.prev,
                            icon: const Icon(Icons.skip_previous),
                            iconSize: 34,
                            onPressed: () => ref
                                .read(playbackControllerProvider.notifier)
                                .previous(),
                          ),
                          IconButton.filled(
                            key: const ValueKey('now-playing-play-pause'),
                            tooltip: playback.playing
                                ? labels.pause
                                : labels.play,
                            icon: Icon(
                              playback.playing ? Icons.pause : Icons.play_arrow,
                            ),
                            iconSize: 36,
                            onPressed: () => ref
                                .read(playbackControllerProvider.notifier)
                                .pauseOrResume(),
                          ),
                          IconButton(
                            tooltip: labels.next,
                            icon: const Icon(Icons.skip_next),
                            iconSize: 34,
                            onPressed: () => ref
                                .read(playbackControllerProvider.notifier)
                                .next(),
                          ),
                          IconButton(
                            tooltip: switch (playback.repeatMode) {
                              PlayerRepeatMode.off => labels.repeatOff,
                              PlayerRepeatMode.all => labels.repeatAll,
                              PlayerRepeatMode.one => labels.repeatOne,
                            },
                            icon: Icon(
                              playback.repeatMode == PlayerRepeatMode.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                            ),
                            color: playback.repeatMode != PlayerRepeatMode.off
                                ? colors.primary
                                : null,
                            onPressed: () => ref
                                .read(playbackControllerProvider.notifier)
                                .cycleRepeat(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: wide
                          ? Row(
                              key: const ValueKey('now-playing-wide'),
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: cover),
                                const SizedBox(width: 24),
                                Expanded(child: Center(child: details)),
                              ],
                            )
                          : Column(
                              key: const ValueKey('now-playing-portrait'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                cover,
                                const SizedBox(height: 20),
                                details,
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Commit a seek only when dragging finishes, avoiding hundreds of Range GETs.
class _PlayerSeekBar extends ConsumerStatefulWidget {
  const _PlayerSeekBar({
    required this.trackPath,
    required this.position,
    required this.duration,
    this.cacheFraction,
    super.key,
  });

  final String trackPath;
  final Duration position;
  final Duration duration;
  final double? cacheFraction;

  @override
  ConsumerState<_PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends ConsumerState<_PlayerSeekBar> {
  double? _draft;

  @override
  void didUpdateWidget(covariant _PlayerSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackPath != widget.trackPath) _draft = null;
  }

  String _time(int milliseconds) {
    final value = Duration(milliseconds: milliseconds);
    return '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds;
    final current = widget.position.inMilliseconds.clamp(
      0,
      totalMs > 0 ? totalMs : 0,
    );
    final sliderValue = (_draft ?? current.toDouble()).clamp(
      0.0,
      totalMs > 0 ? totalMs.toDouble() : 1.0,
    );
    return Column(
      children: [
        Slider(
          key: const ValueKey('now-playing-seek'),
          value: sliderValue,
          min: 0,
          max: totalMs > 0 ? totalMs.toDouble() : 1,
          onChanged: totalMs > 0
              ? (value) => setState(() => _draft = value)
              : null,
          onChangeEnd: totalMs > 0
              ? (value) {
                  setState(() => _draft = null);
                  ref
                      .read(playbackControllerProvider.notifier)
                      .seek(Duration(milliseconds: value.round()));
                }
              : null,
        ),
        if (widget.cacheFraction != null)
          Semantics(
            label: 'Загрузка текущего трека',
            value: '${(widget.cacheFraction! * 100).round()}%',
            child: LinearProgressIndicator(
              key: const ValueKey('now-playing-cache-progress'),
              value: widget.cacheFraction!.clamp(0.0, 1.0),
              minHeight: 3,
            ),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(_time(sliderValue.round())), Text(_time(totalMs))],
        ),
      ],
    );
  }
}

class _TrackArtwork extends ConsumerStatefulWidget {
  const _TrackArtwork({required this.track, required this.size, super.key});

  final RemoteTrack track;
  final double size;

  @override
  ConsumerState<_TrackArtwork> createState() => _TrackArtworkState();
}

class _TrackArtworkState extends ConsumerState<_TrackArtwork> {
  late final Future<Uint8List?> _image;

  @override
  void initState() {
    super.initState();
    _image = ref
        .read(cloudMusicServiceProvider)
        .readArtwork(widget.track)
        .catchError((Object error, StackTrace stackTrace) => null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget placeholder() => Icon(
      Icons.album,
      size: widget.size / 2,
      color: colors.onSurfaceVariant,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FutureBuilder<Uint8List?>(
        future: _image,
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null || image.isEmpty) return placeholder();
          return Image.memory(
            image,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            cacheWidth: 800,
            cacheHeight: 800,
            errorBuilder: (context, error, stackTrace) => placeholder(),
          );
        },
      ),
    );
  }
}
