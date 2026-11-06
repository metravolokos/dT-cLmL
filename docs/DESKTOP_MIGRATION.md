# Desktop migration — final source snapshot record (2026-11-06)

## Repositories and source provenance
- Source (historical): [cloudmail-player-m0](https://github.com/metravolokos/cloudmail-player-m0), immutable import baseline `2d373369bfe0e7b256dd98534cc90933336e3811`.
- Desktop successor: [dT-cLmL](https://github.com/metravolokos/dT-cLmL) (Windows/Linux).
- Independent Android successor: [aN-cLmL](https://github.com/metravolokos/aN-cLmL) (not changed).
- This is an audited **source snapshot import**, not a complete Git-history import. All non-Android source files, tests, runners, Flutter package files and original Windows ICO from the pinned source are present, except desktop-specific replacements described below.
- Original PR discussions, issues, commit SHA and architecture history remain in cloudmail-player-m0. See `docs/DEVELOPMENT_HISTORY.md` and `docs/DECISION_INDEX.md`.

## Why the commit graph was not transferred
The original repository's independent [history-scanner PR #38](https://github.com/metravolokos/cloudmail-player-m0/pull/38) reported **two potential `generic-api-key` findings** in historical Git objects. This does not conclusively establish valid keys; it does prevent representing the original full history as safe to republish. The [desktop importer run](https://github.com/metravolokos/dT-cLmL/actions/runs/42224051950) also failed its secret-check gate. Never bypass this gate merely to preserve SHA history; review findings privately and rotate any genuine exposed keys. The desktop snapshot deliberately contains no original history commits.

## Snapshot comparison
All original files missing from the desktop tree are Android-specific: Android runner/build resources, Android-only media bridges, Android-only tests and Android ARM64 workflow. Desktop changes relative to source are:
- `lib/main.dart`: Windows/Linux-only startup and OS bridges
- `.github/workflows/flutter.yml`: Quality + Windows + Linux only, no Android build
- `tests/test_public_identity.py`: desktop identity validation only
- `README.md`, `AGENTS.md`, `docs/STATUS.md`, `docs/ROADMAP.md`: desktop-specific instructions
- Original Windows ICO and Runner.rc restored at identical pinned source blob SHA

## Acceptance separation
- GitHub CI proves source tests and builds, not actual audio playback or system integration.
- Windows 11 real-cloud playback, P03 reproduction, SMTC, seek, cache and packaging still need manual acceptance.
- Linux Wayland/Flatpak/Secret Service/MPRIS and audible playback still need device validation.
- Do not change stable package name `cloudmail_player` or data/credential storage identifiers without explicit migration/upgrade tests.
- No project-wide source license has been authorized. Third-party library notices remain mandatory.

## Follow-up
The one-time restore workflow was only a bootstrap helper. Remove it after source snapshot and CI are accepted. Future PRs belong exclusively in the desktop repository. Do not delete the historical source until provenance and security reviews are resolved.
