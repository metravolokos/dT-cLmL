# Codex Cloud — implement milestone M1, stop before M2

The user approved continuing development on 2026-11-05. Follow AGENTS.md, docs/SPEC.md, docs/ROADMAP.md, docs/STATUS.md and the instructions below.

## Stage 0 — repository hygiene
1. Start from fresh origin/main in a new feature branch feature/m1-flutter-scaffold. Do not continue in stale work checkout; request the same network permission that enabled git fetch during M0 if needed.
2. The M0 detailed documentation commit b48d785 was previously local-only. The current main already contains a sanitized summary. If the detailed commit remains available, compare the documents, incorporate any missing non-sensitive observations, and never force-push nor overwrite newer main.
3. Never read or use WEBDAV_USERNAME or WEBDAV_PASSWORD during M1. No external WebDAV requests or account traffic.

## Stage 1 — Flutter project generation
1. Check whether Flutter stable SDK is installed; if not, install from an official verified Flutter source when permitted. Record exact flutter --version and dart --version. Never claim a build if tooling unavailable.
2. Generate a conventional Flutter app (package name cloudmail_player) from the repository root with only android and windows platforms, e.g. flutter create --project-name cloudmail_player --platforms=android,windows --org com.cloudmailplayer ., preserving existing docs/tools/tests and refusing to overwrite user code. Verify the generated platform files. Explicitly set Android minSdk at least 24; do not add GMS dependencies.
3. Resolve and lock compatible versions. Prefer Flutter SDK Material widgets, flutter_localizations, and flutter_riverpod (verified existing version; evaluate Dart SDK compatibility; 3.4.3 currently requires Dart 3.12). Do not add plugins for audio, cloud or secure storage in M1. Record framework and dependency choices in one concise ADR.
4. Configure Flutter gen-l10n (l10n.yaml, Russian app_ru.arb, optional English scaffold); do not hardcode user-facing strings.

## Stage 2 — functioning UI shell
1. Create app entrypoint with ProviderScope and MaterialApp localized to Russian; Material 3 theme, system/light/dark switching.
2. Navigation destinations: Tracks, Albums, Artists, Settings. Android/narrow window uses NavigationBar; wide/Windows window uses NavigationRail. The same destination must remain active when resizing between layouts.
3. Empty-state screens clearly say that no library is connected and that cloud indexing will arrive in M2/M3. Do not add fictitious albums/tracks or playable controls. No favorites, playlists, equalizer or mock streaming.
4. Use light, testable state management with Riverpod; isolate future interfaces for WebDAV/storage/player without implementing them. Avoid excessive abstractions and code generation.
5. Settings screen offers theme mode selection. Display the connection capability as not yet implemented; do not ask for live password in M1. Keep window layout usable on narrow screens and Windows.
6. Add a handful of focused widget tests for switching destinations, narrow/wide layout and theme; include clear keys where useful.

## Stage 3 — verify and hand over
1. Run dart format, flutter gen-l10n, flutter analyze and flutter test. If unavailable, state exact blocked command; do not suppress errors or remove tests.
2. On Linux with a working Android SDK/JDK, run flutter build apk --debug; if SDK absent, record blocker. Windows native build requires Windows runner/VS C++ and should be represented in a separate GitHub Actions Windows job. Do not label Windows tested unless run succeeded.
3. CI: unit/analyze on Linux (with verified Flutter setup), Windows build Windows runner, Android APK build Linux runner only if SDK available. Keep workflows minimal and bounded. Retain existing M0 Python offline tests if practical.
4. Update AGENTS.md, README.md, docs/STATUS.md, docs/ROADMAP.md, docs/adr/0001-stack.md and docs/SPEC.md as needed. Update docs/screenshots only with true app screenshots, no mockups passed as real.
5. Commit code/docs, open Draft PR against main with checklist and actual test outputs. Do not merge. Stop and present PR URL, commit SHA, tested platforms, blockers and the next stage without automatically starting M2.

## Guardrails
- Never use the personal WebDAV credentials or write to /AllMusic.
- No more M0 network probing, stress testing or hours-long CI.
- Avoid early audio-engine/spike work and unnecessary dependencies.
- No platform claims based solely on generated folders: actual build success is required.
