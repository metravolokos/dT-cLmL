# Security policy — teStPlaYclouDE

The project is a development preview and does not yet publish a supported production release. **Do not report vulnerabilities or accidental secrets in public GitHub Issues or PRs.**

For security reports, use GitHub's **Report a vulnerability / Private vulnerability reporting** facility on the repository Security tab **if enabled**; otherwise contact the repository owner privately through a channel they publish. Do not assume a private report route is already configured. Do not attach live account credentials, remote library names, Authorization headers, full server responses, user tracks or identifiable filenames.

Relevant threat boundaries: Basic Auth restricted to `https://webdav.cloud.mail.ru/AllMusic`, disabled redirects, bounded HTTP 206 reads, OS secure storage, SQLite/cache partitioned per account, localhost-only audio streaming, and platform media metadata (which may intentionally show titles). The project must never modify remote music.

If a secret has been exposed, **revoke/rotate it first**, inspect publication/history and then remediate privately. Publicly disclose only a sanitized fix after confirming the exposure is contained.

No guarantee of vulnerability response time or production security support is currently offered. See docs/PUBLIC_REPOSITORY_AUDIT.md and docs/RELEASE_AND_LICENSING.md.
