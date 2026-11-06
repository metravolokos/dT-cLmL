# Desktop migration tracking — 2026-11-06

## Immutable source baseline
- Original: `metravolokos/cloudmail-player-m0` main `2d373369bfe0e7b256dd98534cc90933336e3811` (includes Windows P03 PR #53).
- Destination: `metravolokos/dT-cLmL`, staging branch `migration/desktop-snapshot-20261106`.
- Android successor: `metravolokos/aN-cLmL`; do not modify.
- **Not a full Git-history import**: GitHub connector cannot cross-reference remote Git objects; re-created snapshot commits have different SHA. Do not claim source history was preserved.

## Outstanding release blockers
1. Use Git-native fetch/push locally to transfer the source's complete commit graph, after an independent full-history secrets scan (open source PR #38). Do not force-update destination main.
2. Restore all remaining text and binary assets, especially `windows/runner/resources/app_icon.ico`, plus Windows runner C++ and all original docs/tests.
3. Remove inherited Android-only workflows/tests and Android runtime dependencies, without breaking the desktop build.
4. Validate `flutter pub get --enforce-lockfile`, analyzer, tests, Windows release bundle and Linux release bundle / Flatpak at exact PR HEAD.
5. Confirm Windows P03 error diagnosis and real playback on Windows 11; confirm real Linux playback, MPRIS, Secret Service.
6. Preserve source architectural ADRs and cross-reference source PRs/issues. Desktop-specific decisions require new ADRs.
7. Project owner has **not** approved any top-level source LICENSE. Preserve third-party notices.

## Compatibility constraints
Keep `cloudmail_player` package name, Windows executable name and existing user data/secure-store IDs until migration testing explicitly approves changes. Fixed read-only WebDAV `/AllMusic`, strict 206, <=64 KiB requests and no credential redirects are unchanged.

## Merging gate
Draft PR is intentionally incomplete. Do not mark ready or merge until the above work is accepted. GitHub Actions alone do not prove audible hardware playback.
