/// Stable metadata for an audio file beneath the fixed /AllMusic root.
class RemoteTrack {
  const RemoteTrack({
    required this.path,
    required this.sizeBytes,
    this.etag,
    this.title,
    this.artist,
    this.albumArtist,
    this.album,
    this.trackNumber,
    this.discNumber,
    this.duration,
  });

  final String path;
  final int sizeBytes;
  final String? etag;
  final String? title;
  final String? artist;
  final String? albumArtist;
  final String? album;
  final int? trackNumber;
  final int? discNumber;
  final Duration? duration;

  String get fileName => path.split('/').last;

  String get displayTitle {
    final name = title?.trim();
    if (name != null && name.isNotEmpty) return name;
    final fallback = fileName;
    final dot = fallback.lastIndexOf('.');
    return dot > 0 ? fallback.substring(0, dot) : fallback;
  }

  String get displayArtist => (artist?.trim().isNotEmpty ?? false)
      ? artist!.trim()
      : (albumArtist?.trim().isNotEmpty ?? false)
      ? albumArtist!.trim()
      : 'Неизвестный исполнитель';

  String get displayAlbum =>
      (album?.trim().isNotEmpty ?? false) ? album!.trim() : 'Без альбома';

  /// Albums with the same title but different artists are distinct.
  String get albumKey => '${albumArtist ?? artist ?? ''}\u0000$displayAlbum';

  bool get isFlac => fileName.toLowerCase().endsWith('.flac');
  bool get isMp3 => fileName.toLowerCase().endsWith('.mp3');
}
