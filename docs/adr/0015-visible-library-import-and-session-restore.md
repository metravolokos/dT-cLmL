# ADR-0015: Visible catalog import and automatic saved-session restore

Date: 2026-11-06
Status: Source implementation; physical Windows/Android acceptance pending

## Reproduction and root cause

Windows 11 manual observation: entering the account works, but the library screen gives no useful import progress, and after several minutes interrupted import shows no playable tracks. On restart the user must manually reconnect. Code review showed: AppShell never invokes a catalog refresh for already-saved credentials; the Settings flow saves credentials but never starts loading the library; CloudCatalogController resets AsyncValue to loading and hides existing tracks during re-index; WebDAV listing only returns a fully parsed XML list with no observable transfer progress; FLAC/MP3 tag scan callbacks were not published as UI progress.

## Decision

At startup, inspect only the OS protected credential vault (never place password in source, logs or app state) and automatically open the previously persisted SQLite catalog and refresh the read-only WebDAV listing. On verified login, automatically start refresh without an extra button. During refresh keep old tracks on screen. Stream bounded PROPFIND response *byte counts* into a visible indeterminate progress banner; once the complete Depth:1 listing is received and atomically persisted, immediately show its filename-based tracks before any FLAC/ID3 tag reads. Publish metadata progress as processed / total, refresh visible titles after every 32 indexed tracks (avoiding excessive full-catalog reads), and retain committed entries after failure. On next launch resume the remaining unindexed tags via the database.

## Scope and explicit limitations

WebDAV XML is still parsed and committed as one Depth:1 response: the number of files is unknown until the full response arrives. The progress banner can show received bytes **during listing**, but cannot claim an exact file count or percentage yet. For long directories a bounded streaming XML/index pipeline may be needed after measuring the real response size and latency. No new network endpoints, cloud writes or unbounded Range GET. Never delete the known catalog on failed PROPFIND.

## Acceptance

- Offline test of startup with pre-saved credentials shows cached filenames immediately and begins background refresh without manual login; test validates new tracks appear while metadata finishes.
- Test validates byte progress and separate indexed tag counts.
- Quality + Android + Windows + Linux CI green on exact HEAD; manual Windows 11 test using the same artifact validates visible progress, stored login, streaming FLAC/MP3 and clean restart.
- Do not infer physical acceptance from CI or a synthetic fake server.
