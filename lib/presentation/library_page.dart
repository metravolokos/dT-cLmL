import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../data/audio/playback_controller.dart';
import '../data/library/cloud_music_service.dart';
import '../data/library/catalog_import_progress.dart';
import '../domain/remote_track.dart';
import '../domain/album_track_order.dart';
import '../domain/library_search.dart';
import '../l10n/app_localizations.dart';
import 'album_cover_thumbnail.dart';
import 'album_detail_page.dart';
import 'mini_player.dart';

/// Displays the actual cloud catalog. Album/artist names are placeholders
/// until the bounded FLAC/ID3 tag scanner is enabled; no invented metadata.
class CloudLibraryPage extends ConsumerStatefulWidget {
  const CloudLibraryPage({required this.destination, super.key});

  final AppDestination destination;

  @override
  ConsumerState<CloudLibraryPage> createState() => _CloudLibraryPageState();
}

class _CloudLibraryPageState extends ConsumerState<CloudLibraryPage> {
  final Map<AppDestination, TextEditingController> _searchControllers = {};

  @override
  void dispose() {
    for (final controller in _searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _searchFor(AppDestination destination) =>
      _searchControllers.putIfAbsent(destination, TextEditingController.new);

  void _openAlbum(BuildContext context, List<RemoteTrack> tracks) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => AlbumDetailPage(tracks: tracks)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final tracksAsync = ref.watch(cloudCatalogProvider);
    final importProgress = ref.watch(catalogImportProgressProvider);
    final destination = widget.destination;
    final title = switch (destination) {
      AppDestination.tracks => strings.tracks,
      AppDestination.albums => strings.albums,
      AppDestination.artists => strings.artists,
      AppDestination.settings => strings.settings,
    };
    final tracks = switch (tracksAsync) {
      AsyncData<List<RemoteTrack>>(:final value) => value,
      _ => const <RemoteTrack>[],
    };
    final query = _searchFor(destination).text;
    final filtered = tracks
        .where((track) => matchesLibraryQuery(track, query))
        .toList();
    final groups = <String, List<RemoteTrack>>{};
    if (destination == AppDestination.albums ||
        destination == AppDestination.artists) {
      for (final track in filtered) {
        final key = destination == AppDestination.albums
            ? track.albumKey
            : track.displayArtist;
        groups.putIfAbsent(key, () => []).add(track);
      }
      if (destination == AppDestination.albums) {
        for (final group in groups.values) {
          group.sort(compareAlbumTracks);
        }
      }
    }
    return Column(
      key: ValueKey('page-${destination.name}'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                key: const ValueKey('refresh-library'),
                tooltip: strings.libraryRefresh,
                icon: const Icon(Icons.refresh),
                onPressed: importProgress.inProgress
                    ? null
                    : () => ref.read(cloudCatalogProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        if (importProgress.inProgress || importProgress.failed)
          Padding(
            key: const ValueKey('library-import-progress'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(switch (importProgress.phase) {
                    CatalogImportPhase.listing =>
                      strings.libraryReceiveProgress(
                        importProgress.receivedBytes ~/ 1024,
                      ),
                    CatalogImportPhase.metadata =>
                      strings.libraryMetadataProgress(
                        importProgress.done,
                        importProgress.total,
                      ),
                    CatalogImportPhase.failed => strings.libraryError,
                    _ => '',
                  }, key: const ValueKey('library-progress-label')),
                  const SizedBox(height: 6),
                  if (importProgress.inProgress)
                    LinearProgressIndicator(
                      value:
                          importProgress.phase == CatalogImportPhase.metadata &&
                              importProgress.total > 0
                          ? importProgress.done / importProgress.total
                          : null,
                    ),
                ],
              ),
            ),
          ),
        if (tracks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: ValueKey('library-search-${destination.name}'),
              controller: _searchFor(destination),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: strings.librarySearch,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        if (tracks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(strings.libraryLoaded(tracks.length)),
          ),
        Expanded(
          child: tracksAsync.when(
            loading: () => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(strings.libraryLoading),
                ],
              ),
            ),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.libraryError),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(cloudCatalogProvider.notifier).refresh(),
                    child: Text(strings.libraryRefresh),
                  ),
                ],
              ),
            ),
            data: (_) {
              if (tracks.isEmpty) {
                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 48),
                          const SizedBox(height: 10),
                          Text(strings.libraryDisconnected),
                          const SizedBox(height: 10),
                          Text(strings.libraryHint),
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const ValueKey('load-library'),
                            onPressed: () => ref
                                .read(cloudCatalogProvider.notifier)
                                .refresh(),
                            child: Text(strings.libraryRefresh),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              if (groups.isNotEmpty) {
                final keys = groups.keys.toList()..sort();
                if (destination == AppDestination.albums) {
                  return GridView.builder(
                    key: const ValueKey('album-grid'),
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.74,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final albumTracks = groups[keys[index]]!;
                      final first = albumTracks.first;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('album-open-${first.albumKey}'),
                          onTap: () => _openAlbum(context, albumTracks),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: LayoutBuilder(
                                  builder: (context, constraints) =>
                                      AlbumCoverThumbnail(
                                        key: ValueKey(
                                          '${first.path}:${first.etag}',
                                        ),
                                        track: first,
                                        size: constraints.maxWidth,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      first.displayAlbum,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      '${first.displayArtist} · ${albumTracks.length}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return ListView.builder(
                  key: const ValueKey('artist-list'),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final artist = keys[index];
                    final artistTracks = groups[artist]!;
                    return ListTile(
                      key: ValueKey('artist-open-$artist'),
                      leading: const Icon(Icons.person_outline),
                      title: Text(artist),
                      subtitle: Text('${artistTracks.length}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ArtistDetailPage(
                            artist: artist,
                            tracks: artistTracks,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _TrackTile(track: filtered[index], queue: filtered),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrackTile extends ConsumerWidget {
  const _TrackTile({required this.track, required this.queue});
  final RemoteTrack track;
  final List<RemoteTrack> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.audiotrack),
      title: Text(
        track.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.play_arrow),
      onTap: () => ref
          .read(playbackControllerProvider.notifier)
          .playFromList(
            queue,
            queue.indexWhere((item) => item.path == track.path),
          ),
    );
  }
}

/// Artist drill-down: albums first, then every track by this artist.
/// Uses the same album identity and track ordering as the main library.
/// No additional WebDAV calls or album thumbnails are eagerly fetched.
class ArtistDetailPage extends ConsumerWidget {
  const ArtistDetailPage({
    required this.artist,
    required this.tracks,
    super.key,
  });

  final String artist;
  final List<RemoteTrack> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final albums = <String, List<RemoteTrack>>{};
    for (final track in tracks) {
      albums.putIfAbsent(track.albumKey, () => <RemoteTrack>[]).add(track);
    }
    for (final group in albums.values) {
      group.sort(compareAlbumTracks);
    }
    final albumGroups = albums.values.toList()
      ..sort((a, b) => a.first.displayAlbum.compareTo(b.first.displayAlbum));
    final allTracks = <RemoteTrack>[for (final group in albumGroups) ...group];

    return Scaffold(
      appBar: AppBar(title: Text(artist)),
      bottomNavigationBar: const MiniPlayer(),
      body: CustomScrollView(
        key: const ValueKey('artist-detail-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                strings.albums,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              key: const ValueKey('artist-album-grid'),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 0.75,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: albumGroups.length,
              itemBuilder: (context, index) {
                final albumTracks = albumGroups[index];
                final first = albumTracks.first;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('artist-album-${first.albumKey}'),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => AlbumDetailPage(tracks: albumTracks),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AlbumCoverThumbnail(track: first, size: 160),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            first.displayAlbum,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                strings.tracks,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverList.builder(
            itemCount: allTracks.length,
            itemBuilder: (context, index) =>
                _TrackTile(track: allTracks[index], queue: allTracks),
          ),
        ],
      ),
    );
  }
}
