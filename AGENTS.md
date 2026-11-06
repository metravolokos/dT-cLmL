# dT-cLmL — desktop engineering and agent handover

This is the **Windows and Linux only** continuation of https://github.com/metravolokos/cloudmail-player-m0.
The Android-only successor is https://github.com/metravolokos/aN-cLmL. Never modify or synchronize that repository as part of desktop work.

## Sources of truth

Read `docs/DESKTOP_MIGRATION.md`, `docs/STATUS.md`, `docs/ROADMAP.md`, `docs/USER_SPEC_RU.md` (original historical cross-platform request), `docs/DECISION_INDEX.md`, `docs/DEVELOPMENT_HISTORY.md`, and `docs/RELEASE_AND_LICENSING.md` before work. Use source PR links for rationale, do not invent undocumented decisions.

The source snapshot is pinned at `2d373369bfe0e7b256dd98534cc90933336e3811` including Windows P03 diagnostics PR #53. Its historical Git commit graph was **not imported**, because a Gitleaks scan found two potential historical `generic-api-key` matches. The original repository preserves historical commits and review discussions. Do not import that history without private security review and owner approval.

## Desktop-only requirements

- Windows 11 x64 is the priority; Linux x86_64 GNOME/Wayland/Flatpak follows.
- Preserve read-only Cloud Mail.ru WebDAV `/AllMusic`, HTTPS, strict 206 responses, max 64 KiB per Range GET and disabled credential redirects.
- Preserve SQLite catalog, FLAC/MP3 metadata and artwork, bounded cover/audio caches, one playback controller, system mixer and existing identity/storage identifiers.
- Windows uses MediaKit/libmpv and SMTC; Linux uses MediaKit/libmpv, MPRIS and Secret Service. Do not reintroduce Android runners or Android media-session startup.
- Credentials belong in the OS secure store, never in Git, CI logs or test output. Production releases require third-party license audit.
- **No project-wide LICENSE has been authorized**; do not add one.

## Development procedure

1. Check exact current main, open PRs, reported defects and CI.
2. Use a focused feature branch; document why for nontrivial decisions and preserve source history links.
3. Run `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`, `python -m unittest discover -s tests -v`, and desktop layer checks.
4. Require exact-HEAD Quality + Windows release + Linux release CI. Flatpak when affected by Linux packaging.
5. Test real Windows/Linux sound and actual Cloud Mail login/index/play/pause/seek/next before marking hardware acceptance.
6. Never confuse green CI with successful live-device audio. Investigate Windows P03 using `docs/PLAYBACK_DIAGNOSTICS.md`.

The old source PRs/issues and original cross-platform spec are historical records; desktop status and roadmap override stale cross-platform action items.
