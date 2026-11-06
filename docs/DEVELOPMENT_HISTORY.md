# Development history and lineage — 2026-11-05 to 2026-11-06

This is a **source-grounded chronological reconstruction** of public PRs and main commits. PR numbers are permanent GitHub URLs of the form `https://github.com/metravolokos/cloudmail-player-m0/pull/N`. Closed-unmerged drafts must not be described as merged code. All dates UTC; a PR merge proves source inclusion, never device operation.

## Initial approach and consolidation

- Initial commit `61822a5`; PR #1 merged as `aff2199`: M0 offline safe WebDAV probe and bounded authenticated observations; no remote writes.
- `bffd03e`: short M0 findings and M1 authorization. PR #2 merged `288db54`: Flutter shell, Russian UI and Android/Windows runners; user's M1 shell launch check recorded in PR.
- Independent transport comparison: PR #4 (dart:io HttpClient) and PR #5 (Dio) were closed **without merge**; Issue #6's controlled cross-platform benchmark decision gate remains open. Current code is Dio, not proof of measured transport superiority.
- PR #7 Linux/WebDAV/audio vertical slice; #8 queue; #9 SQLite/FLAC integration; #10 two-track cache were intermediate **closed-unmerged** drafts. Some changes were consolidated into PR #11, not merged individually.
- `1f977d0`: full Russian user specification committed. PR #11 merged `6f5bffc`: three-platform preview with WebDAV, SQLite, FLAC/MP3, audio queue and temporary cache. This is the first common integrated baseline.

## Targeted hardening on 2026-11-05

- PR #13 merged `da0a6e9`: invalidate cloud session after delayed secure-vault reads; logout race.
- PR #14 merged `4bc2503`: provider hard 64 KiB Range GET ceiling.
- PR #12 merged `18ec012`: stop/rapid track-switch async generation safety.
- PR #15 merged `90b96b9`: bounded embedded FLAC artwork and Now Playing, no entire track for cover.
- PR #16 merged `14ca26c`: intermediate status docs (now superseded by this audit).
- PR #18 merged `f3e7aa8`: album thumbnails; stacked PR #17 was superseded/closed.
- PR #21 merged `2d7aaae`: disc/track ordering; duplicate PR #20 was superseded/closed.
- PR #19 merged `34bf0cc`: Android AudioService foreground MediaSession and OS buttons, not yet tested on Huawei.
- PR #22 merged `5694c79`: Windows native SMTC; required config args and optional native init fixed during review.
- PR #23 merged `5a59a77`: rejects stale Play/Seek commands after Stop.
- PR #24 merged `0b4413a`: responsive album grid and playable sheet.
- PR #25 merged `92b15d3`: Linux MPRIS.
- PR #26 merged `f04edd1`: Android music audio focus.
- PR #27 merged `6a07a48`: CI-built ARM64 **debug-signed** APK preview, runtime GMS check; not production signing.

## Packaging and artwork on 2026-11-06

- PR #28 merged `da009bc`: persisted resized per-account cover thumbnails, 64 MiB LRU; isolated background encode and race fixes.
- PR #29 merged `0a0aad6`: GNOME 51 Flatpak preview and packaging/installation smoke. Initial Flatpak CI failed because `eu-strip` was absent; feature commit `657c415` added `elfutils`; [four-platform CI #42129981372](https://github.com/metravolokos/cloudmail-player-m0/actions/runs/42129981372) and [Flatpak CI #42129981370](https://github.com/metravolokos/cloudmail-player-m0/actions/runs/42129981370) passed.
- PR #30 merged `8aa1550`: direct ELF dependency resolution smoke *inside* Flatpak; [four-platform CI #42130938884](https://github.com/metravolokos/cloudmail-player-m0/actions/runs/42130938884) and [Flatpak CI #42130938855](https://github.com/metravolokos/cloudmail-player-m0/actions/runs/42130938855) passed.
- Subsequent public preparation adopts exact display name `teStPlaYclouDE`, documents handoff, fixes stale descriptions and records remaining release/hardware gates. The historical repository name is retained pending a separate repository-settings migration.

## Public maintenance and playback hardening on 2026-11-06

- PR #31 merged `111c176`: adopted the public name **teStPlaYclouDE**, refreshed README, AGENTS, STATUS, architecture, requirements/ADR traceability, security and licensing handover. Internal app IDs remain unchanged.
- PR #32 merged `e37fb21`: update `actions/setup-python` v5 → v7; PR #33 merged `c0da639`: checkout v4 → v7. Automated dependency maintenance requires exact-head CI, not blind approval.
- PR #34 merged `baf78f7`: flutter_riverpod 3.0.3 → 3.4.3, actual package pin now in `pubspec.yaml`.
- PR #35 merged `afa62ba`: guard playback transport controls during async track/source switching; this does not itself prove real-device sound or prevent every stale stream-event race.
- PR #37 merged `acf56f6`: Android MediaSession no longer exposes relative WebDAV filename through `MediaItem.id`; opaque hash derived from track identity, regression test and ADR-0014. Exact-head [Quality + Android + Windows + Linux #42170135377](https://github.com/metravolokos/cloudmail-player-m0/actions/runs/42170135377) all passed.
- PR #36 (draft when reviewed) addresses stale player-stream callbacks during track changes; its CI was red on then-current HEAD. Do not describe as integrated unless subsequently merged.
- PR #38 (draft when reviewed) adds redacted Git history scanning. First scan found two `generic-api-key`-rule candidates, **not confirmed secrets**. The workflow suppresses matched values, filenames and raw logs. Do not suppress findings or claim secret-free history without private triage.

## Lessons, negative results and reproducibility

- Several overlapping feature branches caused stale-base conflicts and duplicated work; use clean feature branches from *current* main and squash a single tested capability at a time.
- A green old-head CI is not a green rebased HEAD. Exact SHA and all required jobs must be checked before merge.
- Cross-platform compile checks caught an SMTC required-parameter failure; the Flatpak packaging smoke caught an omitted host tool. These are reproducible build defects, not proof of audio performance.
- Real Cloud Mail.ru M0 responses included `Content-Range: bytes=first-last/total`; keep compatibility and strict size checks; do not conflate isolated 128 KiB samples with production safe cap 64 KiB.
- No CI run uses a user's private credentials or modifies remote `/AllMusic`; only user-controlled hardware/network acceptance can validate actual audio and secure-store integration.
