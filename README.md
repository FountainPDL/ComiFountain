# ComiFountain

A source-based manga/comic reader for Android, inspired by [Mihon](https://github.com/mihonapp/mihon) (Tachiyomi fork).

**Package:** `com.fountainpdl.comifountain`  
**Min SDK:** 28 (Android 9)  
**Target SDK:** 34 (Android 14)  
**Language:** Java  

---

## Features

- **Library** — track reading progress, categories, unread counts
- **Search** — browse/search across multiple sources
- **Sources** — AllManga (GraphQL), MangaPuma (scraper), RavenScans (scraper), Local (folder/CBZ)
- **Reader** — LTR, RTL, vertical, webtoon modes with pinch-to-zoom
- **Settings** — Solid / Dual-Shift / Dynamic theming, reader preferences
- **Offline** — download chapters for offline reading

## Architecture

Mihon-style:

```
MainActivity (bottom nav)
├── LibraryFragment       ← ViewModel + Room LiveData
├── SearchFragment        ← ViewModel + Source.search()
├── SourcesFragment       ← SourceRegistry + SAF folder picker
├── UpdatesFragment       ← Library manga with unread chapters
├── SettingsFragment      ← AppPreferences (SharedPreferences)
├── MangaDetailFragment   ← ViewModel + Source.getChapterList()
└── ReaderFragment        ← ViewModel + Source.getPageList() + ViewPager2
```

## Sources

| Source | Type | Notes |
|--------|------|-------|
| AllManga | GraphQL (`api.allanime.day`) | Requires `Referer` + `Origin` headers |
| MangaPuma | HTML scraper | Via `corsproxy.io` |
| RavenScans | HTML scraper | `ts_reader.run` parser, `ravenscans.com` |
| Local | SAF + CBZ | Folder structure: `Series/Chapter/images` or `.cbz` |

## Setup

1. Clone the repo
2. Open in **Android Studio Hedgehog** or later
3. `File → Sync Project with Gradle Files`
4. Add your app icon to `res/mipmap-*` (all densities)
5. Build → Run on device or emulator (API 28+)

### First build

```bash
./gradlew assembleDebug
```

APK output: `app/build/outputs/apk/debug/`

## Generating project files

```bash
bash patch_comifountain.sh       # data layer, build files, models
bash generate_comifountain.sh    # network, sources, UI, layouts, resources
```

---

*Built by FountainPDL — May 2026*
