# ADR: Ignore transport controls while replacing an audio source

Date: 2026-11-06

## Context

`PlaybackController._open` updates the selected track before the asynchronous `setAudioSource` finishes. During that interval, the player may still hold the previous audio source. `pauseOrResume` or `seek` would otherwise act on that stale source, contrary to the track displayed in the UI.

## Decision

Ignore pause/resume and seek requests while `_changingTrack` is true. The next valid request after source replacement acts on the newly selected track. Do not queue transport commands, since an old seek should never be replayed against another track.

## Consequences and verification

This avoids wrong-track seeks and accidental old-track resumes, at the cost of ignoring commands during a short loading window. CI and device verification are required; source-level reasoning alone is not playback acceptance. No WebDAV writes or new dependencies.
