import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../cloud/cloud_connection_service.dart';
import '../../cloud/cloud_mail_webdav.dart';
import '../../domain/remote_track.dart';
import '../artwork/flac_artwork_reader.dart';
import '../artwork/cover_thumbnail_cache.dart';
import '../db/catalog_database.dart';
import '../tags/flac_tag_reader.dart';
import '../tags/mp3_tag_reader.dart';
import 'catalog_import_progress.dart';

/// The only data layer that resolves protected credentials for WebDAV reads.
class CloudMusicService {
  CloudMusicService({
    CloudMailWebDavClient? client,
    CloudCredentialVault? vault,
  }) : _client = client ?? CloudMailWebDavClient(),
       _vault = vault ?? FlutterSecureCredentialVault();

  final CloudMailWebDavClient _client;
  final CloudCredentialVault _vault;
  CloudCredentials? _credentials;
  CatalogDatabase? _catalog;
  String? _catalogFor;
  bool _closed = false;
  Future<CoverThumbnailCache>? _thumbnailCache;
  // Three images max, with each image independently capped at 5 MiB.
  final LinkedHashMap<String, Future<Uint8List?>> _artworkCache =
      LinkedHashMap<String, Future<Uint8List?>>();

  static const String _usernameKey = 'cloud_mail_username';
  static const String _passwordKey = 'cloud_mail_app_password';

  Future<CloudCredentials> _sessionCredentials() async {
    if (_closed) throw StateError('Cloud session closed');
    if (_credentials != null) return _credentials!;
    final user = await _vault.read(_usernameKey);
    final password = await _vault.read(_passwordKey);
    // Vault reads are asynchronous: Disconnect may dispose this service
    // while the secure store is still returning the previous credentials.
    if (_closed) throw StateError('Cloud session closed');
    if (user == null || user.isEmpty || password == null || password.isEmpty) {
      throw const CloudMailException(CloudMailErrorCode.credentialsRequired);
    }
    return _credentials = CloudCredentials(
      username: user,
      appPassword: password,
    );
  }

  Future<CatalogDatabase> _getCatalog() async {
    final credentials = await _sessionCredentials();
    if (_catalog != null && _catalogFor == credentials.username) {
      return _catalog!;
    }
    await _catalog?.close();
    _catalogFor = credentials.username;
    return _catalog = await openAccountCatalog(credentials.username);
  }

  Future<List<RemoteTrack>> loadCatalog({
    void Function(int receivedBytes)? onResponseBytes,
  }) async {
    final credentials = await _sessionCredentials();
    final entries = await _client.propfind(
      credentials,
      depth: 1,
      onResponseBytes: onResponseBytes,
    );
    final tracks = <RemoteTrack>[];
    for (final entry in entries) {
      if (entry.isCollection || entry.relativePath.isEmpty) continue;
      final path = entry.relativePath;
      final lower = path.toLowerCase();
      if (!(lower.endsWith('.flac') ||
          lower.endsWith('.mp3') ||
          lower.endsWith('.m4a') ||
          lower.endsWith('.ogg') ||
          lower.endsWith('.opus') ||
          lower.endsWith('.wav'))) {
        continue;
      }
      final size = entry.sizeBytes;
      if (size == null || size <= 0) continue;
      tracks.add(RemoteTrack(path: path, sizeBytes: size, etag: entry.etag));
    }
    final catalog = await _getCatalog();
    await catalog.applyScan(tracks);
    return catalog.readTracks();
  }

  Future<List<RemoteTrack>> readCachedCatalog() async {
    try {
      final catalog = await _getCatalog();
      return await catalog.readTracks();
    } on CloudMailException catch (error) {
      if (error.code == CloudMailErrorCode.credentialsRequired) {
        return const <RemoteTrack>[];
      }
      rethrow;
    }
  }

  Future<Uint8List> readRange(
    String path,
    int offset,
    int length, {
    WebDavRequestCancellation? cancellation,
  }) async {
    final credentials = await _sessionCredentials();
    return _client.getRange(
      credentials,
      path: path,
      offset: offset,
      length: length,
      cancellation: cancellation,
    );
  }

  /// Embedded artwork is loaded lazily for the displayed track only.
  Future<Uint8List?> readArtwork(RemoteTrack track) async {
    if (_closed) throw StateError('Cloud session closed');
    if (!track.isFlac) return null;
    final key =
        '${track.path}\u0000${track.etag ?? ''}\u0000${track.sizeBytes}';
    final cached = _artworkCache.remove(key);
    if (cached != null) {
      _artworkCache[key] = cached;
      return cached;
    }
    final request = FlacArtworkReader(
      readRange,
    ).read(track.path, track.sizeBytes).then((artwork) => artwork?.bytes);
    _artworkCache[key] = request;
    if (_artworkCache.length > 3) {
      _artworkCache.remove(_artworkCache.keys.first);
    }
    try {
      return await request;
    } catch (_) {
      if (identical(_artworkCache[key], request)) {
        _artworkCache.remove(key);
      }
      rethrow;
    }
  }

  /// Persistent, account-scoped miniatures use only bounded cover Range reads.
  Future<Uint8List?> readThumbnail(RemoteTrack track) async {
    if (_closed) throw StateError('Cloud session closed');
    if (!track.isFlac) return null;
    final account = (await _sessionCredentials()).username;
    if (_closed) throw StateError('Cloud session closed');
    _thumbnailCache ??= getApplicationCacheDirectory().then((root) {
      final accountKey = sha256.convert(utf8.encode(account)).toString();
      return CoverThumbnailCache(
        Directory(p.join(root.path, 'cloud_cover_thumbnails', accountKey)),
      );
    });
    final cache = await _thumbnailCache!;
    if (_closed) throw StateError('Cloud session closed');
    final sourceIdentity =
        '$account\\u0000${track.path}\\u0000${track.etag ?? ''}\\u0000${track.sizeBytes}';
    return cache.read(sourceIdentity, () => readArtwork(track));
  }

  /// The UI gets a usable file list immediately; tags update in background
  /// with bounded concurrency and never consume a full audio file.
  Future<void> scanMetadata({
    void Function(List<RemoteTrack> tracks, int done, int total)? onProgress,
    void Function(int total)? onStarted,
    bool Function()? isCancelled,
  }) async {
    final catalog = await _getCatalog();
    final pending = await catalog.unindexedTracks();
    onStarted?.call(pending.length);
    if (pending.isEmpty) return;
    final parser = FlacTagReader(readRange);
    final mp3Parser = Mp3TagReader(readRange);
    var assigned = 0;
    var completed = 0;

    Future<void> worker() async {
      while (!_closed && !(isCancelled?.call() ?? false)) {
        final index = assigned++;
        if (index >= pending.length) return;
        final track = pending[index];
        FlacTags? tags;
        Mp3Tags? id3;
        try {
          if (track.isFlac) {
            tags = await parser.parse(track.path, track.sizeBytes);
          } else if (track.isMp3) {
            id3 = await mp3Parser.parse(track.path, track.sizeBytes);
          }
        } catch (_) {
          // Corrupt/unsupported metadata retains a safe file-name fallback.
        }
        if (_closed || (isCancelled?.call() ?? false)) return;
        await catalog.saveTags(
          track.path,
          title: tags?.title ?? id3?.title ?? track.displayTitle,
          artist: tags?.artist ?? id3?.artist,
          albumArtist: tags?.albumArtist ?? id3?.albumArtist,
          album: tags?.album ?? id3?.album,
          trackNumber: tags?.trackNumber ?? id3?.trackNumber,
          discNumber: tags?.discNumber ?? id3?.discNumber,
          duration: tags?.duration ?? id3?.duration,
        );
        completed++;
        if (completed % 32 == 0 || completed == pending.length) {
          final snapshot = await catalog.readTracks();
          onProgress?.call(snapshot, completed, pending.length);
        }
      }
    }

    await Future.wait([for (var i = 0; i < 4; i++) worker()]);
  }

  void close() {
    _closed = true;
    _artworkCache.clear();
    _credentials = null;
    final catalog = _catalog;
    if (catalog != null) unawaited(catalog.close());
    _client.close();
  }
}

final cloudMusicServiceProvider = Provider<CloudMusicService>((ref) {
  final service = CloudMusicService();
  ref.onDispose(service.close);
  return service;
});

class CloudCatalogController extends AsyncNotifier<List<RemoteTrack>> {
  bool _disposed = false;
  bool _refreshing = false;

  @override
  List<RemoteTrack> build() {
    ref.onDispose(() => _disposed = true);
    // The initial empty state must be synchronous. Otherwise it can complete
    // after the first refresh starts and overwrite the imported file list.
    return const <RemoteTrack>[];
  }

  /// Keep a readable catalog visible while the remote directory is refreshed.
  /// A completed PROPFIND is the safe boundary for a durable SQLite generation.
  Future<void> refresh() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    final progress = ref.read(catalogImportProgressProvider.notifier);
    final previous = state.asData?.value ?? const <RemoteTrack>[];
    if (previous.isEmpty) state = const AsyncValue.loading();
    progress.beginListing();
    var visible = previous;
    try {
      final service = ref.read(cloudMusicServiceProvider);
      final cached = await service.readCachedCatalog();
      if (_disposed) return;
      if (cached.isNotEmpty) {
        visible = cached;
        state = AsyncValue.data(cached);
      }
      final tracks = await service.loadCatalog(
        onResponseBytes: (received) {
          if (!_disposed) progress.received(received);
        },
      );
      if (_disposed) return;
      // Filenames and sizes become playable immediately, before downloading
      // any FLAC/ID3 tags. SQLite has committed this complete listing.
      visible = tracks;
      state = AsyncValue.data(tracks);
      await _scanMetadata(service, progress);
      if (!_disposed) progress.finish();
    } catch (error, trace) {
      if (_disposed) return;
      progress.fail();
      // A network failure must not hide previously saved tracks.
      if (visible.isEmpty) state = AsyncValue.error(error, trace);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _scanMetadata(
    CloudMusicService service,
    CatalogImportProgressController progress,
  ) async {
    await service.scanMetadata(
      isCancelled: () => _disposed,
      onStarted: (total) {
        if (!_disposed) progress.beginMetadata(total);
      },
      onProgress: (tracks, done, total) {
        if (_disposed) return;
        // Each batch is persisted before publication, so interruption leaves
        // a usable catalog and the next launch resumes unindexed records.
        state = AsyncValue.data(tracks);
        progress.metadata(done, total);
      },
    );
  }
}

final cloudCatalogProvider =
    AsyncNotifierProvider<CloudCatalogController, List<RemoteTrack>>(
      CloudCatalogController.new,
    );
