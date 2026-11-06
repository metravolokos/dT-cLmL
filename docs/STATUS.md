# teStPlaYclouDE — evidence-based status (2026-11-06)

**Main baseline at audit start:** `8aa15507691c2ac391f05b7a00467ef98cb9b0be` (PR #30). The latest merge may be newer; always inspect GitHub before relying on this anchor.

## Implemented in main and checked by source/CI

- Flutter 3.47.9, Dart 3.13.7, Russian Material 3 UI; Android, Windows and Linux builds.
- Read-only HTTPS Cloud Mail.ru `/AllMusic`, secure OS vault, bounded Depth:1 PROPFIND, strict 206 ranges with hard 64 KiB per GET, no redirect credentials.
- Drift/SQLite per-account single-table catalog with generation-based refresh; FLAC/MP3 bounded tag parsing and filename fallback; tracks/albums/artists/search and disc/track ordering.
- FLAC embedded cover ranges, album grid, resizable 640px thumbnails, persistent 64 MiB per-account cover LRU; transient in-memory Now Playing artwork.
- just_audio/Media3 (Android), just_audio_media_kit/libmpv (Windows/Linux); single logical queue, seek, shuffle/repeat, mini-player/Now Playing; temporary current+next disk cache (512 MiB total cap), prefetch and stop/disconnect generation protections.
- Android audio_service foreground MediaSession and audio_session music focus, Windows native SMTC, Linux MPRIS; all bridge to existing controller.
- CI: Quality + Android debug + Windows release folder + Linux release bundle; optional ARM64 debug-signed Android release-mode preview and GNOME 51 Flatpak preview. Flatpak packaging tests exported executable, ICU and direct ELF dependencies in sandbox.

**Representative exact-head CI:** four jobs #42130938884 and Flatpak #42130938855 passed on PR #30 head `f4d37b8`. These are **build/source/sandbox smoke evidence**, not audio playback acceptance.

## Not yet implemented or not confirmed

- **Not shipped**: stable production-signed APK; installer/MSIX for Windows; formally release-ready, license-audited Flatpak distribution; automated release/version/signing process.
- **Implementation gaps**: persistent queue/theme state across restart; complete audio formats beyond proven FLAC/MP3 tag support; 50k keyset UI and FTS5 (current catalog loads full lists); robust DB migration history and targeted migration tests; advanced recovery/metrics and formal performance budgets.
- **Hardware/live-cloud acceptance missing**: real account login/index/seek/audio on all OSes; Android GMS-free device behavior and Huawei media panel/BT/USB DAC/headphones/calls; Windows SMTC/media keys; Linux GNOME 51 Wayland, Flatpak Secret Service/MPRIS/libmpv and audible playback.
- **Important**: absence of confirmed results is not proof of failure; equally, a successful CI build cannot be described as tested on devices.

## Non-goals

No cloud writes, playlists/favorites/EQ, GMS, telemetry or analytics. No promise of gapless playback. Remote metadata uses bounded Range, not full-media GET.

For history and superseded PRs see DEVELOPMENT_HISTORY; known audit concerns see PUBLIC_REPOSITORY_AUDIT; up-to-date decisions in DECISION_INDEX.

**Requirement-by-requirement gap register:** [REQUIREMENTS_TRACEABILITY.md](REQUIREMENTS_TRACEABILITY.md). Manual evidence form: [TESTING_MANUAL.md](TESTING_MANUAL.md). Changelog is tracked in root CHANGELOG.md.

## In-flight verification (not merged)

- Feature branch `feature/guard-controls-during-source-switch` guards pause/resume and seek during asynchronous audio-source replacement; pending CI and device playback checks. This is not accepted functionality until merged and verified.
