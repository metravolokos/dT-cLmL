# Contributing to teStPlaYclouDE

This repository is public and accepts carefully scoped reviewable contributions. It is a private-library client: **never submit your music, usernames, app passwords or cloud API responses**, even as test fixtures. Read docs/USER_SPEC_RU.md, AGENTS.md, docs/STATUS.md, docs/DECISION_INDEX.md and docs/PUBLIC_REPOSITORY_AUDIT.md before proposing changes.

## Workflow

1. Open a focused issue (redacted) for a reproducible bug, or link the relevant spec requirement; confirm no equivalent work is merged or in PRs.
2. Branch from latest `main`, change one feature, add a minimal offline regression test and an ADR (0013+ unique number) for nontrivial dependencies/security/architecture changes.
3. Use English source/comments/docs/commits; Russian UI text via `lib/l10n/app_ru.arb`. Keep public product capitalization `teStPlaYclouDE`.
4. Locally run pinned Flutter 3.47.9 `flutter pub get --enforce-lockfile`, `flutter gen-l10n`, Dart format, `flutter analyze`, `flutter test`, Python fixture tests, and `tools/check_layers`. The CI checks Android+Windows+Linux; special Flatpak/ARM64 tests when affected.
5. Include reproduction, changes, screenshots only with synthetic data, tests and exact CI URLs, plus **what was not tested on real hardware**. Do not merge Draft, conflicting or non-green PRs.
6. Preserve historical documentation and avoid force pushing over another agent's work. Do not alter cloud files, leak credentials, add telemetry/GMS, or change package IDs/signing without a migration plan.

There are no guarantees of review SLA. Third-party source/assets must have compatible licenses and correct attribution. See SECURITY.md for private disclosure.
