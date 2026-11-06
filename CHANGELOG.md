# Changelog

Significant source changes to **teStPlaYclouDE** are tracked here. This is a development project; **there is no tagged, signed production release yet**. Format follows Keep a Changelog conventions and stable commit/PR references; past CI previews are not distribution releases.

## [Unreleased] — 2026-11-06

### Changed
- Adopt exact public product name teStPlaYclouDE in Flutter/Android/Windows/Linux/Flatpak display labels. Internal package IDs and GitHub slug intentionally remain stable for future install/data migration.
- Publish a full handover: source audit, requirements traceability, PR history, defect decisions, ADR index, security policy, contribution process and release limitations. The initially added MIT project license was removed at the owner's request; no replacement project license has been authorized.

### Security and reliability
- PR #37: use opaque MediaSession IDs to avoid publishing private cloud filenames in Android system metadata (ADR-0014).
- PR #35: guard transport controls during asynchronous track switching.
- PRs #32–#34: GitHub Actions runner/action dependency updates and Riverpod 3.4.3.

### Existing development preview milestones (before this handover)
- PR #30: verify direct ELF runtime linkage inside GNOME Flatpak sandbox.
- PR #29: GNOME 51 Flatpak packaging preview, with missing `eu-strip` fix.
- PR #28: account-scoped 64 MiB persistent 640px JPEG cover thumbnail cache.
- PR #27: ARM64 Android debug-signed APK preview.
- PRs #25–#26: Linux MPRIS and Android music focus.
- PRs #19/#22/#23/#24: Android MediaSession, Windows SMTC, stale command protections, album grid.
- PRs #12–#15/#18/#21: playback races, secure-store races, 64 KiB transport guard, bounded covers, album ordering.
- PR #11: integrated 3-platform Flutter WebDAV/SQLite/FLAC/MP3/audio-cache preview; PR #2: initial shell; PR #1: read-only M0 probe.

Full date/SHA history and unmerged prototypes: docs/DEVELOPMENT_HISTORY.md. None of these previews proves actual device playback, authenticated Cloud Mail behavior, production signing or native-codec redistribution rights.
