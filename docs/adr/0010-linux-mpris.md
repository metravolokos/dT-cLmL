# ADR-0010: Linux MPRIS via audio_service

Date: 2026-11-06
Status: Proposed until GNOME 51 / Wayland manual acceptance

## Context

The Linux Flutter runner already plays through the existing native MediaKit
audio backend. GNOME's system player controls require an MPRIS D-Bus service.
Media buttons must manipulate the same PlaybackController, not spawn another
player or obtain an additional authenticated network session.

## Decision

Use the maintained MIT-licensed `audio_service_mpris: 0.2.1` Linux platform
adapter for the existing `audio_service: 0.18.19`. It delegates MPRIS
Play, Pause, PlayPause, Next, Previous, Stop and SetPosition to a Linux-only
AudioHandler whose callbacks bind to PlaybackController. Keep media metadata
limited to title, album, artist and duration; never publish WebDAV URLs,
authentication headers, or actual credentials on D-Bus.

The adapter and Linux AudioHandler live exclusively in `lib/platform/linux`.
The shared audio source, queue, cache and existing Android/Windows platform
adapters are unchanged. D-Bus unavailability is nonfatal to the player.

## Alternatives and limitations

- Raw `dbus` service: more code and surface for MPRIS protocol bugs.
- Unmaintained `mpris_service`: less appropriate than the supported
  audio_service platform adapter.
- MPRIS via an external binary: not acceptable for a self-contained player.

The selected plugin uses `dbus` (MPL-2.0) transitively; retain dependency
license notices in packaged distributions. Its 0.2.1 implementation does not
provide every optional MPRIS feature: Seek offsets and Seeked signals,
volume control, shuffle and rich artwork are not claimed. A functional
SetPosition implementation is required.

## Acceptance

1. Lock the dependency versions; pass Quality, Android, Windows and Linux CI.
2. On GNOME 51 Wayland, verify D-Bus service discovery, system media panel,
   transport commands, Cyrillic metadata, Stop/Disconnect cleanup and seeking.
3. Verify the player still launches without a D-Bus session and no GMS
   dependencies appear on Android.
4. Do not call MPRIS hardware-accepted on the strength of CI alone.
