/// Capability contracts only. M1 creates no clients or service instances.
/// Implementations and their provider bindings belong to later milestones.
abstract interface class CloudLibrarySource {
  Future<bool> isConnected();
}

abstract interface class LibraryStorage {
  Future<bool> hasIndex();
}

abstract interface class AudioPlayer {
  Future<void> stop();
}
