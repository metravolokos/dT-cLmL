import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/playback_controller.dart';
import '../domain/album_track_order.dart';
import '../domain/remote_track.dart';
import '../l10n/app_localizations.dart';
import 'album_cover_thumbnail.dart';
import 'mini_player.dart';

/// Full album route shared by Android, Windows and Linux.
/// Opening the album never starts playback; only explicit controls do.
class AlbumDetailPage extends ConsumerWidget {
  const AlbumDetailPage({required this.tracks, super.key});

  final List<RemoteTrack> tracks;

  String _duration(Duration? value) {
    if (value == null) return '';
    return '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = AppLocalizations.of(context)!;
    final sorted = List<RemoteTrack>.of(tracks)..sort(compareAlbumTracks);
    if (sorted.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(labels.libraryEmpty)),
      );
    }
    final first = sorted.first;
    final width = MediaQuery.sizeOf(context).width;
    final coverSize = width >= 720 ? 240.0 : 176.0;

    return Scaffold(
      appBar: AppBar(title: Text(first.displayAlbum)),
      bottomNavigationBar: const MiniPlayer(),
      body: CustomScrollView(
        key: const ValueKey('album-detail-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Wrap(
                spacing: 24,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AlbumCoverThumbnail(track: first, size: coverSize),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          first.displayAlbum,
                          key: const ValueKey('album-detail-title'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (first.albumArtist?.trim().isNotEmpty ?? false)
                              ? first.albumArtist!
                              : first.displayArtist,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('${labels.tracks}: ${sorted.length}'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              key: const ValueKey('album-play-all'),
                              onPressed: () => ref
                                  .read(playbackControllerProvider.notifier)
                                  .playFromList(sorted, 0),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(labels.play),
                            ),
                            OutlinedButton.icon(
                              key: const ValueKey('album-shuffle'),
                              onPressed: () async {
                                final controller = ref.read(
                                  playbackControllerProvider.notifier,
                                );
                                await controller.playFromList(sorted, 0);
                                controller.setShuffle(true);
                              },
                              icon: const Icon(Icons.shuffle),
                              label: Text(labels.shuffleOn),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final track = sorted[index];
              final number = track.trackNumber ?? index + 1;
              final discChange =
                  track.discNumber != null &&
                  (index == 0 ||
                      track.discNumber != sorted[index - 1].discNumber);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (discChange)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                      child: Text(
                        '${labels.albums} · ${track.discNumber}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ListTile(
                    key: ValueKey('album-track-${track.path}'),
                    leading: SizedBox(
                      width: 32,
                      child: Center(child: Text('$number')),
                    ),
                    title: Text(
                      track.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: track.displayArtist == first.displayArtist
                        ? null
                        : Text(track.displayArtist),
                    trailing: Text(_duration(track.duration)),
                    onTap: () => ref
                        .read(playbackControllerProvider.notifier)
                        .playFromList(sorted, index),
                  ),
                ],
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
