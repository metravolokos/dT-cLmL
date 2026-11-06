# ADR 0006: Bounded parallel metadata indexing

Date: 2026-11-05
Status: Trial, actual Cloud Mail.ru scan pending

After the read-only WebDAV root Depth:1 listing, a SQLite generation commits
all paths/sizes/ETags atomically. Files whose size or ETag is unchanged retain
their tags. Files whose identity changes are marked for metadata parsing.

The library is immediately usable from filenames. Four independent workers
read only 64 KiB or smaller ranges for FLAC STREAMINFO and Vorbis Comment
blocks. The reader fetches the initial 8 KiB once per file and can skip
large PICTURE blocks, fetching a later metadata offset only if necessary.
The results are stored in a background-isolate Drift SQLite catalog and exposed
to the UI every 32 files. No full FLAC download or entire-file GET is issued.

The Flutter UI remains responsive during indexing, and database state survives
relaunch. Client cancellation/closing stops new work; a progress checkpoint per
file is represented by tagsIndexed, permitting resumed scans. Corrupt FLAC tags
fall back to filenames instead of failing the entire catalog.

MP3/ID3, Opus, AAC and WAV parsers, image covers, migration tests and on-device
index throughput remain pending. The configured worker count is a conservative
upper bound requiring empirical calibration under Cloud Mail.ru's rate limits.
