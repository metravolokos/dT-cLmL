import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/remote_track.dart';

/// Platform adapters may attach opaque metadata to a native audio source.
typedef MediaTagFactory = Object? Function(RemoteTrack track);

final mediaTagFactoryProvider = Provider<MediaTagFactory>(
  (ref) =>
      (track) => null,
);
