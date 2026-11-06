# teStPlaYclouDE — agent handover and engineering contract

**Read before any change:** docs/USER_SPEC_RU.md (full user intent), docs/STATUS.md (facts), docs/ROADMAP.md (next milestones), docs/PUBLIC_REPOSITORY_AUDIT.md (risk register), docs/DECISION_INDEX.md (historical ADRs), docs/RELEASE_AND_LICENSING.md.

## Source of truth and naming

- Product/display name **teStPlaYclouDE** (exact capitalization). Existing internal package/application/Flatpak identifiers remain `cloudmail_player` until a separate migration.
- User communication Russian; implementation, tests, ADRs, commits, and repository documentation English; UI strings from `lib/l10n/app_ru.arb`.
- Source in `main` is a preview, **not** authenticated real-cloud/device accepted. No fabricated performance, hardware, app-store or GitHub CI outcomes.
- Historical PRs are evidence, not current work. PR #11 consolidated earlier drafts. See docs/DEVELOPMENT_HISTORY.md. Check actual main/head and current CI before making claims.

## Project license decision (owner instruction, 2026-11-06)

- **No project-wide license has been selected or authorized.** The previously added MIT `LICENSE` was removed at the owner's request. Do not recreate it, add SPDX metadata, describe this project as MIT-licensed or make licensing decisions on the owner's behalf.
- The historical `docs/USER_SPEC_RU.md` phrase `LICENSE (предложи MIT)` means *propose*, not approval. Preserve that source specification as a historical record; this explicit owner decision supersedes it.
- Keep third-party notices, attribution and license-compliance checks for dependencies and native packages. Removing our project's LICENSE does not remove their obligations.

## Boundaries

- Only Cloud Mail.ru HTTPS WebDAV; fixed `/AllMusic`; requests read-only. Never upload, change or delete music. No redirects with Basic Auth. Each upstream ranged GET <=64 KiB, validate 206, lengths, offsets and both supported Content-Range dialects.
- Credentials only through the OS-backed secure-store UI. No credentials, private account identifiers, real remote filenames, authenticated URLs, XML dumps or user data in code, tests, issues, CI, commit messages or screenshots. Revoke any exposed credential.
- No GMS, Firebase, analytics, telemetry, playlists, favorites or EQ.
- Keep platform integrations in `lib/platform/android`, `windows`, `linux`; avoid platform-specific package imports or `Platform.is*` in domain, shared data and presentation. Keep one PlaybackController and system audio mixer.
- No mass rewrite, mock-only claim of acceptance, destructive migrations or unbounded cloud/stress tests. Do not silently change fixed constraints.

## Small-change process

1. Check current `main`, open PRs, commit history, the exact relevant files and active CI; avoid duplicate work.
2. Write a short failure hypothesis or feature acceptance gate; create a feature branch from the current main.
3. Implement one focused change, add regression test for real bug, record rationale in a new **uniquely numbered** ADR where nontrivial. The existing 0006/0007 collisions are historical; do not rename referenced ADR files.
4. Run formatter, analyzer, relevant unit/contract tests and Quality+Android+Windows+Linux CI for the **exact PR HEAD**. Add platform-specific packaging checks where applicable.
5. Merge only if all required CI jobs succeed, PR is non-draft, mergeable and HEAD SHA is unchanged; then verify merge on main. Never turn off tests to make green.
6. Distinguish CI build, sandbox smoke and physical-device/cloud acceptance. Record evidence links, scope and unknowns. Update STATUS/ROADMAP only when facts change.
7. On actual blocker, record in the audit/issue with exact reproduction, logs sanitized, ownership, next smallest action. Stop repeating failed guesses.

## Repository & developer commands

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python -m unittest discover -s tests -v
bash tools/check_layers.sh
```

`flutter build apk --debug` (Android), `flutter build windows --release` (Windows), `flutter build linux --release` (Linux). Windows also needs Rust for `smtc_windows`. No secrets in CI. Platform acceptance instructions: docs/PLATFORMS.md and docs/RELEASE_AND_LICENSING.md.

Before adding dependencies, compare maintainability, supported platforms, GMS independence and licenses; pin exact versions, update the lockfile and ADR. Avoid repeated load/endurance tests unless investigating a measured defect.

Before labeling any item complete, check docs/REQUIREMENTS_TRACEABILITY.md. Use docs/TESTING_MANUAL.md for real hardware checks; do not invent results.
