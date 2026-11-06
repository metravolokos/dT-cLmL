# ADR 0004: Persistent catalog using Drift SQLite

Date: 2026-11-05
Status: Trial, build verification pending

## Context
A flat /AllMusic listing contains thousands of entries. Re-fetching and rebuilding
the full catalog for every app launch is unnecessary, and remote metadata must not
be stored along with account secrets.

## Decision
Use drift 2.35.3 on native sqlite3, the official 2.35.2 generator,
build_runner 2.17.1, and path_provider 2.1.6. SQLite is opened on a background
isolate using NativeDatabase.createInBackground. Database filenames use a
truncated SHA-256 of the account name and reveal neither credentials nor email.

One canonical remote_files table stores path, size, ETag, title, artist, album and
scan generation. One Depth:1 listing commits atomically, marking additions,
changes and removals; existing tags are retained only for unchanged size/ETag.
A failed HTTP request never commits any deletion. Read-only app startup uses
the most recently indexed catalog while disconnected.

No online account secret, token or HTTP Authorization header appears in SQLite.
WAL/foreign-key and FTS5 enhancements can be added after availability tests.

## Alternatives and limitations
Raw sqlite3 with own SQL is smaller but sacrifices generated schema checking.
sqflite ffi provides different platform native adapters.
This stage does not yet include music tag extraction, schema migrations beyond
initial v1, FTS5, recursive scanning or progress checkpoints; those remain
explicitly unfinished.

References: https://drift.simonbinder.eu/platforms/vm/
https://pub.dev/packages/drift/versions/2.35.3
https://pub.dev/packages/path_provider/versions/2.1.6
