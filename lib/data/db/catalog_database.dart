import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/remote_track.dart';

part 'catalog_database.g.dart';

class RemoteFiles extends Table {
  TextColumn get path => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get etag => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  BoolColumn get tagsIndexed => boolean().withDefault(const Constant(false))();
  IntColumn get generation => integer()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

@DriftDatabase(tables: [RemoteFiles])
class CatalogDatabase extends _$CatalogDatabase {
  CatalogDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<RemoteTrack>> readTracks() async {
    final rows = await select(remoteFiles).get();
    final tracks = [
      for (final row in rows)
        RemoteTrack(
          path: row.path,
          sizeBytes: row.sizeBytes,
          etag: row.etag,
          title: row.title,
          artist: row.artist,
          albumArtist: row.albumArtist,
          album: row.album,
          trackNumber: row.trackNumber,
          discNumber: row.discNumber,
          duration: row.durationMs == null
              ? null
              : Duration(milliseconds: row.durationMs!),
        ),
    ];
    tracks.sort(
      (a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()),
    );
    return tracks;
  }

  Future<List<RemoteTrack>> unindexedTracks({int limit = 50000}) async {
    final rows =
        await (select(remoteFiles)
              ..where((row) => row.tagsIndexed.equals(false))
              ..orderBy([(row) => OrderingTerm.asc(row.path)])
              ..limit(limit))
            .get();
    return [
      for (final row in rows)
        RemoteTrack(path: row.path, sizeBytes: row.sizeBytes, etag: row.etag),
    ];
  }

  /// One atomic generation prevents partial/deleted catalog states on failed
  /// server listings. Tags remain valid only for unchanged ETag and length.
  Future<void> applyScan(List<RemoteTrack> remote) async {
    final existing = {
      for (final row in await select(remoteFiles).get()) row.path: row,
    };
    final epoch = DateTime.now().microsecondsSinceEpoch;
    await transaction(() async {
      await batch((batch) {
        for (final file in remote) {
          final previous = existing[file.path];
          final sameFile =
              previous != null &&
              previous.etag == file.etag &&
              previous.sizeBytes == file.sizeBytes;
          batch.insert(
            remoteFiles,
            RemoteFilesCompanion.insert(
              path: file.path,
              sizeBytes: file.sizeBytes,
              generation: epoch,
              etag: Value(file.etag),
              title: Value(sameFile ? previous.title : file.title),
              artist: Value(sameFile ? previous.artist : file.artist),
              albumArtist: Value(
                sameFile ? previous.albumArtist : file.albumArtist,
              ),
              album: Value(sameFile ? previous.album : file.album),
              durationMs: Value(
                sameFile ? previous.durationMs : file.duration?.inMilliseconds,
              ),
              trackNumber: Value(
                sameFile ? previous.trackNumber : file.trackNumber,
              ),
              discNumber: Value(
                sameFile ? previous.discNumber : file.discNumber,
              ),
              tagsIndexed: Value(sameFile && previous.tagsIndexed),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      await (delete(
        remoteFiles,
      )..where((row) => row.generation.isNotValue(epoch))).go();
    });
  }

  Future<void> saveTags(
    String path, {
    required String title,
    String? artist,
    String? albumArtist,
    String? album,
    int? trackNumber,
    int? discNumber,
    Duration? duration,
  }) async {
    await (update(remoteFiles)..where((row) => row.path.equals(path))).write(
      RemoteFilesCompanion(
        title: Value(title),
        artist: Value(artist),
        albumArtist: Value(albumArtist),
        album: Value(album),
        trackNumber: Value(trackNumber),
        discNumber: Value(discNumber),
        durationMs: Value(duration?.inMilliseconds),
        tagsIndexed: const Value(true),
      ),
    );
  }
}

Future<CatalogDatabase> openAccountCatalog(String username) async {
  final support = await getApplicationSupportDirectory();
  final digest = sha256.convert(utf8.encode(username.toLowerCase())).toString();
  final path = p.join(support.path, 'music_${digest.substring(0, 24)}.sqlite');
  return CatalogDatabase(NativeDatabase.createInBackground(File(path)));
}
