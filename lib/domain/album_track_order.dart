import 'remote_track.dart';

/// Disc/track metadata determines album play order; filenames are the stable
/// fallback for unindexed or incompletely tagged tracks.
int compareAlbumTracks(RemoteTrack a, RemoteTrack b) {
  final disc = (a.discNumber ?? 1).compareTo(b.discNumber ?? 1);
  if (disc != 0) return disc;

  final trackA = a.trackNumber;
  final trackB = b.trackNumber;
  if (trackA != null && trackB != null) {
    final number = trackA.compareTo(trackB);
    if (number != 0) return number;
  } else if (trackA != null) {
    return -1;
  } else if (trackB != null) {
    return 1;
  }

  return a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
}
