# ADR-0016: Compact persistent transport controls and artist drill-down

Date: 2026-11-06
Status: Proposed until CI and physical-device acceptance

## User acceptance observation

On a real Android device the WebDAV list loaded, tracks became visible before metadata parsing finished, and unindexed tags resumed on restart (PR #40 positive device evidence). UI defects remain: the persistent mini-player uses two button rows; Stop/Repeat/Shuffle overcrowd the strip; Play icon can remain displayed while the selected track is already being played; clicking an artist expands a large list rather than opening a catalog page with album cards first and tracks below.

## Decision

Mini-player has one compact title/transport row (Play/Pause, Previous and Next), leaving repeat/shuffle/stop in full Now Playing. The seek bar remains above this single row when duration is available. Label follows requested playback intent immediately after media source opens instead of waiting solely for an asynchronous native playingStream notification. Explicit playback errors reset the state and report failure. The separate in-flight PR #36 also addresses stale stream events; review potential interactions carefully before combining.

Tap an artist to push a detail screen with a lazily built grid of available album artworks above a lazy full track list. Group albums by existing albumKey (artist/album identity), sort tracks by disc and track within each album, reuse existing playback queues; don't add WebDAV GETs during list grouping. All artist screens display filename fallbacks until metadata tags arrive; no fabricated artist or album data.

## Acceptance gates

Flutter widget tests: mini-player exposes exactly the three control buttons, Play/Pause state matches playback, and artist detail has distinct album cards and tracks. Quality+Android+Windows+Linux must pass on the exact commit. Confirm on Huawei that the row does not wrap and the toggle matches actual audio; check narrow 390 dp layout. No audio acceptance inferred from CI.
