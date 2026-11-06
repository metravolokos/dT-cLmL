# ADR 0007: Credential session invalidation

Date: 2026-11-05
Status: Draft implementation; hardware/network verification pending

## Context

The connection form stores an external application password in OS-protected
storage, but CloudMusicService caches a copy in memory for active reads.
Deleting stored credentials alone leaves the old client capable of WebDAV
requests until its provider is disposed. Changing an account can similarly
leave stale library contents on screen.

## Decision

On a verified connection change or successful Disconnect, Settings stops
the active player and temporary audio cache and then invalidates both the
CloudMusicService and CloudCatalogController Riverpod providers. This
disposes the old WebDAV client, clears in-memory credentials and resets
the visible catalog. An audio shutdown exception does not prevent
invalidation. This requires no new dependencies or cloud write operations.

## Verification and limitations

Existing widget tests cover secure-store deletion. Combined Flutter tests
and three-platform builds must pass; on-device checks must confirm that
Disconnect prevents further authenticated requests and that switching
accounts cannot reveal the previous catalog. Requests already in flight
have not yet been independently captured on the network.
