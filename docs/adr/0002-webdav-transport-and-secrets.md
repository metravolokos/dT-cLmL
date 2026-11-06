# ADR 0002: Read-only WebDAV transport and OS-backed credentials

Date: 2026-11-05
Status: Accepted for M2-A

## Decision

- Use Dio 5.11.1 for custom PROPFIND and GET requests. It supports connection,
  send and receive timeouts, per-request cancellation, and disabled redirects on
  Android and Windows without native network plugins.
- Use `xml` 7.1.0 for namespace-agnostic DAV multistatus parsing. Reject DTD and
  entity declarations, cap XML at 1 MiB, and validate every response href against
  the requested path under `/AllMusic`.
- Use `flutter_secure_storage` 11.2.0. Its Android implementation encrypts with
  Android Keystore-backed RSA-OAEP/AES-GCM; its Windows implementation keeps an
  AES-GCM key in Windows Credential Manager and encrypted values in the app's
  support directory. Both platforms are supported by this package version.
- The Android plugin depends on `com.google.crypto.tink:tink-android` for
  cryptography. Tink is not Google Play Services. CI checks the resolved Android
  runtime graph for `com.google.android.gms` and Firebase dependencies.
- Send credentials only to the fixed HTTPS Cloud Mail.ru origin. Never follow a
  redirect, and do not include URLs, response XML, credentials or file names in
  application errors or logs. Requests are read-only PROPFIND and GET.
- Limit each Range response to 64 KiB and validate HTTP 206, exact byte count,
  requested offsets and both observed `bytes=first-last/total` and standard
  `bytes first-last/total` Content-Range forms. Allow one retry for transient
  failures; use an 8-second timeout and caller cancellation.
- Disable Android app backup so secure-storage ciphertext is not restored onto a
  device that cannot access the original Android Keystore keys.

## Evidence and consequences

Package versions and federated platform implementations were checked against
their pub.dev metadata and package manifests. The Android secure-storage plugin
requires API 24, matching the app's minimum SDK. The app does not use GMS,
Firebase, a media index, or whole-file downloads in this slice.

Offline integration tests use a loopback fake WebDAV server with anonymous test
credentials. A real account is not used in CI. Android and Windows builds and
manual device verification are reported in the M2-A Draft PR and `docs/STATUS.md`.
