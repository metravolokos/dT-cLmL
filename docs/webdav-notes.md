# Cloud Mail.ru WebDAV notes

## Evidence from authenticated Codex Cloud M0 probe — 2026-11-05

The Codex agent reported a read-only authenticated probe against the real service, using secret environment variables. Only sanitized results have been transferred to GitHub. The original detailed report was committed locally in Codex as b48d785da4a5a3d49254bdbc41e0f0ea4015eda9 but was not present on remote main at the time of this update.

- Direct system DNS resolution failed, but HTTPS over the Codex-provided proxy reached the WebDAV service.
- An unauthenticated request returned HTTP 401; an authenticated PROPFIND to /AllMusic returned HTTP 207 and confirmed the collection.
- Sampled audio resource HEAD returned 200, included ETag, and did not include Last-Modified or Accept-Ranges.
- Five bounded HTTP Range GETs all returned 206 with the expected byte counts.
- The tested Content-Range responses had the non-standard form bytes=first-last/total (with an equals sign); parsers must explicitly account for it.
- The sample included an HTTP 206 for a 128 KiB requested range. This does not establish a general server-wide maximum.
- Five Range request latencies: 584–1317 ms, median 1241 ms. Small sample only; not a playback latency benchmark.
- Six Python offline unit tests passed.
- Cloud data was not modified.

## Remaining unknowns

- Metadata/tag parsing and fallback handling; Chinese/Cyrillic/special character compatibility; full/incremental index traversal; rate limiting/concurrency.
- Range behavior across multiple file formats, errors, caching and resume/seek during actual audio playback.
- Android device and Windows playback, background audio, SMTC, secure storage and GMS-free APK verification.

## Intended provider endpoint

- WebDAV endpoint: https://webdav.cloud.mail.ru
- Required account credential: external application password, not ordinary mail password.
- Library root: /AllMusic, and no paths outside this root may be indexed or played.
- Provider docs: https://help.mail.ru/cloud/desktop/webdav/

## Experiment policy

Do not re-run remote probes as part of M1. Stage M2 should validate library index and tag extraction with focused tests. Stage M4/M5 should validate real playback and cache behavior. Treat M0's observations as limited samples rather than broad guarantees.
