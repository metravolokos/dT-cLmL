# Architecture decision register and supersession map

The ADR filename is the durable citation key. **Historical collisions are preserved, not silently rewritten:** both `0006-*` and both `0007-*` exist because independent workstreams used the same number. New ADRs must use a unique number **0015+** and an unambiguous slug. Do not treat the numeric prefix alone as unique.

| Existing ADR | Decision | Current qualification |
| --- | --- | --- |
| 0001-stack | Flutter 3.47.9, Material 3, Riverpod, ARB, Android minSdk 24 | Accepted source/tooling; originally M1 Android/Windows only, later Linux |
| 0002-webdav-transport-and-secrets | Dio 5.11.1, OS secure storage, read-only DAV, 206 Range, redirect forbidden | Implemented; 64 KiB enforced later by PR #14; transport comparison Issue #6 unresolved |
| 0003-audio-vertical-slice | just_audio/Media3 Android; media_kit/libmpv desktops; localhost StreamAudioSource | Implemented preview, actual audio and binary codec licensing pending |
| 0004-sqlite-catalog | Drift SQLite background isolate; per-account catalog; atomic generation updates | Implemented schema v1; FTS5, paging and migration tests missing |
| 0005-bounded-flac-metadata | Bounded FLAC STREAMINFO/Vorbis comments; skip large embedded PICTURE | Implemented, no claim about all malformed real files |
| 0006-tag-indexing | Four parallel metadata workers, incremental tag flags | Implemented; historical text saying MP3 pending is superseded by merged PR #11 |
| 0006-playback-cache-wiring | Player reads temporary current+next cache, fallback to Range | Implemented; cache verified offline, real network still pending |
| 0007-id3-encoding | MP3 ID3/cp1251 heuristics with bounded Range | Implemented; unsupported variants fallback to filename |
| 0007-account-session-invalidation | Stop, dispose, clear catalog and credentials on Disconnect | Implemented; PRs #12, #13, #23 add related asynchronous race guards |
| 0008-android-background-media-session | audio_service custom handler, foreground MediaSession | Merged PR #19; device/EMUI acceptance pending |
| 0009-windows-smtc | smtc_windows native commands + timeline; nonfatal fallback | Merged PR #22; Windows device acceptance pending |
| 0010-linux-mpris | audio_service_mpris + bounded metadata and opaque D-Bus IDs | Merged PR #25; real GNOME acceptance pending |
| 0011-android-audio-focus | audio_session music configuration, avoid duplicate interruption handler | Merged PR #26; device acceptance pending |
| 0012-persistent-cover-thumbnails | pure Dart image isolate, 640px JPEG, 64 MiB persistent LRU | Merged PR #28; memory/performance live verification pending |
| 0013-public-identity-and-distribution | public name, stable internal IDs, publication and release/attribution boundaries | Adopted PR #31 |
| 0014-opaque-android-media-ids | Hash Android MediaSession track identity rather than expose private WebDAV filename | Merged PR #37; OS media surface hardware acceptance pending |

## Defect and corrective-decision index

| Symptom / decision | Fix and verification |
| --- | --- |
| Pending async Play/track open restarted playback after Stop | PR #12 generation/last-selection-wins guard, targeted tests; PR #23 later prevents stale Play/Seek commands |
| Delayed secure-store read recreated stale cloud session after Disconnect | PR #13 checks closed session after awaited vault reads; tests |
| Provider may reject large Range calls | PR #14 imposes **hard 64 KiB per GET at transport boundary**; preserves strict 206 validation |
| Artwork missing/slow repeated download | PRs #15/#18/#24 add bounded FLAC covers, lazy grid and playable album sheets; #28 adds persistent JPEG cache |
| Album order followed filename rather than disc/track tags | PR #21; duplicate PR #20 closed without merge |
| Windows SMTC config constructor missing required fast-forward/rewind flags; optional native startup issues | PR #22 repaired missing flags and safeguarded initialization before merge; do not confuse earlier failed CI with merged HEAD |
| Android service lifecycle assertions and wrong logical queue callbacks | PR #19 uses custom AudioHandler, compatible notification config and guarded controller bridge |
| Flatpak builder lacked `eu-strip` | PR #29 added `elfutils`; packaging #42129981370 passed |
| Flatpak binary might lack direct ELF runtime libraries despite successful build | PR #30 adds in-sandbox `ldd` smoke; #42130938855 passed, not a live Wayland/audio test |
| Android system MediaItem IDs exposed relative cloud filenames | PR #37 replaces raw filenames with stable opaque IDs; Quality/Android/Windows/Linux CI #42170135377 passed |
| Async transport controls could race audio-source switching | PR #35 merged controller guards; PR #36 proposes additional stale-event protection, pending independent CI and merge |
| Draft branch incompatibilities and duplicate work | PRs #4/#5/#7/#8/#9/#10/#17/#20 closed without merge; consolidated/corrected by #11, #18, #21 |

References: docs/DEVELOPMENT_HISTORY.md and GitHub PR/CI permalinks. Each new bug must document reproduction, failed assumption, minimal fix, regression coverage, CI head and what remains unverified.
