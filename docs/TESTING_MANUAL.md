# teStPlaYclouDE — concise device acceptance checklist

This is a **manual test plan only**. No check below is marked PASS solely by successful GitHub Actions. Use small, bounded network budgets, ordinary device playback, and no destructive operations. Never publish personal login/password/filename, remote PROPFIND XML, Authorization or debug raw tracks.

## Common acceptance, in order

1. Record git commit SHA, downloaded Actions artifact and digest, OS/device/runtime and whether real account or synthetic fixture; no private account identifiers.
2. Install the **whole** package: Android ARM64 preview (debug signed), Windows release folder or GNOME 51 Flatpak. Launch and show Russian UI and teStPlaYclouDE brand.
3. Enter Cloud Mail.ru app-specific credentials **only in OS secure-store UI**; connect to read-only `/AllMusic`, index, reconnect after restart. If connecting real account, authorize only bounded PROPFIND/Range GET. Do not alter remote files.
4. Check accurate Tracks/Albums/Artists, disc/track order, Cyrillic/legacy encoding, cover, search, progress and scroll responsiveness.
5. Play one FLAC and one MP3, seek within buffered and unbuffered parts, pause/resume, next/prev, repeat/shuffle, stop; check native OS mixer, 2-track cache behavior and no stale playback after logout.
6. Change/revoke credentials, disconnect during loading, lose/recover network. Ensure no old account metadata/source resumes; log only sanitized outcome.
7. Record reproducible defect with bounded logs, expectation vs actual, frequency and device; no general stability claim from a single track.

## Android (AOSP without Google Play Services + Huawei)

- Confirm GMS-free install and audio on speaker, BT headset and USB DAC; headset/media keys, background with screen off, foreground MediaSession, media panel card and correct metadata, lockscreen outcome (OEM dependent).
- Test audio focus with another player, call, noisy device/unplug, pause/stop/logout. Check OS battery optimization separately; do not promise OEM controls absent from system policy.
- Test reinstall/update carefully: **debug signing may change between preview builds**, and uninstall wipes private app cache and credential storage.

## Windows 11 x64

- Start from the complete zipped release folder. Verify title, metadata, 64-bit native plugins, credential persistence; Play/Pause/Next/Previous/Stop via keyboard or SMTC and correct cleanup; seek and full track re-selection cache reuse.
- Inspect dependent DLLs/license notices before distribution. Avoid publishing logs containing user paths.

## Linux GNOME 51 Wayland

- Use real Wayland GNOME 51 session (not X11 or Ubuntu CI substitute), install Flatpak from docs/LINUX_FLATPAK_PREVIEW.md, launch, dark mode, 100/125/150/200% scaling and window behavior.
- Verify complete libmpv dynamic loading, output via PipeWire/PulseAudio, Secret Service save/restart, D-Bus MPRIS Play/Pause/Next/Prev/Stop/SetPosition, metadata and art. Test absence of keyring gracefully and no host-file access.
- Inspect sandbox permission scope and licensing before production tagging.

## Results table template

| Commit/artifact | OS/device (nonidentifying) | Scenario | PASS / FAIL / NOT RUN | Evidence without secrets | Follow-up PR |
| --- | --- | --- | --- | --- | --- |
| _SHA_ | _target_ | _one scenario_ | NOT RUN | _sanitized_ | _link_ |

Attach a short targeted regression test to any repaired failure, then rerun exact-head CI. Do not claim large-library throughput, gapless playback or hardware compatibility without a measured outcome.
