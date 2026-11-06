# Android ARM64 preview APK

The `.github/workflows/android-arm64-preview.yml` workflow builds an ARM64
APK for sideloading on an Android test device with **no Google Play Services**.
It uses the pinned Flutter SDK and dependencies, checks the release runtime
dependency graph, validates the final APK's INTERNET permission and verifies
the APK signature. The APK is retained as a GitHub Actions artifact for 14 days.

## Installation

1. In GitHub Actions, open **Android ARM64 test-installable preview** and
   choose a successful run from the main branch. Download the
   `cloudmail-player-android-arm64-debug-signed-preview` artifact ZIP.
2. Extract `app-release.apk` and install on an ARM64 test device, e.g.
   `adb install app-release.apk`. Android 7+ is the declared minimum.
3. Enter the Cloud Mail.ru app-specific password through the application's
   normal on-device secure store UI. Never supply credentials through Actions,
   source control, issue comments or release artifacts.
4. Test login, /AllMusic index, FLAC/MP3 playback, Pause/Resume, Seek,
   Next/Previous, Bluetooth/USB DAC routing, background MediaSession, and
   interruption/headphone unplug behavior.

## Important: NOT a signed production release

The current Android Gradle release build type uses an **ephemeral CI debug
keystore**, so the test APK is not a reproducibly signed, trusted, distributable
production release. Keys may differ across workflow runs and locally built
debug APKs. `adb install -r` can fail with a signature mismatch; installing
after uninstalling the previous copy wipes its private app data, including
saved credentials and its local library index. Do not uninstall without
accepting that data loss. Never upload a production signing key as source code.

A successful CI build is *not* hardware acceptance and does not prove that
WebDAV credentials, Huawei media panels, USB DAC, Bluetooth or GNOME/Windows
audio will function on real devices. Record those checks separately.
