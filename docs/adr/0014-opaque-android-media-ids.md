# ADR-0014: Opaque Android system-media identifiers

Date: 2026-11-06
Status: Implemented in source; Android hardware acceptance pending

## Context and defect

The Android `mediaItemForTrack` adapter exported the remote relative WebDAV path as `MediaItem.id`. AudioService/Media3 may make that ID visible beyond the app to the operating system and media browsers. A path is not a credential, but can disclose private filenames/collection structure. The Linux MPRIS bridge already used a one-way opaque ID; there is no legitimate requirement for the Android OS to see the remote path.

## Decision

Derive a stable, opaque `track:` + SHA-256 identifier from the track's relative path, ETag and size using existing `crypto` (already pinned). Preserve title, artist, album and duration as intentionally displayed metadata. No authenticated URL, credential, raw path or remote secret is placed in the ID. Identical track identity yields the same value; changed ETag/size yields a new value. **This is pseudonymization, not encryption:** someone who already knows a filename may guess the hash. No additional network requests, OS permissions, plugins or WebDAV changes.

Alternatives: random IDs per render would cause media session instability; reusing raw path leaks it; encrypting with device key adds secret-storage complexity without a justified threat model. A keyed HMAC may be considered only if deterministic filename enumeration is demonstrated to be a problem.

## Verification and limits

Unit tests assert Cyrillic display metadata remains correct, ID stays stable, does not contain remote path, changes with ETag, and no artwork URL is synthesized. Exact-head Quality/Android/Windows/Linux CI is mandatory before merge. Real Huawei/AOSP media panels, Media3 queue selection, headset actions and login/playback remain unverified by this source-only regression.
