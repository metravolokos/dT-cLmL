# Codex assignment — M2-A only: secure Cloud Mail.ru connection

Scope: https://github.com/metravolokos/cloudmail-player-m0/issues/3

## Read first
- AGENTS.md, docs/STATUS.md, docs/ROADMAP.md, docs/webdav-notes.md and docs/SPEC.md.
- Start a fresh feature branch off **current remote main** after PR #2 merge; do not reuse stale local work checkouts.
- Keep this change small: **M2-A** only. Do not jump to SQLite, full indexing, artwork, streaming audio or M2-B/C.

## Functional requirements
1. Investigate and verify a real, maintained HTTP/WebDAV Flutter/Dart package and OS-backed secret store compatible with Windows 11 and Android **without Google Play Services**. Choose minimum dependencies; document one brief ADR.
2. Implement a read-only Cloud Mail.ru WebDAV client restricted to https://webdav.cloud.mail.ru/AllMusic and descendants, supporting Basic Auth with the **external-application password**, explicit Depth 0/1 PROPFIND and small bounded GET Range. Protect Authorization headers and personal file paths in logging.
3. Strictly validate status 207, HTTP 206, actual byte count and Content-Range including the empirically confirmed Cloud Mail.ru form \`bytes=first-last/total\`. Handle URL encoding, Cyrillic and untrusted PROPFIND hrefs, and never follow redirects to a different origin with credentials.
4. Android/Windows Settings: user enters login + app password; verify connection and show clear Russian success/failure messages. Store secrets only in actual OS secure storage; never persist plaintext passwords in SQLite, settings or logs. Provide Disconnect and remove saved credentials.
5. Use asynchronous bounded requests with cancellation/timeout; **no** full-library scan, media download, or background sync in this PR.

## Tests, artifacts and handoff
- Unit/integration tests against a local fake WebDAV server with anonymous fixtures (207, 401/403, 404, malformed XML, Unicode paths, oversized/unexpected Range, bad Content-Range, timeouts, cancellation).
- Run dart format, flutter analyze, flutter test and Python M0 tests; ensure GitHub Actions builds a Windows executable and Android debug APK. No real cloud credentials in GitHub CI.
- If live authenticated testing is performed in Codex Cloud, use only individually authorized secret environment variables and sanitized summaries. The temporary password previously exposed in chat must be replaced before reuse.
- Update STATUS, ROADMAP and the brief ADR. Submit a **Draft PR** with actual CI evidence, do not merge without user approval. Report working UI steps and defects concisely. No hours-long tests or speculative refactors.

## Important exclusions
Do not build M2-B SQLite catalog or M2-C tag scanner yet. No favorites, playlists, GMS, telemetry, ALAC or playback engine.
