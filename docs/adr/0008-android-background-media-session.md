# ADR-0008: Android foreground MediaSession for Cloud Range playback

Date: 2026-11-05
Status: Proposed, pending device acceptance

## Context

Flutter UI and just_audio already stream encrypted authenticated WebDAV audio using bounded 64 KiB Range GETs. The Android app must continue playing while backgrounded and expose a true system media session with playback metadata and controls in the Android/EMUI media panel, rather than an ordinary unrelated notification. Bluetooth headset buttons and pause/resume/next/previous are required. The user prohibits GMS and wants normal system audio routing.

## Decision

Use audio_service 0.18.19 with a custom BaseAudioHandler. Unlike the simple just_audio_background adapter, the custom handler dispatches Play, Pause, Stop, Seek, Next and Previous to the existing PlaybackController, so the Android system notification can expose the actual application queue even though the native just_audio engine currently loads one stream at a time.

The foreground service stays active during Pause using `androidStopForegroundOnPause: false`. `androidNotificationOngoing` remains false because `audio_service` forbids an ongoing notification combined with a non-stopping foreground service; this setting requires hardware/EMUI verification for notification retention.

The Android activity extends AudioServiceActivity. The manifest declares WAKE_LOCK, foreground mediaPlayback permissions, AudioService and a media button receiver. Initialize the handler before constructing the Flutter app. A platform-only Riverpod bridge forwards playback state and media metadata to the handler and installs guarded callbacks; no second decoder, WebDAV client or audio player is created.

Only code in lib/platform/android imports audio_service. A platform-injected MediaTagFactory creates MediaItem metadata (opaque SHA-256-based ID, album, artist, title and duration), never Basic Auth, app passwords, relative WebDAV filenames as IDs, authenticated URLs or redirect targets. See ADR-0014 for the privacy hardening. Windows/Linux continue using their existing audio backends.

## Alternatives

- Direct Kotlin Media3 MediaSessionService plus a bidirectional Flutter channel: more native control, but duplicates playback command dispatch, lifecycle state and queue; defer unless the audio_service handler proves inadequate.
- A generic persistent notification alone: rejected because the user explicitly requires system media controls.
- just_audio_background for the single player: simpler but its system Next/Previous buttons are enabled from the just_audio source sequence; our logical queue lives in PlaybackController and is not a native playlist, so it cannot show the full required controls reliably.

## Validation gates

1. CI: Flutter analyzer, widget/unit tests, layer checker, Android debug APK, Windows release and Linux release.
2. Static Android manifest check for foreground mediaPlayback service, receiver and permission; Android GMS dependency audit.
3. AOSP Android runtime: media panel appears as a media session, correct track title, play/pause/seek/next/previous, headphone buttons, background and screen-off playback.
4. Huawei EMUI runtime: Bluetooth audio and media panel checked on the user device. Lock-screen visibility may depend on OEM policies and cannot be promised from source code.
5. Disconnect stops playback and invalidates credentials; no authenticated requests after logout.

This ADR describes planned integration and acceptance criteria; green CI alone does not establish a passing device or EMUI result.
