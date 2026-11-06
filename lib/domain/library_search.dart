import 'remote_track.dart';

/// Normalizes Russian search input without network calls or locale-dependent
/// system services. Library filtering always uses the local indexed metadata.
String normalizeLibraryQuery(String value) =>
    value.trim().toLowerCase().replaceAll('ё', 'е');

bool matchesLibraryQuery(RemoteTrack track, String query) {
  final needle = normalizeLibraryQuery(query);
  if (needle.isEmpty) return true;
  return [
    track.displayTitle,
    track.displayArtist,
    track.displayAlbum,
    track.fileName,
  ].any((field) => normalizeLibraryQuery(field).contains(needle));
}
