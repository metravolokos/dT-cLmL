# teStPlaYclouDE — integrated dependency register (2026-11-06)

This is an **implemented** stack, not a candidate list. Pins are from `pubspec.yaml` on main; originally audited at `8aa1550`, refreshed after PR #34. Refer to `pubspec.lock` for resolved transitive versions. Do not update any dependency without an ADR and exact-head multi-platform CI.

| Module | Selected version | Rationale / limits |
| --- | --- | --- |
| Flutter / Dart | Flutter 3.47.9 / Dart 3.13.7 | One codebase, Material 3 Russian ARB, Windows/Android/Linux CI |
| DI / state | flutter_riverpod 3.4.3 | Testable UI/service/controller state |
| HTTP/WebDAV | dio 5.11.1 | Cancellable streamed custom PROPFIND and validated 206 Range; measured multi-transport comparison remains unresolved in Issue #6 |
| XML | xml 7.1.0 | Bounded PROPFIND multistatus parsing; check worst-case full directory size |
| Secure storage | flutter_secure_storage 11.2.0 | OS secret vault; actual runtime on devices still unverified |
| Catalog | drift 2.35.3; drift_dev 2.35.2; build_runner 2.16.1 | SQLite background isolate, generation snapshots; no FTS5/keyset/migration proof |
| Filesystem / keys | path_provider 2.1.6; path 1.9.1; crypto 3.0.8 | Per-account cache dirs and opaque hashed file keys |
| Covers | image 4.12.0 | Pure Dart worker image transform and bounded 64 MiB LRU |
| Android sound | just_audio 0.10.6, Media3 | Native platform decoder, normal OS audio route; real Huawei sound unverified |
| Windows/Linux sound | just_audio_media_kit 2.1.0, media_kit_libs_windows_audio 1.0.9, media_kit_libs_linux 1.2.1 | Native libmpv binaries; actual runtime and codec license verification pending |
| Android MediaSession | audio_service 0.18.19; audio_session 0.2.4 | Foreground service, Android controls, music focus |
| Linux OS media | audio_service_mpris 0.2.1 | D-Bus MPRIS, requires GNOME Wayland runtime check |
| Windows OS media | smtc_windows 1.1.0 | Rust-backed native SMTC and hardware media keys, runtime check pending |
| Development / lint | flutter_lints 6.0.0 | Analyze, formatter, Flutter/unit/contract tests |

Alternative transports: persistent dart:io HttpClient, package:http IOClient, Android OkHttp and Windows WinHTTP are comparison candidates in Issue #6; no new native transport should be introduced without a reproducible failure or fair short measurement. Avoid claiming library performance supremacy from historical CI.

Third-party licensing and native-codec redistribution must be reviewed independently of MIT source license. See docs/RELEASE_AND_LICENSING.md.
