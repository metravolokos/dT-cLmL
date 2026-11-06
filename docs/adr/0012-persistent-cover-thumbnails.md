# ADR-0012: Bounded persistent album cover thumbnails

Date: 2026-11-06
Status: Source implementation; real Cloud Mail.ru and device acceptance pending

## Context

The album grid already reads embedded FLAC pictures using bounded HTTP 206
Range requests, but even previously seen covers must be fetched again after an
app restart. Retaining original 5 MiB pictures in UI memory and disk would be
expensive for large libraries.

## Decision

Use pinned, pure-Dart `image: 4.12.0` for image decode and JPEG encoding on a
worker isolate. Album-grid previews, not Now Playing full-size covers, are
converted to JPEG quality 85 and a maximum long edge of 640 pixels, without
upscaling. Reject unsupported formats, source payloads over 5 MiB, decoded
images exceeding 20 megapixels and generated thumbnails over 1 MiB.

Persist under the OS application cache directory, in a per-account directory.
Both directory name and individual cache filenames are SHA-256 hashes. The
source identity includes the account, WebDAV path, ETag and remote size, so
changing a file invalidates its prior thumbnail and multiple cloud accounts
do not share cached covers. Never put credentials or literal remote filenames
in cache filenames.

Keep a 64 MiB best-effort LRU per account; update last-used modification time
and delete oldest thumbnails when over budget. Concurrent requests for one
thumbnail share the same in-flight future, and all disk access remains
optional: failures display a placeholder, not a playback failure. No
additional remote endpoints or writes are involved.

## Tradeoffs and acceptance

- JPEG/PNG are supported. Unknown formats fall back to an album placeholder.
- The source reader retains its existing 64 KiB per-GET transport cap.
- This is a bounded thumbnail cache, **not** a persistent audio cache.
- Unit tests must cover resize, reuse after a new cache instance and invalid
  data without downloading from a real account.
- CI Quality, Android, Windows and Linux must all pass on the exact PR HEAD.
- A physical-device acceptance run must verify cover correctness, startup,
  SQLite/library responsiveness, cache size and eviction, and profile switching.
