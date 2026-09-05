# Kurogane Roadmap & Future Improvements

This document tracks planned features, architectural enhancements, and upcoming improvements for the Kurogane media tracking platform.

---

## 1. Database & Persistence Layer

- **PostgreSQL / SQLite Integration:** Persistent database layer (Prisma ORM with SQLite for dev / PostgreSQL for production).
- **Managed Authentication (Supabase / OAuth):** Externalized authentication strategy using Supabase Auth or Google & Discord OAuth — zero local password storage, maximum security, and 1-click user onboarding.
- **User Watchlists:** Custom watchlist statuses (*Watching*, *Completed*, *Plan to Watch*, *On Hold*, *Dropped*), custom ratings, and episode progress tracking.


---

## 2. Dynamic Franchise Watch Order Generator

- **Automated Tree Generation:** Build an algorithmic Watch Order graph generator that parses AniList GraphQL media relationships (`SEQUEL`, `PREQUEL`, `SIDE_STORY`, `SPIN_OFF`, `ALTERNATIVE`) automatically for any franchise, eliminating the need for manual static definitions.

---

## 3. Search Engine & Inverted Index Expansion

- **Studio & Staff Indexing:** Extend the search engine in `apps/workers-api` to support queries by Animation Studios (e.g. *ufotable*, *MAPPA*, *Kyoto Animation*), directors, manga authors, and voice actors (Seiyuu).
- **Character & Voice Actor Profiles:** Index main character names and voice actors for deeper media discovery.

---

## 4. Universal User List Importer

- **MAL / AniList / Kitsu Import Engine:** Allow users to import their existing watch histories and lists seamlessly via public API endpoints or file exports (XML/JSON).

---

## 5. Mobile Profile Screen Enhancements & Zero Hardcoding (`apps/mobile`)

- **Dynamic Verification Badge:** Condiționare `sealCheck` pe baza profilului din API / Supabase.
- **Dynamic Profile Banner & Fallback:** Suport pentru custom banner și fallback tematic nativ.
- **Cooldown Handle:** Restricție de schimbare a numelui de utilizator o dată la 14 zile, sincronizată cu backend-ul.
- **Activitate Recentă Extinsă:** Paginare și acces către lista completă din profil.

---

## 6. Mobile Series Detail Screen Enhancements (`apps/mobile`)

- **Relații Native Dinamice:** Implementat prin widget-ul `MediaRelationsView` conectat la API (`/api/media/:id/relations`).
- **Unificare Butoane Plutitoare:** Utilizare widget global `FloatingCircleButton` (52px, blur 18).
- **Modal Notare & Watchlist:** Actualizări optimiste la adăugare/editare status și notă fără flicker pe ecran.
- **Centralizare Culori & Tokens:** Aliniere culori hex de status și stea la `AppColors`.

---

## Data Sources & Information Capabilities

### 1. Offline Database (`anime-offline-database-minified.json` — 40,000+ Media Entries)
- **Titles & Synonyms:** Romaji title, English title, native Japanese/Chinese/Korean synonyms.
- **Pan-Asian Media Types:** Anime, Donghua, Aeni, Manga, Manhwa, Manhua, Webtoons.
- **Formats & Status:** TV Series, Movies, OVAs, ONAs, Specials, Releasing/Finished status.
- **Tag Taxonomy & Tropes:** 1,000+ tags (Isekai, Cyberpunk, Magic System, Time Travel, School, Slice of Life).
- **Anti-Review Bombing Metrics:** Weighted score calculations (`weightedScore`) to neutralize troll ratings.
- **Cross-Platform IDs:** Mapping to MyAnimeList, AniList, Kitsu, AniDB, and Anime-Planet.

### 2. Live AniList GraphQL API Integration (`anilist.ts`)
- **Full Synopses & Markdown Descriptions:** Detailed story synopses and background context.
- **HD Imagery & Banners:** Ultra-HD cover art, high-resolution background banners, and theme color palettes.
- **Studios & Production Staff:** Animation studios (*ufotable*, *MAPPA*, *Kyoto Animation*), mangaka, directors, composers.
- **Characters & Voice Actors (Seiyuu):** Character profiles, images, and Japanese/Chinese/English voice actors.
- **Franchise Relationship Graph:** Prequels, Sequels, Side Stories, Spin-offs, Alternative adaptations, Manga sources.
- **Live Airing Schedule:** Exact day/time countdown for upcoming weekly episodes.

### 3. User Data Layer (Supabase & Kurogane DB)
- **User Profiles:** Supabase User ID, username, email, avatar URL.
- **Watchlist Tracking:** Statuses (*Watching*, *Completed*, *Plan to Watch*, *On Hold*, *Dropped*), episode progress, scores, notes.
- **Personalized Analytics & Recommendations:** Genre preference distribution, total watch time hours, and tag-similarity recommendations based on user high ratings.

