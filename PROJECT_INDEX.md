# Kurogane - Project Index

## 1. Overview

Kurogane is a monorepo media discovery and tracking platform focused on pan-Asian media: Anime, Donghua, Aeni, Manga, Manhwa, Manhua and Webtoons. The project combines an offline media dataset, live enrichment from AniList, search ranking logic, recommendation systems, watch-order guides and user profiles.

The system is split across three application layers:

- API backend: Express + TypeScript
- Web frontend: Next.js + React + Tailwind
- Mobile app: Flutter
- Shared package: TypeScript domain models and constants

---

## 2. Repository map

```text
kurogane/
├── .github/
│   └── workflows/
│       └── ci.yml
├── README.md
├── ROADMAP.md
├── PROJECT_INDEX.md
├── OPTIMIZATIONS.md
├── .env.example
├── package.json
├── tsconfig.base.json
├── vercel.json
├── apps/
│   ├── api/
│   │   ├── package.json
│   │   ├── prisma/
│   │   │   └── schema.prisma
│   │   ├── data/
│   │   │   ├── anilist-cache.json
│   │   │   ├── news-db.json
│   │   │   ├── users-db.json
│   │   │   ├── watchlist-db.json
│   │   │   ├── media-seed.json
│   │   │   └── tag-taxonomy.json
│   │   └── src/
│   │       ├── index.ts
│   │       ├── routes/
│   │       ├── middleware/
│   │       ├── test/
│   │       ├── test-search.ts
│   │       └── services/
│   ├── web/
│   │   ├── package.json
│   │   └── src/
│   │       ├── app/
│   │       ├── components/
│   │       │   ├── home/
│   │       │   └── ...
│   │       └── lib/
│   └── mobile/
│       ├── pubspec.yaml
│       ├── lib/
│       └── android/ios/windows/linux/macos
├── packages/
│   └── shared/
│       ├── package.json
│       └── src/
│           ├── index.ts
│           └── types/
└── anime-offline-database-minified.json
```

---

## 3. Application architecture

### 3.1 API backend

Primary entry point:

- apps/api/src/index.ts

Responsibilities:

- app bootstrap and environment config
- authentication endpoints
- profile and watchlist endpoints
- route wiring for media search, recommendations, franchises, news, health checks
- API server on port 4000 by default

Important backend services:

- apps/api/src/services/db.ts
  - offline database loading
  - indexed media search
  - cache, filtering, ranking, curated shelves
- apps/api/src/services/anilist.ts
  - AniList GraphQL integration
  - live media lookup and ranking fetches
- apps/api/src/services/franchise.ts
  - watch-order guides for major franchises
- apps/api/src/services/db-persistent.ts
  - persistent user data and auth/session storage
- apps/api/src/services/news-rss.ts
  - news aggregation
- apps/api/src/services/security.ts
  - normalization, hash comparison, password checks
- apps/api/src/services/resend.ts
  - OTP email sending and verification
- apps/api/src/services/rate-limiter.ts
  - auth rate limiting

Core data files:

- apps/api/data/tag-taxonomy.json
- apps/api/data/media-seed.json
- apps/api/data/anilist-cache.json
- apps/api/data/users-db.json
- apps/api/data/watchlist-db.json
- apps/api/data/news-db.json

---

### 3.2 Web frontend

Primary entry point:

- apps/web/src/app/page.tsx

Stack:

- Next.js 14 with App Router
- React 18
- TypeScript
- TailwindCSS
- Lucide icons

Key concerns:

- homepage media discovery and cards
- search UI and filters
- season-based shelves and ranking sections
- library/watchlist/recommendation screens integrated via app routes in src/app/

Directory highlights:

- apps/web/src/app/
  - routing and page shells
- apps/web/src/components/
  - reusable UI elements
- apps/web/src/lib/
  - API client helpers and shared frontend logic

---

### 3.3 Mobile app

Primary entry point:

- apps/mobile/lib/main.dart

Stack:

- Flutter
- Riverpod
- Firebase
- SharedPreferences
- custom theming and animated UI

Main structure:

- apps/mobile/lib/views/
  - main navigation, home, explore, watchlist screens
- apps/mobile/lib/core/
  - theme, firebase config, constants
- apps/mobile/lib/providers/
  - state management / API providers
- apps/mobile/lib/widgets/
  - reusable visual components
- apps/mobile/lib/services/
  - API communication and data handling

---

### 3.4 Shared package

Primary file:

- packages/shared/src/index.ts

Purpose:

- shared TypeScript types and constant exports
- cross-app interoperability for API and web clients
- common model definitions such as media item shapes, sorting, statuses and search response structures

---

## 4. Search and indexing model

The backend implements a custom search/index layer in apps/api/src/services/db.ts.

Core ideas:

- loads local media dataset and caches it in memory
- indexes items by ID and AniList ID
- builds an inverted index for token-based search
- supports normalized titles, synonyms, tags and fuzzy matching via Levenshtein distance
- generates title initialisms such as "aot" or "jjk" for search shortcuts
- includes a TTL-based cache for repeated searches
- supports content similarity and category shelves

This is effectively a custom internal search engine rather than a database-backed index.

---

## 5. Main features

- Pan-Asian media classification and discovery
- Offline media database with live AniList enrichment
- Search engine with fuzzy and acronym matching
- Franchise watch-order guides (Naruto, Fate, etc.)
- Anti-review-bombing / score metrics logic
- User profile, auth, watchlists and OTP support
- News aggregation and recommendations

---

## 6. Runtime entry points and commands

From root package.json:

```bash
npm install
npm run dev
npm run dev:api
npm run dev:web
npm run build
npm run lint
```

API-specific:

```bash
npm run dev --workspace=apps/api
npm run test:search --workspace=apps/api
```

Mobile:

```bash
cd apps/mobile
flutter run
```

---

## 7. Production / architectural notes

### Strengths

- Clean monorepo split across API, web and mobile
- Shared models reduce duplication across apps
- Search indexing logic is strong and custom built for media discovery
- Offline/online hybrid data strategy is useful for resilient media access

### Observations

- API and web are the most mature app layers in this repo
- Mobile appears feature-rich but likely still under active feature work
- Prisma is present but the repo still relies heavily on flat JSON and in-memory data structures in the API layer
- There is no visible frontend test suite or CI pipeline in the root configuration

---

## 8. Best files to inspect first

If you want to understand the project quickly, start here:

1. README.md
2. package.json
3. apps/api/src/index.ts
4. apps/api/src/services/db.ts
5. apps/api/src/services/anilist.ts
6. apps/api/src/services/franchise.ts
7. apps/web/src/app/page.tsx
8. apps/mobile/lib/main.dart
9. packages/shared/src/index.ts

---

## 9. Suggested next steps

- Add a proper documented API contract for all endpoints
- Move persistent state and user data to a proper database layer
- Add unit/integration tests for search, auth and recommendations
- Standardize error handling and API response schemas across apps
- Expand the shared package and reduce app-specific duplication

This index is intended as a navigational map for the repository and should be updated as the project evolves.
