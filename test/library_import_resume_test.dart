import 'dart:async';

import 'package:cloudmail_player/app/app.dart';
import 'package:cloudmail_player/cloud/cloud_connection_service.dart';
import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:cloudmail_player/data/library/catalog_import_progress.dart';
import 'package:cloudmail_player/data/library/cloud_music_service.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SavedConnection implements CloudConnectionService {
  @override
  Future<SavedConnectionInfo> loadSavedConnection() async =>
      const SavedConnectionInfo(
        username: 'offline@example.invalid',
        hasCredentials: true,
      );

  @override
  Future<void> connect({
    required String username,
    required String appPassword,
    WebDavRequestCancellation? cancellation,
  }) async {}

  @override
  Future<void> disconnect() async {}
}

class _ImportService extends CloudMusicService {
  final remote = Completer<List<RemoteTrack>>();
  int remoteCalls = 0;

  @override
  Future<List<RemoteTrack>> readCachedCatalog() async => const [
    RemoteTrack(path: 'Сохранённый.flac', sizeBytes: 123),
  ];

  @override
  Future<List<RemoteTrack>> loadCatalog({
    void Function(int receivedBytes)? onResponseBytes,
  }) {
    remoteCalls++;
    onResponseBytes?.call(4096);
    return remote.future;
  }

  @override
  Future<void> scanMetadata({
    void Function(List<RemoteTrack> tracks, int done, int total)? onProgress,
    void Function(int total)? onStarted,
    bool Function()? isCancelled,
  }) async {
    onStarted?.call(2);
    onProgress?.call(
      const [
        RemoteTrack(path: 'Сохранённый.flac', sizeBytes: 123, title: 'Песня'),
        RemoteTrack(path: 'Добавленный.flac', sizeBytes: 456),
      ],
      1,
      2,
    );
  }
}

void main() {
  testWidgets('startup restores cached tracks without login and refreshes', (
    tester,
  ) async {
    final service = _ImportService();
    addTearDown(service.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudConnectionServiceProvider.overrideWithValue(_SavedConnection()),
          cloudMusicServiceProvider.overrideWithValue(service),
        ],
        child: const CloudMailApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(service.remoteCalls, 1);
    expect(find.text('Сохранённый'), findsOneWidget);
    expect(find.textContaining('4096'), findsNothing);
    expect(
      find.byKey(const ValueKey('library-import-progress')),
      findsOneWidget,
    );
    expect(find.textContaining('4 КБ'), findsOneWidget);

    service.remote.complete(const [
      RemoteTrack(path: 'Сохранённый.flac', sizeBytes: 123),
      RemoteTrack(path: 'Добавленный.flac', sizeBytes: 456),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Добавленный'), findsOneWidget);
    expect(find.textContaining('Треков в облаке: 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('library-import-progress')), findsNothing);
  });

  testWidgets('settings displays import progress during automatic refresh', (
    tester,
  ) async {
    final service = _ImportService();
    addTearDown(service.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudConnectionServiceProvider.overrideWithValue(_SavedConnection()),
          cloudMusicServiceProvider.overrideWithValue(service),
        ],
        child: const CloudMailApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Настройки').last);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('settings-import-progress')),
      findsOneWidget,
    );
    expect(find.textContaining('4 КБ'), findsOneWidget);
    service.remote.complete(const [
      RemoteTrack(path: 'Сохранённый.flac', sizeBytes: 123),
      RemoteTrack(path: 'Добавленный.flac', sizeBytes: 456),
    ]);
    await tester.pump();
    await tester.pump();
  });

  test('progress counts track metadata separately from listing bytes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(catalogImportProgressProvider.notifier);
    controller.beginListing();
    controller.received(65536);
    expect(container.read(catalogImportProgressProvider).receivedBytes, 65536);
    controller.beginMetadata(20);
    controller.metadata(8, 20);
    final progress = container.read(catalogImportProgressProvider);
    expect(progress.phase, CatalogImportPhase.metadata);
    expect(progress.done, 8);
    expect(progress.total, 20);
    controller.finish();
    expect(container.read(catalogImportProgressProvider).inProgress, false);
  });
}
