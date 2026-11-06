# Linux GNOME 51 Flatpak development preview

This optional GitHub Actions workflow packages the pinned Flutter Linux
release bundle as a **development-only**, x86_64 single-file Flatpak using
the GNOME 51 runtime. The artifact is retained for 14 days.

## Install

1. Download the `cloudmail-player-linux-x86_64-flatpak-preview` artifact
   from a successful **Linux GNOME 51 Flatpak preview** Actions run.
2. Install the GNOME runtime and package via:
   `flatpak install --user ./cloudmail-player-linux-x86_64.flatpak`.
3. Launch with `flatpak run com.cloudmailplayer.cloudmail_player`.
4. Enter credentials only in the application secure-store UI. Never pass
   secrets in Actions, command arguments or logs.

## Sandbox policy

Only HTTPS/WebDAV network traffic is needed externally, with Wayland,
PulseAudio/PipeWire compatibility and GPU for Flutter. Secret Service
access is scoped to `org.freedesktop.secrets`. The optional MPRIS adapter
requires owning the service derived from `cloudmail_player.mpris`; it
must still be manually tested with a real D-Bus session on GNOME 51.
No access to home directories, host files, system buses or OS-mounted
Cloud Mail.ru drives is granted.

## Limits of automated acceptance

The workflow verifies that the Flutter release bundle builds, the GNOME
runtime can package it, and the exported Flatpak has the expected binary
and ICU data in its sandbox, with no unresolved direct ELF dependencies. This is **not** a GTK/Wayland display or sound
test. In particular, verify libmpv dependency resolution, Secret Service
read/write, MPRIS Play/Pause/Next/Stop, network login and FLAC playback on
a real GNOME 51 Wayland desktop before calling the package accepted.

The GitHub Actions artifact is a preview, not a signed production Flatpak
or an approved Flathub submission. The manifest deliberately avoids
opening the full session bus or host filesystem.
