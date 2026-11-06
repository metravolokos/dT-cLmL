# ADR-0011: Android audio focus and music attributes

Date: 2026-11-06
Status: Source implementation; hardware acceptance pending

## Context

The Android player uses Media3 through just_audio, with audio_service for
foreground MediaSession and hardware buttons. Correct system-level media
audio attributes and audio focus are needed when another app plays sound,
a call begins, or Bluetooth/wired headphones disconnect.

## Decision

Declare audio_session 0.2.4 as a direct, pinned dependency (already resolved
transitively through just_audio). Configure
AudioSessionConfiguration.music() after the Android MediaSession and native
audio backend have been initialized, but before the app and player start.
The platform call lives only in lib/platform/android.

Keep just_audio's default audio interruption handling enabled. Do not add a
second interruption/noisy-device listener: duplicate independent listeners
could pause/resume the same player twice or unintentionally restart audio.
Use the platform's normal Android system mixer; do not force a codec, Bluetooth
route, or a custom audio output.

The audio-session configuration channel is optional for app startup. If it
fails on an unusual device, retain the plugin defaults and allow the player
to start. Unit tests check requested media usage, music content type and
long-lived audio-focus gain.

## Acceptance

- Quality, Android, Windows and Linux CI with all pinned dependencies.
- Android AOSP emulator without GMS: audio focus handoff with another
  playback app, incoming call interruption, wired-headphone unplug and
  stop/foreground-service state.
- Huawei physical device: confirm speaker, Bluetooth headset, USB DAC and
  notification/media panel behavior, without claiming system lockscreen
  integration when the OS blocks third-party players.
- No claim of hardware compatibility on CI alone.
