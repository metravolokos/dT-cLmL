import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/library/cloud_music_service.dart';
import '../domain/remote_track.dart';

/// Lazy album cover: decoded off the UI isolate and cached on disk by account.
class AlbumCoverThumbnail extends ConsumerStatefulWidget {
  const AlbumCoverThumbnail({required this.track, this.size = 52, super.key});

  final RemoteTrack track;
  final double size;

  @override
  ConsumerState<AlbumCoverThumbnail> createState() =>
      _AlbumCoverThumbnailState();
}

class _AlbumCoverThumbnailState extends ConsumerState<AlbumCoverThumbnail> {
  late final Future<Uint8List?> imageFuture;

  @override
  void initState() {
    super.initState();
    imageFuture = ref
        .read(cloudMusicServiceProvider)
        .readThumbnail(widget.track)
        .catchError((Object error, StackTrace stackTrace) => null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget placeholder() => Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.album_outlined, color: colors.onSurfaceVariant),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FutureBuilder<Uint8List?>(
        future: imageFuture,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) return placeholder();
          return Image.memory(
            bytes,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            cacheWidth: (widget.size * 2).round(),
            cacheHeight: (widget.size * 2).round(),
            errorBuilder: (context, error, stackTrace) => placeholder(),
          );
        },
      ),
    );
  }
}
