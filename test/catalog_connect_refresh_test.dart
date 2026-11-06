import 'package:cloudmail_player/app/app.dart';
import 'package:cloudmail_player/cloud/cloud_connection_service.dart';
import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:flutter/material.dart';
import 'package:cloudmail_player/data/library/cloud_music_service.dart';
import 'package:cloudmail_player/data/library/catalog_import_progress.dart';
import 'package:cloudmail_player/domain/remote_track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CatalogFixture extends CloudMusicService {
  _CatalogFixture();

  static const file = RemoteTrack(
    path: 'Test Artist - Test Album - 01.flac',
    sizeBytes: 4096,
    title: 'Первый трек',
    artist: 'Исполнитель',
    album: 'Альбом',
  );

  int listingCalls = 0;

  @override
  Future<List<RemoteTrack>> readCachedCatalog() async => const <RemoteTrack>[];

  @override
  Future<List<RemoteTrack>> loadCatalog({
    void Function(int receivedBytes)? onResponseBytes,
  }) async {
    listingCalls++;
    onResponseBytes?.call(4096);
    return const [file];
  }

  @override
  Future<void> scanMetadata({
    void Function(List<RemoteTrack> tracks, int done, int total)? onProgress,
    void Function(int total)? onStarted,
    bool Function()? isCancelled,
  }) async {
    onStarted?.call(0);
  }
}

class _LoginConnection implements CloudConnectionService {
  bool connected = false;

  @override
  Future<SavedConnectionInfo> loadSavedConnection() async =>
      SavedConnectionInfo(
        username: connected ? 'test@example.invalid' : null,
        hasCredentials: connected,
      );

  @override
  Future<void> connect({
    required String username,
    required String appPassword,
    WebDavRequestCancellation? cancellation,
  }) async {
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
  }
}

class _FirstLoginCatalog extends CloudMusicService {
  _FirstLoginCatalog(this.onListing);

  final void Function() onListing;

  @override
  Future<List<RemoteTrack>> readCachedCatalog() async =>
      const <RemoteTrack>[];

  @override
  Future<List<RemoteTrack>> loadCatalog({
    void Function(int receivedBytes)? onResponseBytes,
  }) async {
    onListing();
    return const [_CatalogFixture.file];
  }

  @override
  Future<void> scanMetadata({
    void Function(List<RemoteTrack> tracks, int done, int total)? onProgress,
    void Function(int total)? onStarted,
    bool Function()? isCancelled,
  }) async {
    onStarted?.call(0);
  }
}

void main() {
  testWidgets('first login lists tracks immediately without restarting', (
    tester,
  ) async {
    final connection = _LoginConnection();
    var listingCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudConnectionServiceProvider.overrideWithValue(connection),
          cloudMusicServiceProvider.overrideWith(
            (ref) => _FirstLoginCatalog(() => listingCalls++),
          ),
        ],
        child: const CloudMailApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Настройки').last);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('cloud-login-field')),
      'test@example.invalid',
    );
    await tester.enterText(
      find.byKey(const ValueKey('cloud-password-field')),
      'test-only-password',
    );
    await tester.tap(find.byKey(const ValueKey('connect-button')));
    await tester.pumpAndSettle();

    expect(connection.connected, isTrue);
    expect(find.byKey(const ValueKey('page-tracks')), findsOneWidget);
    expect(find.text('Первый трек'), findsOneWidget);
    expect(listingCalls, 1);
    expect(tester.takeException(), isNull);
  });


  test(
    'first refresh publishes imported tracks, even immediately after provider creation',
    () async {
      final fixture = _CatalogFixture();
      final container = ProviderContainer(
        overrides: [cloudMusicServiceProvider.overrideWithValue(fixture)],
      );
      addTearDown(container.dispose);

      final controller = container.read(cloudCatalogProvider.notifier);
      // This is precisely the call order used after successful login.
      await controller.refresh();

      final tracks = container.read(cloudCatalogProvider).asData?.value;
      expect(tracks, isNotNull);
      expect(tracks, hasLength(1));
      expect(tracks!.single.displayTitle, 'Первый трек');
      expect(fixture.listingCalls, 1);
      expect(
        container.read(catalogImportProgressProvider).phase,
        CatalogImportPhase.finished,
      );
    },
  );
}
