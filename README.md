# teStPlaYclouDE

**teStPlaYclouDE** is a Flutter audio player for a personal Cloud Mail.ru WebDAV music library. Source: read-only `https://webdav.cloud.mail.ru/AllMusic`. Targets: Windows 10/11 x64, Android API 24+ **without Google Play Services**, and Linux x86_64 / GNOME 51 Wayland.

> **Development preview, not a production release.** Four-platform CI builds pass; authenticated real-library playback, actual audio, hardware media panels, device-specific routing and distribution signing remain unaccepted. Do not confuse compilable source with hardware acceptance.

## Current features (implemented in main)

- Read-only authenticated PROPFIND and strict validated HTTP 206 Range GET, each upstream request at most **64 KiB**; fixed `/AllMusic` scope; OS-backed credential storage.
- Account-scoped Drift/SQLite catalog, incremental generation update, bounded FLAC/MP3 tag parsing, tracks/albums/artists, search, disc/track order.
- FLAC embedded artwork, responsive album grid, persistent bounded 64 MiB thumbnail cache (separate from temporary audio cache).
- Android just_audio/Media3, Windows/Linux MediaKit/libmpv, seekable Range stream, current+next temporary cache, queue, shuffle/repeat, Now Playing, mini-player.
- Android foreground MediaSession, Windows SMTC and Linux MPRIS adapters, all forwarding to the same playback controller.
- CI-built Android ARM64 **debug-signed** APK, Windows release folder and Linux GNOME 51 Flatpak **preview**.

## Getting started

Use **Flutter 3.47.9**, bundled Dart 3.13.7, JDK 17 for Android; VS C++ desktop tools and Windows Rust toolchain for Windows; GTK, libsecret, clang, cmake, ninja and pkg-config for Linux. See [platform guide](docs/PLATFORMS.md), [Android preview](docs/ANDROID_PREVIEW.md) and [Flatpak preview](docs/LINUX_FLATPAK_PREVIEW.md).

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python -m unittest discover -s tests -v
bash tools/check_layers.sh
```

Platform-specific builds: `flutter build apk --debug`, `flutter build windows --release` (on Windows), `flutter build linux --release` (on Linux). The GitHub Actions artifacts are **previews**, not verified installations or signed production releases. Credentials are entered **only in the application**, never in PRs, CI or command lines.

## For maintainers and agents

Start with [AGENTS.md](AGENTS.md), [STATUS](docs/STATUS.md), [ROADMAP](docs/ROADMAP.md), [ARCHITECTURE](docs/ARCHITECTURE.md), [DECISIONS](docs/DECISION_INDEX.md), [HISTORY](docs/DEVELOPMENT_HISTORY.md), [AUDIT](docs/PUBLIC_REPOSITORY_AUDIT.md), [SECURITY](SECURITY.md) and [CONTRIBUTING](CONTRIBUTING.md). The verbatim Russian [user acceptance specification](docs/USER_SPEC_RU.md) is authoritative for desired behavior; implementation status documents must never rewrite it retroactively.

The display/product name is **teStPlaYclouDE**. Historical repository slug `metravolokos/cloudmail-player-m0`, Dart package `cloudmail_player`, Android applicationId and Flatpak ID remain unchanged to avoid breaking existing installs, tests and artifact paths. Their future migration requires a separate tested ADR. Earlier `CloudMail Player` names in commit/PR history are historical, not a second product.

No playlists, favorites, analytics, telemetry, Google services or writes to remote audio files. Third-party trademarks and Cloud Mail.ru are not affiliated with this project.

## Licensing status

**The project owner has not selected or authorized a source-code license.** No project-wide permission to use, modify, redistribute or sublicense the project's source is granted by publication of this repository. Do not add a LICENSE file or declare an SPDX project license without the owner's explicit approval. This does not affect third-party components, which remain subject to their own licenses and applicable notices. Binary redistribution still requires a verified dependency and native-codec license inventory; see [release and licensing gates](docs/RELEASE_AND_LICENSING.md).

See also [requirements traceability](docs/REQUIREMENTS_TRACEABILITY.md), [manual acceptance checklist](docs/TESTING_MANUAL.md) and [changelog](CHANGELOG.md).
