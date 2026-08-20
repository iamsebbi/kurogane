# Kurogane

> A modern, resilient, and open media tracking platform for Anime, Donghua, Manga, Manhwa, and Webtoons. Built with a monorepo architecture for fast searching, franchise watch order guides, anti-review bombing metrics, and pan-Asian media discovery.

---

## Project Structure

Kurogane is organized as a monorepo using **npm workspaces**:

```text
kurogane/
├── apps/
│   ├── api/          # Express + TypeScript backend API & Inverted-Index search engine
│   └── web/          # Next.js 14 + TailwindCSS modern frontend UI
├── packages/
│   └── shared/       # Shared TypeScript types, data models, and version constants
├── anime-offline-database-minified.json # Offline database seed (40,000+ media entries)
├── package.json      # Root monorepo configuration & dev scripts
└── tsconfig.base.json # Shared base TypeScript config
```

---

## Key Features

- **Pan-Asian Media Classification:** First-class support for Anime (Japan), Donghua (China), Aeni (Korea), Manga, Manhwa, Manhua, and Webtoons.
- **Inverted-Index Search Engine:** Custom search engine in `apps/api` featuring:
  - **Dynamic Acronym / Initialism Matching:** Direct resolution for common abbreviations (e.g. `aot` -> *Attack on Titan*, `jjk` -> *Jujutsu Kaisen*).
  - **Fuzzy Matching:** Levenshtein distance token matching for typo tolerance.
  - **LRU Search Caching:** Multi-tier caching with TTL for rapid response times.
- **Franchise Watch Order Trees:** Visual timeline guides supporting Recommended, Chronological, and Release order paths (featuring interactive guides for *Naruto*, *Fate*, *Demon Slayer*, *Attack on Titan*, and more).
- **Anti-Review Bombing & Score Metrics:** Weighted score calculation (`ScoreMetrics`) to counteract review bombing and troll ratings.
- **Tag Taxonomy & Demographic Engine:** Rule-based classification mapping micro-tags (Isekai, Cyberpunk, Time Travel) and demographics (Shounen, Seinen, Shoujo, Josei, Kids).
- **Content Similarity Recommendations:** Automated recommendation engine computing genre, format, and tag similarities.
- **Hybrid Data Sources:** Offline database seed supplemented with real-time AniList GraphQL API enrichment.

---

## Tech Stack

### Frontend (`apps/web`)
- **Framework:** Next.js 14 (App Router) & React 18
- **Styling:** TailwindCSS & Lucide Icons
- **Language:** TypeScript

### Backend (`apps/api`)
- **Runtime:** Node.js, Express
- **Language:** TypeScript (`ts-node-dev` for development, `tsc` for production)
- **Data & Caching:** In-memory Inverted Index, dynamic taxonomy rules (`tag-taxonomy.json`), LRU search cache
- **External Integration:** AniList GraphQL API

### Shared (`packages/shared`)
- Common TypeScript interfaces (`MediaItem`, `WatchOrderGuide`, `SearchQueryOptions`, `ScoreMetrics`)
- Global constants and utility labels

---

## API Documentation

The backend service (`apps/api`) runs by default on port `4000` and provides the following endpoints:

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/health` | `GET` | System health status, local dataset count, and version info |
| `/api/search` | `GET` | Multi-criteria search across offline DB and AniList |
| `/api/media/:id` | `GET` | Get detailed media information by ID |
| `/api/categories` | `GET` | Curated category shelves (Popular, Top Rated, Donghua, Webtoons) |
| `/api/media/:id/similar` | `GET` | Content-based recommendations for a specific title |
| `/api/media/:id/watch-order` | `GET` | Interactive watch order guide for media franchises |

### Search Parameters (`GET /api/search`)

- `q` (string): Query string (supports full title, keywords, or initialisms like `aot`, `jjk`)
- `type` (string): Media type filter (`ANIME`, `DONGHUA`, `AENI`, `MANGA`, `MANHWA`, `MANHUA`, `WEBTOON`, `ALL`)
- `format` (string): Media format (`TV`, `TV_SHORT`, `MOVIE`, `OVA`, `ONA`, `SPECIAL`, `MANGA`, `NOVEL`, `ALL`)
- `status` (string): Release status (`RELEASING`, `FINISHED`, `UPCOMING`, `CANCELLED`, `HIATUS`, `ALL`)
- `demographic` (string): Demographic target (`Shounen`, `Seinen`, `Shoujo`, `Josei`, `Kids`, `ALL`)
- `season` (string): Airing season (`WINTER`, `SPRING`, `SUMMER`, `FALL`, `ALL`)
- `year` (number/string): Release year or `ALL`
- `genres` (string / array): Single or comma-separated list of genres
- `microTags` (string / array): Single or comma-separated list of micro-tags
- `minScore` (number): Minimum score threshold (0-100)
- `sortBy` (string): Sort order (`RELEVANCE`, `SCORE_DESC`, `POPULARITY_DESC`, `YEAR_DESC`, `YEAR_ASC`, `TITLE_ASC`)
- `source` (string): Data source (`all`, `local`, `anilist`)
- `page` (number): Page number for pagination (default: `1`)
- `limit` (number): Items per page (default: `30`)

---

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher recommended)
- [npm](https://www.npmjs.com/) (v9 or higher)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/iamsebbi/kurogane.git
   cd kurogane
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

### Running in Development

To start both the API and Web applications concurrently:

```bash
npm run dev
```

Alternatively, you can run individual applications:

- **Start API backend only** (http://localhost:4000):
  ```bash
  npm run dev:api
  ```

- **Start Web frontend only** (http://localhost:3000):
  ```bash
  npm run dev:web
  ```

### Additional Commands

- **Build all applications for production:**
  ```bash
  npm run build
  ```
- **Lint the codebase:**
  ```bash
  npm run lint
  ```
- **Run API search test benchmark:**
  ```bash
  npm run test:search --workspace=apps/api
  ```

---

## Roadmap

Upcoming features and planned improvements are tracked in [ROADMAP.md](file:///d:/kurogane/ROADMAP.md):

- Persistent Database Layer (PostgreSQL / SQLite with user watchlists)
- Automated Franchise Watch Order Tree Generator via AniList GraphQL
- Extended Search Indexing (Studios, Authors & Voice Actors)
- Universal User List Importer (MyAnimeList, AniList, Kitsu)

---

## License

This project is licensed under the [MIT License](LICENSE).

