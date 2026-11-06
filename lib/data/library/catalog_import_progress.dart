import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Progress of one refresh. A WebDAV Depth:1 listing has no known file count
/// until its bounded XML response is received; show transferred bytes first.
enum CatalogImportPhase { idle, listing, metadata, finished, failed }

class CatalogImportProgress {
  const CatalogImportProgress({
    this.phase = CatalogImportPhase.idle,
    this.receivedBytes = 0,
    this.done = 0,
    this.total = 0,
  });

  final CatalogImportPhase phase;
  final int receivedBytes;
  final int done;
  final int total;

  bool get inProgress =>
      phase == CatalogImportPhase.listing ||
      phase == CatalogImportPhase.metadata;
  bool get failed => phase == CatalogImportPhase.failed;
}

class CatalogImportProgressController extends Notifier<CatalogImportProgress> {
  @override
  CatalogImportProgress build() => const CatalogImportProgress();

  void beginListing() =>
      state = const CatalogImportProgress(phase: CatalogImportPhase.listing);

  void received(int bytes) {
    if (state.phase != CatalogImportPhase.listing) return;
    state = CatalogImportProgress(
      phase: CatalogImportPhase.listing,
      receivedBytes: bytes,
    );
  }

  void beginMetadata(int total) => state = CatalogImportProgress(
    phase: CatalogImportPhase.metadata,
    total: total,
  );

  void metadata(int done, int total) => state = CatalogImportProgress(
    phase: CatalogImportPhase.metadata,
    done: done,
    total: total,
  );

  void finish() =>
      state = const CatalogImportProgress(phase: CatalogImportPhase.finished);

  void fail() =>
      state = const CatalogImportProgress(phase: CatalogImportPhase.failed);
}

final catalogImportProgressProvider =
    NotifierProvider<CatalogImportProgressController, CatalogImportProgress>(
      CatalogImportProgressController.new,
    );
