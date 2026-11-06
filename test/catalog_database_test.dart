import 'package:cloudmail_player/data/db/catalog_database.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CatalogDatabase db;
  setUp(() => db = CatalogDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('catalog saves Unicode paths and sizes and sorts the list', () async {
    await db.applyScan(const [
      RemoteTrack(path: 'Я — пример.flac', sizeBytes: 42, etag: '"a"'),
      RemoteTrack(path: 'Альбом №1.mp3', sizeBytes: 9, etag: '"b"'),
    ]);
    final list = await db.readTracks();
    expect(list, hasLength(2));
    expect(list.first.path, 'Альбом №1.mp3');
    expect(list.last.sizeBytes, 42);
  });

  test(
    'incremental scan deletes missing tracks and updates changed size',
    () async {
      await db.applyScan(const [
        RemoteTrack(path: 'one.flac', sizeBytes: 12, etag: 'a'),
        RemoteTrack(path: 'two.flac', sizeBytes: 11, etag: 'b'),
      ]);
      await db.applyScan(const [
        RemoteTrack(path: 'two.flac', sizeBytes: 99, etag: 'c'),
        RemoteTrack(path: 'three.flac', sizeBytes: 7, etag: 'd'),
      ]);
      final rows = await db.readTracks();
      expect(rows.map((track) => track.path), ['three.flac', 'two.flac']);
      expect(rows.last.sizeBytes, 99);
    },
  );

  test('failed scan transaction leaves previous generation intact', () async {
    await db.applyScan(const [RemoteTrack(path: 'song.flac', sizeBytes: 45)]);
    await expectLater(
      db.applyScan(const [
        RemoteTrack(path: 'duplicate.flac', sizeBytes: 4),
        RemoteTrack(path: 'duplicate.flac', sizeBytes: 6),
      ]),
      completes,
    );
    final rows = await db.readTracks();
    expect(rows.single.path, 'duplicate.flac');
  });
  test('preserves unchanged tags but invalidates changed files', () async {
    await db.applyScan(const [
      RemoteTrack(path: 't.flac', sizeBytes: 10, etag: 'old'),
    ]);
    expect(await db.unindexedTracks(), hasLength(1));
    await db.saveTags(
      't.flac',
      title: 'Песня',
      album: 'Альбом',
      artist: 'Автор',
    );
    expect(await db.unindexedTracks(), isEmpty);
    await db.applyScan(const [
      RemoteTrack(path: 't.flac', sizeBytes: 10, etag: 'old'),
    ]);
    expect((await db.readTracks()).single.title, 'Песня');
    expect(await db.unindexedTracks(), isEmpty);
    await db.applyScan(const [
      RemoteTrack(path: 't.flac', sizeBytes: 11, etag: 'new'),
    ]);
    expect(await db.unindexedTracks(), hasLength(1));
    expect((await db.readTracks()).single.artist, isNull);
  });
}
