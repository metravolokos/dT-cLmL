// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_database.dart';

// ignore_for_file: type=lint
class $RemoteFilesTable extends RemoteFiles
    with TableInfo<$RemoteFilesTable, RemoteFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsIndexedMeta = const VerificationMeta(
    'tagsIndexed',
  );
  @override
  late final GeneratedColumn<bool> tagsIndexed = GeneratedColumn<bool>(
    'tags_indexed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tags_indexed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  @override
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    path,
    sizeBytes,
    etag,
    title,
    artist,
    albumArtist,
    album,
    trackNumber,
    discNumber,
    durationMs,
    tagsIndexed,
    generation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('tags_indexed')) {
      context.handle(
        _tagsIndexedMeta,
        tagsIndexed.isAcceptableOrUnknown(
          data['tags_indexed']!,
          _tagsIndexedMeta,
        ),
      );
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    } else if (isInserting) {
      context.missing(_generationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  RemoteFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteFile(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      tagsIndexed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tags_indexed'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
    );
  }

  @override
  $RemoteFilesTable createAlias(String alias) {
    return $RemoteFilesTable(attachedDatabase, alias);
  }
}

class RemoteFile extends DataClass implements Insertable<RemoteFile> {
  final String path;
  final int sizeBytes;
  final String? etag;
  final String? title;
  final String? artist;
  final String? albumArtist;
  final String? album;
  final int? trackNumber;
  final int? discNumber;
  final int? durationMs;
  final bool tagsIndexed;
  final int generation;
  const RemoteFile({
    required this.path,
    required this.sizeBytes,
    this.etag,
    this.title,
    this.artist,
    this.albumArtist,
    this.album,
    this.trackNumber,
    this.discNumber,
    this.durationMs,
    required this.tagsIndexed,
    required this.generation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['tags_indexed'] = Variable<bool>(tagsIndexed);
    map['generation'] = Variable<int>(generation);
    return map;
  }

  RemoteFilesCompanion toCompanion(bool nullToAbsent) {
    return RemoteFilesCompanion(
      path: Value(path),
      sizeBytes: Value(sizeBytes),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      tagsIndexed: Value(tagsIndexed),
      generation: Value(generation),
    );
  }

  factory RemoteFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteFile(
      path: serializer.fromJson<String>(json['path']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      etag: serializer.fromJson<String?>(json['etag']),
      title: serializer.fromJson<String?>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      album: serializer.fromJson<String?>(json['album']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      tagsIndexed: serializer.fromJson<bool>(json['tagsIndexed']),
      generation: serializer.fromJson<int>(json['generation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'etag': serializer.toJson<String?>(etag),
      'title': serializer.toJson<String?>(title),
      'artist': serializer.toJson<String?>(artist),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'album': serializer.toJson<String?>(album),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'durationMs': serializer.toJson<int?>(durationMs),
      'tagsIndexed': serializer.toJson<bool>(tagsIndexed),
      'generation': serializer.toJson<int>(generation),
    };
  }

  RemoteFile copyWith({
    String? path,
    int? sizeBytes,
    Value<String?> etag = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> artist = const Value.absent(),
    Value<String?> albumArtist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> discNumber = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    bool? tagsIndexed,
    int? generation,
  }) => RemoteFile(
    path: path ?? this.path,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    etag: etag.present ? etag.value : this.etag,
    title: title.present ? title.value : this.title,
    artist: artist.present ? artist.value : this.artist,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    album: album.present ? album.value : this.album,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    tagsIndexed: tagsIndexed ?? this.tagsIndexed,
    generation: generation ?? this.generation,
  );
  RemoteFile copyWithCompanion(RemoteFilesCompanion data) {
    return RemoteFile(
      path: data.path.present ? data.path.value : this.path,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      etag: data.etag.present ? data.etag.value : this.etag,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      album: data.album.present ? data.album.value : this.album,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      tagsIndexed: data.tagsIndexed.present
          ? data.tagsIndexed.value
          : this.tagsIndexed,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteFile(')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('etag: $etag, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('album: $album, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('durationMs: $durationMs, ')
          ..write('tagsIndexed: $tagsIndexed, ')
          ..write('generation: $generation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    path,
    sizeBytes,
    etag,
    title,
    artist,
    albumArtist,
    album,
    trackNumber,
    discNumber,
    durationMs,
    tagsIndexed,
    generation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteFile &&
          other.path == this.path &&
          other.sizeBytes == this.sizeBytes &&
          other.etag == this.etag &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.albumArtist == this.albumArtist &&
          other.album == this.album &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.durationMs == this.durationMs &&
          other.tagsIndexed == this.tagsIndexed &&
          other.generation == this.generation);
}

class RemoteFilesCompanion extends UpdateCompanion<RemoteFile> {
  final Value<String> path;
  final Value<int> sizeBytes;
  final Value<String?> etag;
  final Value<String?> title;
  final Value<String?> artist;
  final Value<String?> albumArtist;
  final Value<String?> album;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<int?> durationMs;
  final Value<bool> tagsIndexed;
  final Value<int> generation;
  final Value<int> rowid;
  const RemoteFilesCompanion({
    this.path = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.etag = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.album = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.tagsIndexed = const Value.absent(),
    this.generation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteFilesCompanion.insert({
    required String path,
    required int sizeBytes,
    this.etag = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.album = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.tagsIndexed = const Value.absent(),
    required int generation,
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       sizeBytes = Value(sizeBytes),
       generation = Value(generation);
  static Insertable<RemoteFile> custom({
    Expression<String>? path,
    Expression<int>? sizeBytes,
    Expression<String>? etag,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? albumArtist,
    Expression<String>? album,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<int>? durationMs,
    Expression<bool>? tagsIndexed,
    Expression<int>? generation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (etag != null) 'etag': etag,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (album != null) 'album': album,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (durationMs != null) 'duration_ms': durationMs,
      if (tagsIndexed != null) 'tags_indexed': tagsIndexed,
      if (generation != null) 'generation': generation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteFilesCompanion copyWith({
    Value<String>? path,
    Value<int>? sizeBytes,
    Value<String?>? etag,
    Value<String?>? title,
    Value<String?>? artist,
    Value<String?>? albumArtist,
    Value<String?>? album,
    Value<int?>? trackNumber,
    Value<int?>? discNumber,
    Value<int?>? durationMs,
    Value<bool>? tagsIndexed,
    Value<int>? generation,
    Value<int>? rowid,
  }) {
    return RemoteFilesCompanion(
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      etag: etag ?? this.etag,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtist: albumArtist ?? this.albumArtist,
      album: album ?? this.album,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      durationMs: durationMs ?? this.durationMs,
      tagsIndexed: tagsIndexed ?? this.tagsIndexed,
      generation: generation ?? this.generation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (tagsIndexed.present) {
      map['tags_indexed'] = Variable<bool>(tagsIndexed.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteFilesCompanion(')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('etag: $etag, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('album: $album, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('durationMs: $durationMs, ')
          ..write('tagsIndexed: $tagsIndexed, ')
          ..write('generation: $generation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CatalogDatabase extends GeneratedDatabase {
  _$CatalogDatabase(QueryExecutor e) : super(e);
  $CatalogDatabaseManager get managers => $CatalogDatabaseManager(this);
  late final $RemoteFilesTable remoteFiles = $RemoteFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [remoteFiles];
}

typedef $$RemoteFilesTableCreateCompanionBuilder =
    RemoteFilesCompanion Function({
      required String path,
      required int sizeBytes,
      Value<String?> etag,
      Value<String?> title,
      Value<String?> artist,
      Value<String?> albumArtist,
      Value<String?> album,
      Value<int?> trackNumber,
      Value<int?> discNumber,
      Value<int?> durationMs,
      Value<bool> tagsIndexed,
      required int generation,
      Value<int> rowid,
    });
typedef $$RemoteFilesTableUpdateCompanionBuilder =
    RemoteFilesCompanion Function({
      Value<String> path,
      Value<int> sizeBytes,
      Value<String?> etag,
      Value<String?> title,
      Value<String?> artist,
      Value<String?> albumArtist,
      Value<String?> album,
      Value<int?> trackNumber,
      Value<int?> discNumber,
      Value<int?> durationMs,
      Value<bool> tagsIndexed,
      Value<int> generation,
      Value<int> rowid,
    });

class $$RemoteFilesTableFilterComposer
    extends Composer<_$CatalogDatabase, $RemoteFilesTable> {
  $$RemoteFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tagsIndexed => $composableBuilder(
    column: $table.tagsIndexed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteFilesTableOrderingComposer
    extends Composer<_$CatalogDatabase, $RemoteFilesTable> {
  $$RemoteFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tagsIndexed => $composableBuilder(
    column: $table.tagsIndexed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteFilesTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $RemoteFilesTable> {
  $$RemoteFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tagsIndexed => $composableBuilder(
    column: $table.tagsIndexed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );
}

class $$RemoteFilesTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $RemoteFilesTable,
          RemoteFile,
          $$RemoteFilesTableFilterComposer,
          $$RemoteFilesTableOrderingComposer,
          $$RemoteFilesTableAnnotationComposer,
          $$RemoteFilesTableCreateCompanionBuilder,
          $$RemoteFilesTableUpdateCompanionBuilder,
          (
            RemoteFile,
            BaseReferences<_$CatalogDatabase, $RemoteFilesTable, RemoteFile>,
          ),
          RemoteFile,
          PrefetchHooks Function()
        > {
  $$RemoteFilesTableTableManager(_$CatalogDatabase db, $RemoteFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> tagsIndexed = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteFilesCompanion(
                path: path,
                sizeBytes: sizeBytes,
                etag: etag,
                title: title,
                artist: artist,
                albumArtist: albumArtist,
                album: album,
                trackNumber: trackNumber,
                discNumber: discNumber,
                durationMs: durationMs,
                tagsIndexed: tagsIndexed,
                generation: generation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required int sizeBytes,
                Value<String?> etag = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> tagsIndexed = const Value.absent(),
                required int generation,
                Value<int> rowid = const Value.absent(),
              }) => RemoteFilesCompanion.insert(
                path: path,
                sizeBytes: sizeBytes,
                etag: etag,
                title: title,
                artist: artist,
                albumArtist: albumArtist,
                album: album,
                trackNumber: trackNumber,
                discNumber: discNumber,
                durationMs: durationMs,
                tagsIndexed: tagsIndexed,
                generation: generation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemoteFilesTable, RemoteFile>(table),
                  BaseReferences<
                    _$CatalogDatabase,
                    $RemoteFilesTable,
                    RemoteFile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $RemoteFilesTable,
      RemoteFile,
      $$RemoteFilesTableFilterComposer,
      $$RemoteFilesTableOrderingComposer,
      $$RemoteFilesTableAnnotationComposer,
      $$RemoteFilesTableCreateCompanionBuilder,
      $$RemoteFilesTableUpdateCompanionBuilder,
      (
        RemoteFile,
        BaseReferences<_$CatalogDatabase, $RemoteFilesTable, RemoteFile>,
      ),
      RemoteFile,
      PrefetchHooks Function()
    >;

class $CatalogDatabaseManager {
  final _$CatalogDatabase _db;
  $CatalogDatabaseManager(this._db);
  $$RemoteFilesTableTableManager get remoteFiles =>
      $$RemoteFilesTableTableManager(_db, _db.remoteFiles);
}
