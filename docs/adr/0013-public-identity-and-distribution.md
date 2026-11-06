# ADR-0013: Public project identity and stable application identifiers

Date: 2026-11-06
Status: Accepted for source/display rename; binary identity migration deferred

## Context

The original development used the working title CloudMail Player, GitHub slug `metravolokos/cloudmail-player-m0` and internal package/platform IDs containing `cloudmail_player`. The owner specifies the final public display name **teStPlaYclouDE**. Renaming identifiers simultaneously could break Android installation/update signatures, Windows application/cache storage, Linux Flatpak app data and automated release paths.

## Decision

Use **teStPlaYclouDE** with exact capitalization in README, contribution docs, localized app title, Android launcher label, Windows title/product metadata, Linux window title, Flatpak desktop entry and platform media presentation. Keep existing package/application IDs, executable names, flatpak id, GitHub slug, secure-storage keys and cache paths intact as compatibility-sensitive interfaces.

Use MIT for repository-owned source, with third-party dependencies and native codecs under their existing licensing terms; no production redistribution is accepted without release/legal inventory. Maintain a public security policy and source-grounded audit/history. This ADR does **not** claim that source ownership or dependency license audits are completed.

## Alternatives and consequences

- Immediate package ID/slug rename: rejected for this slice due to update/install/data-loss risk and missing GitHub repository settings rename capability in the connector.
- Keep old user-visible brand: contrary to owner's exact project name.
- Pinned stable internal IDs and new display string: minimal scope, testable and non-destructive.

Verify four-platform CI, actual packaged title/launcher, display strings, and upgrade behavior at release acceptance. Separate ADR/PR required for any future ID migration.
