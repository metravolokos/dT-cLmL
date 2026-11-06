# UI/UX specification: Symfonium-inspired CloudMail Player

Version: 1.0 (proposal)  
Date: 2026-11-06  
Owner: product/user acceptance  
Platforms: Android (portrait first), Windows 10/11 and Linux GNOME/Wayland  
Language: Russian (ARB strings, no hardcoded user-facing strings)

## 0. Purpose and authority

Use the **interaction and information-architecture principles** of Symfonium as reference, not its proprietary artwork, icons, code, exact layouts or brand. Create an original Flutter Material 3 interface for the existing Cloud Mail.ru WebDAV player.

The original requirements in `docs/USER_SPEC_RU.md` remain authoritative. This is a proposed interface refinement. In particular **do not introduce playlists, favorites, ratings, mixes, radio, social features, additional cloud providers, DSP or lyrics** merely because Symfonium offers them. Keep current WebDAV, SQLite, playback/cache and system-media integrations.

Source observations: Symfonium distinguishes configurable Home/Library, album/artist detail pages, independent compact and expanded Now Playing screens, display modes, sorting/filtering and theming. It also lets users hide major controls; **we deliberately do not copy that risk**. Links and a confidence note appear at the bottom.

## 1. Principles

- **Music first:** artwork, album title, artist, track title and predictable navigation are more prominent than file/system metadata.
- **One tap, one unambiguous action:** tap album card -> open album; tap artist -> open artist; tap track -> play track in its contextual queue. Playback from a card is an explicit small Play action, not the card's primary click.
- **The player follows everywhere:** a persistent compact player on all main library screens and nested album/artist screens; a single global playback state; do not instantiate a second player.
- **Progressive disclosure:** play/previous/next/seek immediately available; repeat, shuffle, queue and detailed technical data reside on expanded player/secondary controls, not compact bar.
- **Incremental Cloud Mail library:** file list and progressively discovered tags appear immediately; catalog scan never blocks browsing; maintain local position and navigation.
- **Adaptive, accessible, stable:** touch >= 48x48 logical px, keyboard/focus accessibility, large fonts, RTL-safe alignment where applicable, smooth lists, graceful missing artwork.
- **Original identity:** apply product-approved color tokens and branding if available. Do not copy Symfonium logo, graphics, presets or custom community themes.

## 2. Navigation / information architecture

### 2.1 Android compact widths < 600 dp

A single horizontal bottom NavigationBar with exactly four destinations: **Треки | Альбомы | Исполнители | Настройки**. All four icons/labels remain in one row; no wrapping, two-row navigation or hidden overflow. Search is a prominent icon/action in the app bar and uses a full-screen search route or inline search overlay. Do not add Home, Playlists, Favorites, Genre or Library categories as extra mandatory tabs.

The compact player sits directly above the bottom navigation on every library route. Opening an artist or album preserves it. Full-screen Now Playing hides the duplicate compact player, but does not reset playback. Android back collapses Now Playing to the previous route without stopping audio; navigation remembers scroll, filter and sort state per tab.

### 2.2 Desktop >= 720 dp

NavigationRail (or a persistent compact sidebar when width >= 1100 dp), content at expandable width. Do not arbitrarily cap the whole library at 800 dp; keep sensible maximum reading width only for dense text views, not album grids. Provide a persistent bottom player strip with artwork, title/artist, previous/play-next, seek bar, and volume control where supported. Expanded player may open in a separate route/panel.

### 2.3 Intermediate 600–719 dp

Use compact navigation or rail according to actual available content width and text scaling. No layout overflows or two-row menu. Window resizing must not recreate `AudioPlayer`, restart catalog scanning or discard the selected track.

### 2.4 Route contract

- `/tracks`, `/albums`, `/artists`, `/settings`
- `/albums/:albumKey` -> dedicated AlbumDetailPage
- `/artists/:artistKey` -> ArtistDetailPage, then album detail by click
- `/search` -> contextual results grouped by Tracks, Albums, Artists
- `/now-playing` -> full player; optional Queue sheet

Deep links are internal route concepts, not new authenticated WebDAV URLs. Preserve back behavior and stable identity even while metadata changes from placeholders to parsed tags.

## 3. Compact player: mandatory single-row design (P0)

### 3.1 Android layout

A **single row** with left-to-right:
1. 44–48 dp square artwork (placeholder when missing);
2. flexible title (one line) and artist (one line in same text column), ellipsis;
3. Play/Pause, and Next controls; previous is optional on <= 360 dp, but prefer previous at larger widths;
4. slim 2–3 dp determinate progress **integrated along one edge of the bar**, not a full-size Slider occupying a second row.

No Stop, Shuffle or Repeat buttons in the compact player. Compact height target 64–76 dp excluding the thin progress line. Maintain a touch target >= 48 dp for each actionable item; on 320–360 dp remove Previous before reducing Play/Pause hit target. Artwork/title tap opens Now Playing; button taps never open that screen.

### 3.2 Playback states

- `idle`: compact player absent.
- `opening/buffering`: selected track visible; show a spinner or subtle indeterminate indication; **the central button must reflect pending playback intention** and turn to Pause when playback starts, not stay at Play erroneously.
- `playing`: visible Pause icon.
- `paused`: visible Play icon, preserve progress.
- `error`: show concise error icon and accessible retry/More action, do not permanently block tab navigation.
- `disconnected`: stop and clear only when account is explicitly disconnected; never replay a stale track.

Progress position updates must not trigger renewed cover WebDAV requests or reconstruct the entire navigation tree.

### 3.3 Desktop compact player

Use same shared state but allow previous, play/pause, next, readable timeline, optional volume and queue shortcut. Keep one horizontal strip and avoid duplicating the Android bottom navigation.

## 4. Library and discovery (P0/P1)

### 4.1 Tracks

Default is a virtualized, scrollable list. Each item: optional ~48 dp cover, title, artist — album subtitle, duration right, trailing contextual More menu. A single tap starts playback in the *current filtered/sorted visible queue*; no extra Play button required if the row itself is a clear play target. An explicit More menu offers **Play next**, **Add to queue**, **Go to album**, **Go to artist**, and **Track information** where supported; no playlists/favorites.

Support sorting by title, artist, album, duration (when indexed), filename and stable default catalog order. A changed sort persists per screen; sorting does not alter the current playback position or force downloading audio. A filter/search is applied locally while SQLite is available.

### 4.2 Albums

Default view: responsive grid of **square covers** with album title and album artist underneath, not heavy full-height cards. 2 columns at typical phone width (~360–430 dp), 3–4 at larger phones/tablets, and adaptive desktop columns (tile art 150–220 dp). Use lazy/sliver grids. Title max 2 lines; artist max 1 line. Missing art uses consistent theme-tinted placeholder, no endless retries.

Tapping cover/card **opens dedicated album detail page**. Optional small Play icon can start the full album; do not make card tap start music. Sort by album title, artist, year if known, recently added if reliably indexed. Album identity uses project rules, not only textual title. Cover = first (by disc/track number) valid track cover per album, with artist-aware grouping; avoid eager GETs for every album on first display.

### 4.3 Album detail page (P0)

Header: large cover (phone ~140–220 dp; desktop 240–320 dp), full album title, artist link, optional year, track count, duration and format if known. Actions: **Воспроизвести**, **Перемешать**. Technical metadata is subordinate/collapsible. Follow with track list ordered `discNumber -> trackNumber -> stable filename` and disc separators for multi-disc albums. Track rows show number, title, duration; artist only for compilations/guest tracks or if different from album artist.

Selecting a track plays it within this album queue starting at its index. Back returns to the *same scroll position* in album grid. Do not use the existing 72%-height modal sheet as the primary album page; bottom sheet is appropriate for contextual actions only.

### 4.4 Artists and artist detail (P0)

Artist list: name, optional artwork collage from the artist's albums (not a fabricated external portrait), album count and track count. Alphabetical list with quick section index optional P1; tapping artist opens details.

Artist detail composition, in **this order**:
1. title/artist header;
2. section **Альбомы** with a horizontal or adaptive cover grid, sorted predictably;
3. section **Треки** with all tracks by this artist and optional sort;
4. compact persistent player.

Tapping an album card here **opens AlbumDetailPage**; it must not start playing immediately. An explicit album Play action may start playback. Tapping an individual track plays it in the artist-context queue. A user need not go back to the main Albums tab to browse the artist's album tracks. For artist vs album artist, use the project's metadata grouping rules and clearly handle compilations.

### 4.5 Search (P1)

One search entry point visible in main app header, with search results grouped **Треки / Альбомы / Исполнители** and counts. Match title, artist, album and filename (case-insensitive; normalize `ё/е`). Query persists on navigation back; clear action restores full library. Search must work against progressively imported records, without remote GET per keystroke. For 50k-track target, debounce input ~150–250 ms and use index-backed query/pagination rather than filtering an entire catalog on every frame.

## 5. Now Playing full screen (P0)

### 5.1 Portrait hierarchy

A. Top area: collapse/back, optional queue icon, simple title; avoid a second heavy AppBar above artwork.

B. Dominant square cover centered at 60–90% available content width, bounded for short screens and never cropped unintentionally; default `BoxFit.contain` to preserve album artwork. Tapping cover may toggle details; **Play/Pause, Previous and Next must remain visibly accessible**, never hidden by a theme.

C. Title (up to 2 lines), artist as clickable link, album as clickable link; optional quality chip such as `FLAC · 44.1 kHz · 16-bit` only when accurately known. Do not infer bitrate/sample rate from file extension alone.

D. Seek bar with current time and total time, accurate buffered fraction visually distinct but subtle. During seek drag, keep preview state and commit on release; seeking a fully cached region must not increase network GETs.

E. Primary controls: **Previous — Play/Pause (prominent) — Next**. Shuffle and Repeat appear as secondary icons on the same screen or in an accessible overflow, but never in compact player. Repeat cycles Off -> All -> One with obvious selected state. Additional Queue control opens queue bottom sheet/panel.

F. Cloud/buffering/error state only when meaningful; no diagnostic widgets in normal UI.

### 5.2 Expanded desktop / landscape

Two-column layout where space allows: cover on left, metadata/controls/queue on right, rather than simply stretching the portrait view to 1000 px. Keep minimum target sizes and avoid duplicated compact player. Full queue can be an optional right panel. Do not require animated waveform, lyrics or audio visualizers in initial implementation.

### 5.3 Gestures (optional P1)

Horizontal swipe across artwork = previous/next only if it does not compete with scrolling and has an obvious visual hint; vertical swipe down = close expanded player on Android. No gesture-only function: all commands have visible or accessible buttons. Respect reduced-motion settings.

## 6. Queue behavior and contexts (P0/P1)

Selecting a track from Tracks uses the sorted/filtered visible track list as queue. Selecting from Album uses that album; selecting from Artist uses that artist's sorted track list. Queue sheet shows current, next and later items with artwork/title/artist, current highlight, scroll-to-current and actions Play / Play next / Remove from queue **only if domain queue supports them**. No fake reordering or queue controls disconnected from data model.

Shuffle and Repeat must update one common controller; the OS media session and mini/full player must always show the same playing/paused state and track. Reopening Now Playing must not reset the queue or seek. If a feature is unsupported by the current queue domain, hide/disable it rather than show a dead control.

## 7. Visual design system (P0)

Use a **distinctive original design** based on the project's approved identity (graphite / dusty rose / cream when approved for this repo) rather than Symfonium color presets. Theme defaults: follow system, Light, Dark. On Android optionally allow Material You accent as a user preference, not the sole default; Linux respects GNOME light/dark when supported.

Initial token proposal (must be reviewed against approved palette): `surface`, `surfaceContainer`, `onSurface`, `onSurfaceVariant`, `primary`, `secondary`, `outline`, `error`. Do not hard-code UI colors per widget; use ColorScheme + small semantic token extensions. Clear artwork should remain visually dominant; if dynamic art colors are added (P2), restrict them to player backgrounds with accessible text contrast and keep a static-color fallback.

Suggested geometry: outer horizontal padding 16 dp phone, 24 dp tablet, 24–32 dp desktop; 8 dp spacing grid; 8–12 dp radius for covers; 12–16 dp cards; compact touch targets >= 48 dp. Typography: normal title 16–18 sp, track metadata 12–14 sp, section heading 20–24 sp, full player title 22–28 sp, scalable with text settings. Full black/AMOLED variant, importable preset themes and per-icon editors are **not P0**.

Loading: lightweight skeleton/placeholder for artwork without blocking interaction. Do not synthesize cover images. A single source image may be decoded at different target resolutions; LRU bounded by bytes, and no unbounded network preloading from large grids.

## 8. Connectivity, import and empty states (P0)

On app launch, restore saved account silently from the OS secure store and show cached catalog immediately. Do not ask for login again unless credentials are missing/invalid or user explicitly disconnects.

When importing, display **two independent phases**: received file list (if total unknown, bytes/indeterminate indicator) and tags processed `N / total` with percentage. Files must appear in the library as discovered, before tags are complete. A restart resumes pending metadata scan automatically without resetting indexed tracks. Error states distinguish no network, unauthorized, missing `/AllMusic`, metadata error, cover unavailable, audio unavailable; actionable retries must not erase valid local catalog.

Do not duplicate a permanent 2nd progress bar in compact player; import progress belongs in library header or a small dismissible status surface.

## 9. Responsiveness and accessibility

- At 320/360/393/412/600/720/1024/1440 logical px and 100%–200% text scaling, menus and player controls never overflow. Bottom navigation remains one row.
- Touch targets >= 48 dp (Android). Icons have Russian semantic labels and keyboard tooltips on desktop.
- Keyboard: Tab/Shift+Tab focus, Enter to open/play context, Space to play/pause when focus is on player, Escape to collapse dialogs/player, arrows for slider while focused. Do not steal global keys from editable text fields.
- Minimum WCAG AA contrast target (4.5:1 normal text / 3:1 large text/icons), test light/dark backgrounds.
- Lists use `ListView.builder`, `SliverList`, `SliverGrid`; no eager fetch of all images or full 50k track objects per frame.
- Restore screen scroll/filter/sort after returning from album/artist/Now Playing routes. Respect orientation constraints already accepted by the user.
- When artwork or duration is missing, show a fallback and keep controls functional.

## 10. Recommended Flutter component map

Use existing Riverpod providers and audio/cache code. Proposed presentation components:
- `AdaptivePlayerShell`: Android BottomNavigationBar vs desktop NavigationRail/sidebar, compact player, persistent route stacks.
- `CompactPlayerBar`: single-row, edge progress, cover + title/artist + Play/Pause/Next.
- `AlbumGrid`, `AlbumTile`, `AlbumDetailPage`, `AlbumTrackList`.
- `ArtistList`, `ArtistDetailPage`, `ArtistAlbumSection`, `ArtistTrackSection`.
- `TrackList`, `TrackTile`, `LibrarySortFilterBar`, `SearchResultsPage`.
- `ExpandedPlayerPage`, `PlayerSeekBar`, `PlaybackTransportControls`, optional `QueueSheet`.
- `LibraryImportStatus` and `OfflineOrErrorState`.
- `ArtworkProvider`/thumbnail cache must reuse WebDAV + SQLite identities already implemented, not add direct HTTP downloads in UI widgets.

Keep business logic out of widgets, platform packages under `lib/platform/<os>` and app text in ARB. Migrate screen by screen; do not rewrite WebDAV, SQLite, audio decoder, cache or platform media sessions for an interface redesign.

## 11. Implementation plan and acceptance gates

| Priority | Delivery slice | Test / acceptance |
| --- | --- | --- |
| P0-1 | Album detail route + artist album-click fix | Album card opens album page (not playback or modal); artist page shows albums above tracks; back restores position |
| P0-2 | Compact player precise single-row layout | 320–430 dp one row, progress no extra Slider row; no Stop/Repeat/Shuffle; Play/Pause icon follows actual player |
| P0-3 | Adaptive navigation and nested-route mini player | 4 Android items one navigation row; compact player on album/artist screens only once; full player has no duplicate |
| P0-4 | Expanded player hierarchy / click-through metadata | Previous/Play/Next always visible; album/artist links work; accurate progress, buffer and repeat/shuffle |
| P0-5 | Streaming import and error-state polish | incremental file visibility, live counters, auto-resume, saved-login restoration and clear errors |
| P1-1 | Sort/filter/persist and search grouped by entity | stable sorting, per-tab restore, Cyrillic/`ё` search, no network per keypress |
| P1-2 | Queue panel and contextual menus | one queue context; no dead action; media session remains consistent |
| P1-3 | Desktop density, keyboard controls and adaptive full player | responsive windows and Linux scaling without overflow |
| P2 | Optional theme presets, artwork-derived accents and extra gestures | only after real-device P0 acceptance and no performance regression |

Definition of done for **every slice**:
1. Implement in a separate feature branch and add widget/logic tests; avoid touching existing cloud transport.
2. Run `dart format`, `flutter analyze`, `flutter test`, architecture boundary checks, and Quality + Android + Windows + Linux CI on **exact PR HEAD**.
3. Verify no fresh credentials in repository, no unexpected network GET for artwork on repeated rebuilds, no new GMS dependencies.
4. Do concise manual smoke tests on Android and Windows; record device-dependent limits separately.
5. Merge only a fully checked and conflict-free PR; update status docs with *implemented* vs *device-verified*.

### Essential automated UI scenarios

- Open Tracks -> select track -> compact Pause icon when actually playing -> switch to Albums without losing audio.
- Tap album card -> detail page, select 3rd track -> queue from 3rd position; back returns to original album grid scroll.
- Tap artist -> covers in top section, tracks below; tap album card -> album detail, **not** playback; mini player remains.
- Search Cyrillic artist, album, track; search `е` should match equivalent `ё` forms; clear resets correctly.
- While metadata scan reports 10/3590 etc., UI remains responsive and new tracks appear without a full-screen loading wall.
- Android 320/360/393 dp: bottom navigation and compact bar one row, no overflow at text scale 1.3.
- Full player Seek/Next/Stop preserves logical state; playback icon is consistent across compact, expanded and platform media session.
- Reopen album/artist and rotate/resize desktop without duplicate artwork GET, UI reset, extra player instance or lost scroll state.
- Missing cover, missing year and invalid tags render placeholders safely; no broken images or fabricated fields.

## 12. Scope guard: what we explicitly do NOT copy from Symfonium

Do not implement Symfonium's playlists/favorites, automated mixes, multi-provider integrations, cast/cloud switching, equalizers/AutoEQ, ratings, lyrics, style-sharing community, import/export of themes, drag-to-reorder playlists, or every possible per-button customization. They are outside this project's agreed requirements. Also do not copy Symfonium screenshots, illustration assets, icons, trademarks or pixel-exact screen compositions into distributed app resources.

**Source vs design distinction:** configurable layouts, media lists and gesture options are documented Symfonium features; every numeric size, route structure, priority and test in this document is a **CloudMail Player design proposal**, not an assertion that Symfonium uses the same measurements.

## 13. Reference documents (checked 2026-11-06)

- Official overview: https://symfonium.app/
- Configurable interface: https://docs.symfonium.app/wiki/other/symfonium-configurable-interface/
- Media lists: https://docs.symfonium.app/wiki/settings/settings-interface-media-lists/
- Navigation and media start: https://docs.symfonium.app/wiki/settings/settings-interface-navigation-and-media-start/
- Album page: https://docs.symfonium.app/wiki/settings/settings-interface-album-page/
- Artist page: https://docs.symfonium.app/wiki/settings/settings-interface-artist-page/
- Expanded player: https://docs.symfonium.app/wiki/settings/settings-now-playing-expanded-player/
- Compact player: https://docs.symfonium.app/wiki/settings/settings-interface-now-playing-screens/
- Library sorting/filtering: https://docs.symfonium.app/wiki/other/sort-filter-and-configure-display-modes-in-library-views/
- Themes: https://docs.symfonium.app/wiki/settings/settings-interface-theme-font-and-colors/
- Screenshots (historical): https://docs.symfonium.app/wiki/other/promotional-video-images/

Official docs state that available controls vary by Android version and that some screenshots come from previous versions. This proposal is based on documented design patterns and publicly available screenshots, not an interactive hands-on audit of a Symfonium install.
