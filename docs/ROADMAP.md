# teStPlaYclouDE — remaining work (2026-11-06)

This is a prioritized engineering backlog, **not** an assertion of device acceptance. See docs/USER_SPEC_RU.md for complete acceptance criteria.

| Priority | Slice | Source status and next gate |
| --- | --- | --- |
| P0 | Physical playback of the existing integrated build | Use debug-signed Android ARM64 preview, Windows release folder, Flatpak on GNOME 51; test read-only real `/AllMusic` login/index/FLAC/MP3/play/pause/seek/next and record sanitized evidence; no redesign before observed failure |
| P0 | Safety/security verification | Check full git history for secrets with independent scanner and rotate any discovered secrets; validate build artifacts contain no real credentials; confirm redirects, 64 KiB boundaries and cache cleanup in targeted tests |
| P1 | Platform controls/device acceptance | Huawei GMS-free notification/media panel, BT/LDAC/system mixer/USB DAC/call/noisy audio; Windows 11 SMTC; Linux Wayland/MPRIS/Secret Service. Fix only reproducible defects |
| P1 | Installable distribution | Stable Android signing and update path; Windows portable ZIP or installer with runtime dependencies; Linux Flatpak signing/permissions/libmpv, dependency licenses; release checklist |
| P1 | Catalog reliability | Versioned schema migration tests; cancellation/recovery; cap memory/stream large lists; confirm large PROPFIND and 50k paging rather than merely accepting size threshold |
| P2 | Media metadata / UX scope | Assess M4A/AAC, OGG/Opus, WAV support against full spec, tag/covers and format tests; album artist grouping; persistent queue/theme if required |
| P2 | Production hardening | Clear user-facing error states, credential lifecycle, targeted crash recovery, performance/volume benchmarks; no ungated multi-hour stress tests |
| P2 | Publication operations | Verify copyrights of every contributed file and native dependency; choose/review notices for distributed binaries, release process, issue templates, supported version and vulnerability handling |

## Stage interpretation

M0/M1 engineering baseline; M2 WebDAV/index/tags; M3 library/artwork; M4 playback; M5 current+next cache; M6 queue; M7 Android/Windows/Linux media sessions; M8 robustness/scalability; M9 distribution. **Many source slices M2–M7 are merged, but none may be called fully accepted on actual target devices without evidence.** M8 and M9 remain incomplete.

Always tackle the smallest confirmed failure; keep one feature per PR, tests and CI for exact current HEAD. History is in DEVELOPMENT_HISTORY.md.

A section-by-section mapping of the full user spec, including unimplemented UI/platform/format/test requirements, is maintained in [REQUIREMENTS_TRACEABILITY.md](REQUIREMENTS_TRACEABILITY.md).
