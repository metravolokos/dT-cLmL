# ADR 0006: Wiring the temporary cache into playback

Date: 2026-11-05
Status: Implemented on Draft branch; end-to-end real-device sound verification pending

## Problem

An independently implemented two-track cache was already tested by the data
layer, but the audio player still created its just_audio StreamAudioSource
directly over CloudMusicService.readRange. The cache could not reduce GETs,
and the advertised current/next prefetch never ran in real playback.

## Decision

PlaybackController owns exactly one lazily created TwoTrackAudioCache while
a queue is active. It passes the existing CloudMusicService range-reader
with explicit cancellation to the cache; no new HTTP client or credentials
are created. On a new track it configures the cache with the selected
track and TrackQueue.nextForPrefetch(). This promotes a cached next track
and evicts history. It then gives CloudRangeAudioSource a cache-backed
reader, so standard seek, pause and play use the same bounded 64 KiB
Range contract.

A cache that cannot initialize or is unavailable never blocks playback:
the audio source falls back to the verified WebDAV range reader.
Stop/dispose close the cache. All per-request credentials remain within
CloudMusicService. This is unchanged on Android, Windows and Linux.

## Alternatives

- Whole file before play: increases first-sound latency.
- Keep network-only StreamAudioSource and independent background prefetch:
  wastes the disk copy, since the player would never read it.
- Feed local file to the engine only after full download: requires a
  second source swap, can interrupt playing and complicates seek.
- Swap out Media3 or libmpv: unwarranted by this data-layer change.

## Limitations and verification

Flutter analyze and cross-platform builds must pass before adoption.
Existing offline TwoTrackAudioCache tests check cache invariants, but
the end-to-end behavior still needs real device playback + network
counters. There is no claim of gapless playback or GNOME/Android
media session integration here.
