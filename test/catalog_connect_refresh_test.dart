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

void main() {
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
