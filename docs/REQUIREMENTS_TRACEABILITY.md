# teStPlaYclouDE — traceability of the authoritative user specification

**Audit date:** 2026-11-06. Full requirements are in `docs/USER_SPEC_RU.md`; this register is a source-level review of main around `8aa1550` and is **not** a device/cloud acceptance report. Status: **implemented-source** = code/CI exists, **partial** = functionality missing, **unverified** = no credible live evidence, **non-goal** = expressly excluded by the user. Main source tree and PR #1–#30 were checked via GitHub; no local build or physical device was available during this audit.

| Full spec section | Implementation evidence | Status / remaining requirement |
| --- | --- | --- |
| A. Toolchains | .fvmrc Flutter 3.47.9, Windows/Android/Linux runners, GitHub Actions workflows | **Partial**: builds pass; exact distribution-specific Arch/ALT prerequisites and GNOME 51 real runtime unverified |
| B. Core state, DI, navigation | Riverpod, models and app shell in `lib/app`, `lib/domain` | **Partial**: Riverpod works; go_router ShellRoute, Freezed model generation and persistent ordinary settings not present |
| C. WebDAV transport | `lib/cloud/cloud_mail_webdav.dart`, `cloud_connection_service.dart`; PRs #11/#14 | **Implemented-source**: read-only Depth:1, 206, validation and 64 KiB GET ceiling. **Partial**: HEAD/recursion, full fairness benchmark Issue #6, robust Retry-After/backoff and rate-limit evidence, large PROPFIND capacity |
| D. SQLite index | `lib/data/db/catalog_database.dart` (Drift schema v1); PR #11 | **Partial**: account-scoped generation snapshots; no formal v1→v2 migrations, WAL/FTS5 verification, keyset 50k paging, broader normalized tables or dedicated cache index |
| E. Incremental sync | `lib/data/library/cloud_music_service.dart` four asynchronous workers | **Partial**: flat `/AllMusic` snapshot and `tagsIndexed` resume; no long-lived isolate worker; cancellation/progress/performance live acceptance pending |
| F. FLAC/MP3 tags | `lib/data/tags` and offline tests; PR #11 | **Implemented-source** for bounded FLAC/ID3 and conservative cp1251 heuristic. **Partial** for AAC/M4A/OGG/Opus/WAV metadata and rare ID3 variants; actual library tags unverified |
| G. Artwork | `flac_artwork_reader.dart`, `cover_thumbnail_cache.dart`, album grid; PRs #15/#18/#24/#28 | **Partial**: embedded FLAC, JPEG/PNG 640px thumb cache quality 85 and 64 MiB LRU; full 1200px Now Playing sizing, folder.jpg fallback, EXIF handling and platform artUrl acceptance unverified |
| H. Native playback / queue | `playback_controller.dart`, `track_queue.dart`; PRs #11/#23 | **Implemented-source**: Media3 Android and libmpv desktop, queue/shuffle/repeat/seek. **Unverified** actual sound, gapless, format-specific decoding, audio first-sound latency and queue persistence |
| I. Temporary audio cache | `two_track_cache.dart`, PR #11, cache regression tests | **Implemented-source**: current + next, up to 512 MiB combined, 64 KiB GET, part→ready, stop cleanup. **Partial**: no Drift audio-cache index and no measured 2–3s first sound / interrupted network resume |
| J. OS integrations | Android MediaSession #19, focus #26; Windows SMTC #22; Linux MPRIS #25 | **Partial**: basic play/pause/stop/next/seek bridges exist. Android 13+ notification-permission handling and power-lock device acceptance; Windows `window_manager` position/size and hotkeys; Linux MPRIS cover artUrl/desktop semantics and Wayland close policy not accepted |
| K. UI | Material 3, Russian ARB, albums/artist/tracks, responsive navigation, mini-player/Now Playing | **Partial**: current navigation threshold 720 dp vs spec below 600; no go_router ShellRoute, About/license/version screen, full cache settings, tested 50k scroll/Wayland fractional scaling |
| L. Security/settings | OS secure storage, account invalidation PRs #13/#23, Settings cloud form | **Partial**: password never in source/CI; no demonstrated Flatpak keyring persistence or non-Secret-Service fallback; theme persistence, settings store and full-history secret scan pending |
| M. Testing / CI | `flutter.yml` 4 jobs, offline Flutter/Python tests, GMS Gradle graph checks; Android/Flatpak workflows | **Partial**: no measured >=80% queue/cache/grouping coverage, integration_test/WsgiDAV on all platforms, standalone `check_no_gms` shell/PowerShell or full no-secret history gate; device tests pending. Dependabot monitoring configured in public handover |
| N. Delivery | ARM64 debug-signed release-mode APK preview, Windows release folder, GNOME 51 preview Flatpak PRs #27/#29/#30 | **Partial**: no production APK signing/update path, Windows installer/MSIX, production Flatpak provenance, native codec license clearance, formal tagged changelog release |

## Hard acceptance criteria not to infer from green CI

- Real Windows, AOSP Android (no Google services) and GNOME 51 Wayland **launch and audio**; Cloud Mail.ru read-only `/AllMusic` catalog and playback.
- 64 KiB upstream GET cap (source-enforced), no more than current/next temp audio cache; artwork maximum 1200px quality 85 where applicable.
- Shuffle/repeat for track/album/artist contexts; Android background/media buttons/screen off, Windows SMTC, GNOME MPRIS with art and controls.
- Russian cp1251 tags, Flatpak password persistence and fallback, Linux 100–200% scaling and OS media integration.
- No sensitive data in all public refs/artifacts, current dependency/source licensing, 4-platform CI, no GMS.
- Operational release signing, code provenance and test record per real device.

## Handover policy

For each line, link the next PR and the exact test/CI SHA on resolution. Change **partial → implemented-source** only after reviewing actual merged code; change **unverified → hardware accepted** only with a redacted reproducible device record. Do not turn this register into a reason for repeated six-hour stress tests. Prioritize working player and observed failures.
