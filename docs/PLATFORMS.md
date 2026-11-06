# teStPlaYclouDE — platform build and acceptance matrix (2026-11-06)

| Capability | Android API 24+ without GMS | Windows 10/11 x64 | Linux x86_64 GNOME 51 Wayland |
| --- | --- | --- | --- |
| UI & source build | Debug APK and release-mode ARM64 preview built in CI | Release Flutter folder built in CI | Release bundle and Flatpak built in CI |
| Read-only WebDAV and SQLite | Integrated, on-device login/index pending | Integrated, real login/index pending | Integrated, libsecret runtime pending |
| FLAC/MP3 & seek | Media3 source integrated; real audio pending | MediaKit/libmpv integrated; audio pending | MediaKit/libmpv integrated; audio pending |
| OS media integration | foreground AudioService + media buttons + music focus; Huawei panel/Bluetooth/calls pending | Windows SMTC and media keys; hardware pending | MPRIS over D-Bus; GNOME 51 Wayland and sandbox pending |
| Artwork / cache | FLAC cover, LRU thumbnails and current/next audio cache integrated | Same | Same |
| GMS-free | CI runtime dependency audit passed on supported build; AOSP/Huawei device pending | Not applicable | Not applicable |
| Distribution | ARM64 APK **ephemeral debug-signed**; no stable release signer | Full release folder artifact; no installer/MSIX accepted | GNOME 51 Flatpak preview, sandbox ELF smoke passed; no production release |

## Toolchains

- Flutter **3.47.9** and Dart **3.13.7** (see .fvmrc); install from official Flutter channels.
- Android: JDK 17, Android SDK, API 24 minimum. Use an AOSP no-Google image and an actual Huawei device for system-panel/routing acceptance. The release build currently uses debug signing.
- Windows: Visual Studio C++ desktop workload and ATL for credential plugin, plus Rust toolchain for `smtc_windows`; system playback uses normal Windows audio mixer. CI artifact is a folder, **not just the EXE**.
- Linux CI (Ubuntu): clang, cmake, ninja-build, pkg-config, libgtk-3-dev, libstdc++-12-dev, libsecret-1-dev. GNOME 51 Flatpak SDK and `elfutils` for packaging; libmpv dynamic load is not proven by `ldd` on the app executable alone.
- Arch/CachyOS target: GTK3, libsecret, native audio runtime and Flatpak/Portal availability need distribution-specific validation. ALT Linux GNOME 51 availability remains unknown; do not claim support from Ubuntu CI.

## Evidence and realistic smoke steps

- PR #30 exact-head CI #42130938884: quality, Android, Windows, Linux successful. Flatpak #42130938855: packaging, executable/ICU and direct ELF dependency smoke successful.
- Android: use docs/ANDROID_PREVIEW.md; test AOSP and Huawei without using credentials in logs. Verify playback controls, background, audio focus, unplug, speaker/BT/USB DAC, seek, stop/logout.
- Windows: extract entire CI release artifact, start via Flutter bundle, verify secure vault, FLAC/MP3, stop/seek/next/media keys and no stale SMTC.
- GNOME 51: install Flatpak from docs/LINUX_FLATPAK_PREVIEW.md; Wayland session, secret-service save/reopen, sound, MPRIS, volume/system mixer, fractional scaling and restart.
- None of the above manual device cases has an accepted result merely because CI succeeded. Record test artifact SHA, OS, reproduction and outcome in a PR or issue **without private filenames/usernames**.
