# Codex Cloud assignment — M0 only

1. Read AGENTS.md, README.md, docs/STATUS.md, docs/webdav-notes.md and tools/webdav_probe.py.
2. Run python -m unittest discover -s tests -v; report results.
3. Check whether webdav.cloud.mail.ru resolves and HTTPS connectivity works. Do not display credentials or full URL paths containing private filenames.
4. If the two Codex Personal environment variables WEBDAV_USERNAME and WEBDAV_PASSWORD are present, run:
   python tools/webdav_probe.py --live --output m0-results.private.json
   Do not enable shell tracing, print secrets, persist .env, or upload the private JSON result.
5. Summarize verified HTTP statuses, Range and Content-Range behavior, ETag/Last-Modified availability, and bounded request latency. Distinguish provider facts from assumptions; a bounded sample is not a full scan or playback benchmark.
6. If blocked, identify the *category* (DNS/network, missing environment variable, HTTP 401/403, provider response, or code problem), without leaking credentials. Fix only a concrete probe defect if necessary and add a regression test.
7. Update docs/webdav-notes.md and docs/STATUS.md with dated findings and remaining unknowns. Ensure no private JSON or secret file is added to Git. Commit documentation changes, then STOP. Do not start M1 or install Flutter/Android SDK.

This probe is read-only. Never send PUT, POST, DELETE, MOVE, COPY, MKCOL or PROPPATCH.
