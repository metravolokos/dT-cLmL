# ADR 0003: Native audio engines with bounded WebDAV Range streaming

Date: 2026-11-05
Status: Trial implementation; performance/device acceptance **not yet verified**

## Context and alternatives

The application must support Windows 10/11, Android without Google services and Linux GNOME 51 Wayland. Cloud Mail.ru has accepted 206 GET Range responses in bounded M0 samples, with the provider-specific Content-Range 'bytes=' dialect. Native decoders are preferable to implementing FLAC/MP3 codecs in Dart.

Considered: media_kit on all platforms; just_audio Android backed by Media3 plus just_audio_media_kit/libmpv on desktops; and custom Android Media3 + Windows Linux native player adapters. A single source of truth for queue and range transport is necessary.

## Choice for a measured vertical slice

- just_audio 0.10.6 for Android's native Media3 player.
- just_audio_media_kit 2.1.0 for Windows/Linux player backends, with media_kit_libs_windows_audio 1.0.9 and media_kit_libs_linux 1.2.1.
- StreamAudioSource serves bytes via **local HTTP loopback only**, backed by a read-only WebDAV client; the Basic Auth password is never placed into that URL.
- Each upstream GET reads <=64 KiB; body byte counts and Content-Range are checked by the WebDAV module. This supports arbitrary byte-offset seek requests. User device / Linux audio tests still pending.
- Only Android localhost cleartext traffic is enabled via network_security_config; external cleartext is disabled.
- Session and source closure are required to prevent long-lived authenticated request leaks.

## Rationale and trade-offs

just_audio is maintained and implements Media3 on Android; desktop audio depends on libmpv and licensing obligations of the distributed native codecs. StreamAudioSource is labelled experimental upstream. Its three compiler warnings are narrowly and explicitly opted into at lib/data/audio/cloud_range_audio_source.dart; this is a tracked compatibility risk, not a declaration that the API is stable. A 64 KiB chunk can incur expensive round-trip latency, so this prototype is **not yet an accepted audio cache**. The 2-track disk cache and prefetch mechanism still need implementation and measured performance. It is incorrect to claim the final gapless or start-under-three-seconds requirement has been achieved.

A native media_kit-only alternative must be compared if this bridge shows instability, and the native libmpv licensing profile verified before public binaries. The versioned dependencies were checked against pub.dev and are resolved into pubspec.lock by actual Flutter tooling.

References:
- https://pub.dev/packages/just_audio
- https://pub.dev/packages/just_audio_media_kit
- https://pub.dev/packages/media_kit_libs_windows_audio
- https://pub.dev/packages/media_kit_libs_linux
- https://pub.dev/documentation/just_audio/latest/just_audio/StreamAudioResponse-class.html
