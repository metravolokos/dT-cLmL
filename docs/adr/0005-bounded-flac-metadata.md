# ADR 0005: FLAC metadata via bounded remote ranges

Date: 2026-11-05
Status: Trial implementation, CI pending

Vorbis Comment and STREAMINFO metadata are parsed directly from FLAC metadata
blocks. Each HTTP range is <=64 KiB. Embedded PICTURE blocks are skipped by their
declared lengths instead of downloading the image while reading titles and tags.
Large or malformed blocks are rejected with bounded budgets. The FLAC format
requires UTF-8 Vorbis tags; album artist and disc/track number fields are
normalized without rewriting user tags. Audio content is never fetched during
this metadata step. A separate artwork reader will later fetch only cover ranges.

Alternative: use audio_metadata_reader on a temporary reconstructed file
portion; this needs proof that it tolerates partial files and large cover blocks.
A small parser avoids potentially downloading a whole FLAC track for tags.

The initial reader does not scan ID3, MP4, Opus or embedded picture data; these
are separate unfinished features. Preserve only the root /AllMusic paths.
