# Public repository audit — 2026-11-06

Scope: GitHub main tree at `8aa15507691c2ac391f05b7a00467ef98cb9b0be`, history of PRs #1–#30, published CI metadata, source of key security, data and media modules, packaging and documentation. **Static review** through GitHub connector: no local Flutter build, no independent secret-scanner run, no audited binary/license inventory, no real Cloud Mail account or physical device access. Findings are bounded by that scope.

## Verified positives

- Public repository; Flutter/Dart pins, committed pubspec.lock, reproducible `--enforce-lockfile`, four-platform CI and optional Android ARM64/Flatpak builds.
- Fixed WebDAV origin/root; bounded, strict 206 reads and both Content-Range dialects; no remote-write feature in primary client; redirect following disabled; credentials stored outside Git, not fed to CI.
- Source contains unit/widget/HTTP fixture tests for connection, catalog, parser, queue, cache, artwork, platform metadata and session races. PRs #12/#13/#14/#23 added targeted regression defenses.
- Native OS media adapters stay under `lib/platform`; release-mode Android is GMS runtime-graph audited. CI artifacts are preview only.
- Existing .gitignore ignores .env, private JSON, local secrets, build output, logs and Android signing configs. `.env.example` holds placeholders, not actual credentials.
- Documentation references native code, shell commands and CI results without claiming actual playback acceptance.

## Findings and disposition

| Severity | Finding | Action / gate |
| --- | --- | --- |
| High | Previous README/STATUS/ROADMAP/PLATFORMS/TECH_STACK/AGENTS were stale and contradicted merged implementation. | Replaced with evidence-based public handoff and source/CI vs hardware distinction. |
| High | Binary legal provenance of libmpv, native codecs, transitive packages and bundled assets not fully audited; release APK uses debug signing. | Do not mark distributable production-ready; release and licensing checklist; verify notices/licenses and setup owner-controlled signing. |
| High | No independent **full Git history secret scan** completed in this audit; current tree inspection cannot prove no historical secrets. | Run Gitleaks/trufflehog locally/CI using entire history, review findings privately and rotate exposed credentials before public promotion. Never paste them into issues. |
| Medium | Current Drift schema version 1 lacks documented migration coverage; `readTracks()` loads/sorts entire catalog; no FTS5; 50k acceptance not reached. | Add schema migration tests, keyset paging and bounded benchmark before claiming scalability. |
| Medium | Selected Dio transport is an implemented design, not a measured Windows/Huawei comparison against HttpClient/OkHttp; Issue #6 remains open. | Keep choice unless real blocking defect; run only short fair tests on user devices if needed. |
| Medium | Android release signing uses debug keys, and installed debug-signed preview updates may invalidate app data. | Explicit preview warnings; production signing/update keys and reproducibility separate from source. |
| Medium | Physical GNOME 51 Wayland/Flatpak and Secret Service/MPRIS, Windows SMTC and Huawei GMS-free/Bluetooth/USB DAC not accepted. | Device matrix; no fabricated pass. |
| Medium | Full spec includes more formats and UX robustness than verified FLAC/MP3 tags; persistence of queue/theme and error recovery incomplete. | Implement per roadmap after actual functional acceptance. |
| Low | Duplicate historical ADR numbers `0006`, `0007` and old candidate-phase prose. | Decision index preserves original names and states what later PR superseded. |
| Low | Old product title in Flutter, Android, desktop packaging and docs, with internal IDs already in use. | Change *display* name to teStPlaYclouDE; keep package IDs stable pending deliberate migration. |
| Low | Issue #3 and #6 may contain outdated assignment/gates and historical context. | Preserve issue history; update only with evidence, not wholesale delete. |

## Security and privacy notes

- CloudMailWebDavClient must not log Authorization, authenticated URLs, PROPFIND response bodies or real filenames. Current code maps transport faults to error enums; future debug logging must redact by design.
- Android MediaSession previously exposed relative WebDAV path as MediaItem.id. ADR-0014 replaces it with an opaque SHA-256-derived ID and adds a privacy regression test; real Android system-surface acceptance is still pending.
- Audio temp cache contains local plaintext portions of remote files and is best-effort cleaned on stop/restart; OS temp storage is not guaranteed secure erasure. Persistent album JPEG cache remains on disk per account; deletion/privacy policy requires explicit verification.
- `CloudMusicService.loadCatalog()` and Drift `readTracks()` materialize full lists; the `unindexedTracks(limit:50000)` cap is **not** a proof of 50k scalable UX.
- Only sources reviewed here; secret/history and supply-chain scanners still required before claiming a full public security audit.

## Safe handover criteria

A new agent reads AGENTS/STATUS/ROADMAP/DECISION_INDEX/DEVELOPMENT_HISTORY first, reproduces a specific defect with a synthetic offline fixture, changes one feature branch, checks exact HEAD CI and records remaining live-device gates. Any real Cloud testing must be read-only with OS secret store; never use account credentials in Github Actions or print them into discussions.
