# ADR-0009: Windows System Media Transport Controls

Date: 2026-11-05
Status: Proposed until Windows hardware acceptance

## Context

The Flutter app uses the system audio mixer through its existing MediaKit playback backend, and manages its queue and WebDAV cache in PlaybackController. Windows media keys and the system player surface should control that same instance, not a second media pipeline.

## Decision

Integrate smtc_windows 1.1.0 (MIT, Windows-only Rust-backed Flutter plugin). Call SMTCWindows.initialize() only on Windows before runApp. Use a platform-specific ConsumerStatefulWidget to publish current track metadata, playback position and status, and to forward SMTC button events to the existing PlaybackController. Do not expose cloud credentials, Authorization headers or remote file URLs to Windows media metadata.

The Windows-only code lives under lib/platform/windows. It never imports platform packages into domain, data or presentation. Windows SMTC failures are nonfatal to audio playback.

## Tradeoffs

- This adds Rust/rustup to the Windows build toolchain; CI must verify reproducible native build before merge.
- The initial version shows text metadata and transport buttons. Album artwork integration and playback timeline fidelity must be verified on an actual Windows 11 desktop.
- The system media control must be explicitly enabled only when there is a track; it must not remain a stale entry after Stop or Disconnect.
- Media key behavior is routed through the same Flutter controller as the UI, without adding a custom audio mixer path.

## Acceptance

1. Quality, Windows, Android and Linux CI pass with locked dependencies and no layer leaks.
2. On Windows 11: play a Cloud Mail.ru FLAC/MP3, verify system player card, title, artist, duration and Play/Pause/Next/Previous/Stop hardware controls.
3. Verify Stop/Disconnect removes stale SMTC data; switching and seeking do not reopen downloaded chunks or restart an old track.
4. No claims of actual device success until manual verification.
