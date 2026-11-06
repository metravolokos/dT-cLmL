# teStPlaYclouDE — unresolved questions and assumptions (2026-11-06)

These are engineering gates, not reasons to stop coding or silently change the user's complete spec. Existing decisions and rationales: DECISION_INDEX.md.

| Question | Current assumption / source fact | Resolution |
| --- | --- | --- |
| Can actual Cloud Mail.ru `/AllMusic` index and playback work across all three target devices? | Only limited M0 read-only response samples and offline fixtures are published. | Perform bounded user-controlled device checks; sanitized outcomes only. |
| Is Dio the best transport on Huawei/Windows? | Implemented and CI-tested, but fair alternative benchmarks in Issue #6 unresolved. | Compare only if a reproducible problem warrants it; no speculative replacement. |
| How does 50k catalog scale? | Current single-table SQLite and `readTracks()` materialize whole lists; `unindexedTracks(limit:50000)` is not pagination. | Keyset query/FTS5/migration tests and targeted memory measurement. |
| Will Huawei media panel / Bluetooth / DAC / calls work? | Android AudioService and audio_session code exists; OEM policies uncertain. | AOSP and Huawei manual acceptance with FLAC/MP3. |
| Will GNOME 51 Flatpak run fully? | GNOME 51 Flatpak packaged, in-sandbox direct ELF check passed; no display/audio/Secret Service proof. | Real GNOME 51 Wayland, MPRIS, libmpv dynamic load and keyring verification. |
| Does ALT Linux provide GNOME 51? | Unknown; no verified ALT image/pkgs. | Check actual distro image and repositories; no assumptions. |
| Which other formats beyond FLAC/MP3 are accepted? | File extension listing includes AAC/M4A/OGG/Opus/WAV, but tag/parsing and end-to-end decoding are not accepted. | Decide via real representative format fixtures and explicit full-spec acceptance. |
| What is the permanent package signing and upgrade path? | Android release preview uses ephemeral debug key; Windows installer and production Flatpak absent. | Owner-managed signing, migration/updater plan, licenses, actual OS install checks. |
| Can the public repository claim clean history / complete licensing? | No independent all-ref secret scan and dependency/native-codec redistribution audit yet. | Run scanners privately; verify source/asset copyright, manifests and notices. |
| Should stable app IDs or GitHub slug be renamed? | Display name teStPlaYclouDE, legacy IDs preserved to prevent upgrade/data loss. | Separate ADR, signed releases/update migration, repository settings access. |
| What survives restart? | SQLite and artwork thumbnails do; audio cache temporary, queue/theme persistence not established. | Specify behavior, implement and test separately if part of acceptance. |

The 64 KiB **hard upstream Range GET** cap is not open to guessing: enforced by PR #14. No client may silently issue larger remote GET requests even though one M0 sample accepted 128 KiB. Do not run multi-hour stress suites to answer bounded questions.
