# ADR 0001: Flutter shell, localization and state management

Date: 2026-11-05
Status: Accepted (M1 CI and manual device checks)

## Decision

One Flutter application codebase for Android (minSdk 24) and Windows. Material 3 UI with Russian ARB-generated localizations, Flutter SDK localization tools, and flutter_riverpod 3.0.3. Two Notifier providers hold navigation destination and theme. NavigationBar switches to NavigationRail at 720 logical pixels without losing selection. Theme selection is session-only for M1; persistence can be added later.

Data and domain interfaces live outside widgets. M1 provides no WebDAV transport, SQLite index or audio playback implementation. No Google Mobile Services, telemetry, analytics or Google-dependent runtime libraries are introduced.

## Version / build evidence

Flutter 3.47.9 stable, framework revision c197ca5199 and bundled Dart SDK 3.13.7 were directly confirmed by GitHub Actions run #42013267771. pubspec.yaml pins flutter_riverpod 3.0.3 and flutter_lints 6.0.0. The genuine generated pubspec.lock is committed, and CI uses flutter pub get --enforce-lockfile.

Android and Windows runners were initially assembled from official Flutter templates because Codex Cloud was blocked by its proxy. After opening the GitHub repository publicly, a GitHub Actions runner successfully executed flutter create --no-pub for both platforms, preserving the project's existing code and tests and recording generated registrant updates. A new sample test referencing MyApp created by flutter create was deliberately discarded, because project-owned widget tests already exist.

## Verified outcomes

GitHub Actions run #42013267771: flutter analyze passed with zero issues; four Flutter widget tests and six Python M0 tests passed; flutter build apk --debug and flutter build windows --release both passed and produced artifacts. The user personally confirmed that both applications launch and work on Android and Windows. This verifies the M1 shell, not cloud connection or playback.

## Consequences

One small codebase and standardized platform builds make rapid iterative UI work possible. Platform-specific services stay behind interfaces for later phases. GMS-free release auditing and future cloud/audio plugins must be checked when introduced; successful M1 compilation alone does not establish their compatibility. No multi-hour stress test is required to accept M1.
