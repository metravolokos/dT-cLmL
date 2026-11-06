# dT-cLmL — desktop engineering status (2026-11-06)

## Implemented and source-preserved
Windows/Linux Flutter application, Cloud Mail.ru read-only `/AllMusic` WebDAV, fixed 64 KiB strict Range GETs, OS secure-store credentials, SQLite catalog, FLAC/MP3 tags, album covers and thumbnail LRU, current+next cache, audio playback controller, track queue, mini-player and Now Playing. Windows SMTC and Linux MPRIS are integrated. Original Windows icon restored. This snapshot includes Windows P03 diagnostic changes from source PR #53.

The original commit graph remains in cloudmail-player-m0 because full-history Gitleaks detected two potential historical generic API keys. `docs/DESKTOP_MIGRATION.md` explains the migration provenance and scope.

## Evidence and limitations
Previous exact-HEAD desktop CI (Quality/Windows/Linux), Python tests and Flatpak preview passed on commit `d008e27`. **That proof does not apply automatically to later commits.** Re-run checks on the final migration HEAD before merge.
Real-cloud and hardware playback are NOT accepted. Windows P03 still needs real-device diagnostics; Linux sound, MPRIS, secure-store and Flatpak need manual tests. Bundles are previews, not signed installers or licensed production releases.

## Work priorities
1. Merge source-only desktop migration after exact-head CI and file provenance checks.
2. Diagnose Windows P03 in actual build and reproduce/resolve audible playback.
3. Confirm Windows 11 catalog/SMTC/seek/cache; confirm Linux audio, MPRIS/Wayland/Secret Service.
4. Produce working portable Windows ZIP and Linux Flatpak with full native dependencies and notices.
5. Improve desktop UI/search and catalog scaling from observed defects, without speculative rewrites.

No Android builds, no cloud writes, no unauthorized project-wide LICENSE.
