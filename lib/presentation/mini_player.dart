import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/playback_controller.dart';
import '../l10n/app_localizations.dart';
import 'album_cover_thumbnail.dart';
import 'now_playing_page.dart';

/// One-row player shared by mobile, Windows and Linux library screens.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider);
    final track = playback.track;
    if (track == null) return const SizedBox.shrink();
    final labels = AppLocalizations.of(context)!;
    final max = playback.duration.inMilliseconds;
    final progress = max > 0
        ? (playback.position.inMilliseconds / max).clamp(0.0, 1.0)
        : null;

    void openPlayer() {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const NowPlayingPage()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 540;
        return Material(
          elevation: 2,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 68,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    InkWell(
                      key: const ValueKey('mini-player-open-artwork'),
                      onTap: openPlayer,
                      child: AlbumCoverThumbnail(
                        key: ValueKey('mini-art-${track.path}:${track.etag}'),
                        track: track,
                        size: 44,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        key: const ValueKey('mini-player-open'),
                        onTap: openPlayer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playback.failed
                                    ? labels.playbackError
                                    : track.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                track.displayArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (wide)
                      IconButton(
                        key: const ValueKey('mini-player-previous'),
                        tooltip: labels.prev,
                        onPressed: () => ref
                            .read(playbackControllerProvider.notifier)
                            .previous(),
                        icon: const Icon(Icons.skip_previous),
                      ),
                    IconButton(
                      key: const ValueKey('mini-player-play-pause'),
                      tooltip: playback.playing ? labels.pause : labels.play,
                      icon: playback.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              playback.playing ? Icons.pause : Icons.play_arrow,
                            ),
                      onPressed: playback.loading
                          ? null
                          : () => ref
                                .read(playbackControllerProvider.notifier)
                                .pauseOrResume(),
                    ),
                    IconButton(
                      key: const ValueKey('mini-player-next'),
                      tooltip: labels.next,
                      icon: const Icon(Icons.skip_next),
                      onPressed: () =>
                          ref.read(playbackControllerProvider.notifier).next(),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              if (progress != null)
                LinearProgressIndicator(
                  key: const ValueKey('mini-player-progress'),
                  value: progress,
                  minHeight: 2,
                )
              else if (playback.loading)
                const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        );
      },
    );
  }
}
