# ADR 0007: ID3v2 and legacy cp1251 metadata via bounded ranges

Date: 2026-11-05
Status: Trial implementation; real files unverified

ID3v2.3 and ID3v2.4 text frames are read from at most 64 KiB Range GETs,
reusing one initial 16 KiB window. APIC image frames are skipped without reading
their potentially large payload during tag indexing. A safe 32 MiB metadata
offset bound prevents hostile or corrupt ID3 headers causing excessive reads.

ID3v1 is inspected at the final 128 bytes. Russian collections may label cp1251
as Latin-1, so a conservative heuristic decodes at least three high Cyrillic
bytes through a cp1251 mapping. ASCII/Western tags remain Latin-1 by default.
UTF-8 and UTF-16/BOM text are supported. Unsupported ID3 global
unsynchronization yields a filename fallback, rather than interpreting bytes
incorrectly.

A vetted third-party metadata parser remains a fallback if actual collection
samples exhibit unsupported ID3 variants or embedded cover layouts. No whole
audio GET occurs for tags. Any unknown or malformed metadata must fail safe.
