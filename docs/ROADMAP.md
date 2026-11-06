# dT-cLmL — desktop roadmap

**P0 — Migration acceptance:** verify source snapshot and original Windows binary resource, run exact HEAD Quality + Windows + Linux CI and Flatpak, merge PR while preserving historical source links. Never import unscreened historical Git objects.

**P0 — Audible Windows 11 player:** use the existing P03 instrumentation to determine whether a local audio stream reaches the native MediaKit/libmpv backend; fix reproducible failure, test live `/AllMusic` indexing and FLAC/MP3 play/pause/seek/next/stop.

**P1 — Linux playback:** test native bundle and GNOME Wayland Flatpak; verify Secret Service, MPRIS and native mixer.

**P1 — Distribution:** portable complete Windows release folder ZIP and supported Linux Flatpak; native dependency and notices inventory. No production license/signing assumptions.

**P2 — UX/scaling:** search, album/artist navigation, mini-player and buffering controls, catalog pagination/migrations and recovery; prioritize observed defects. Preserve historical cross-platform user specification as provenance, not as active Android requirements.
