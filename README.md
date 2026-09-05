# Kurogane 🌌

> **The Next-Generation Pan-Asian Media Discovery & Tracking Platform.**  
> Built for Anime, Donghua, Aeni, Manga, Manhwa, Manhua, and Webtoons. Monorepo architecture featuring an Inverted-Index search engine, dynamic franchise relations, real-time AniList enrichment, Supabase cloud sync, and a high-performance Flutter mobile application.

---

## 📑 Cuprins

1. [Structură Monorepo](#-structură-monorepo)
2. [Funcționalități Cheie](#-funcționalități-cheie)
3. [Stack Tehnologic](#-stack-tehnologic)
4. [Catalog de Endpoint-uri API](#-catalog-de-endpoint-uri-api)
5. [Instalare & Pornire Rapidă](#-instalare--pornire-rapidă)
6. [Variabile de Mediu](#-variabile-de-mediu)
7. [Documentație Tehnică Aprofundată](#-documentație-tehnică-aprofundată)

---

## 📁 Structură Monorepo

Kurogane este organizat ca un monorepo axat exclusiv pe **Aplicația Mobilă** și **Cloudflare Workers API**:

```text
kurogane/
├── apps/
│   ├── mobile/       # Aplicație mobilă Flutter (Android/iOS) cu Riverpod, GoRouter & design minimalist
│   └── workers-api/  # Backend modern pe Cloudflare Workers (Hono, D1, KV & RSS feed-uri)
├── packages/
│   └── shared/       # Interfețe de domeniu TypeScript, constante și tipuri partajate
├── docs/
│   └── ARCHITECTURE.md # Specificații de sistem și arhitectură
├── package.json      # Configurația rădăcină & scripturile unificate de dev/build
└── tsconfig.base.json# Configurație de bază TypeScript
```

---

## ⚡ Funcționalități Cheie

- **Focus 100% Mobil:** Proiectat pentru performanță extremă pe dispozitive fizice și emulatoare.
- **Backend Edge Serverless (Cloudflare Workers + Hono):**
  - Timpi de răspuns sub 50ms la nivel global.
  - Bază de date serverless Cloudflare D1 (`kurogane-d1`).
  - Caching distribuit Cloudflare KV (`CACHE_KV`) pentru știri și cataloage media.
- **Clasificare Pan-Asiatică:** Suport pentru Anime (Japonia), Donghua (China), Aeni (Coreea), Manga, Manhwa, Manhua și Webtoons.
- **Relații Dinamice de Franciză & Personaje:** Arbore nativ de legături între serii și catalog bogat de personaje.
- **Știri Live Agregate:** Parsare dinamică a feed-urilor RSS (Anime News Network, Otaku USA) cu extragere automată a imaginilor și curățare conținut.
- **Zero Hardcoding:** Toate datele sunt preluate dinamic prin API-ul centralizat.
- **Client Mobil Rezistent:**
  - `ApiClient` (Dio) cu interceptori, gestionare erori și fallback automat.
  - UI reactiv prin Riverpod cu actualizări optimiste.
  - Autentificare nativă Firebase Auth & Google Sign-In.

---

## 🛠️ Stack Tehnologic

### Backend (`apps/workers-api`)
- **Runtime:** Cloudflare Workers (Edge V8)
- **Framework:** Hono v4
- **Bază de Date:** Cloudflare D1 (`kurogane-d1`)
- **Cache:** Cloudflare KV (`CACHE_KV`)
- **Surse Date:** AniList GraphQL, Kitsu API, RSS Aggregator (Anime News Network, Otaku USA)
- **URL Producție:** `https://kurogane-api.kurogane-workers-api.workers.dev`

### Mobil (`apps/mobile`)
- **Framework:** Flutter 3 (Dart 3) — Android & iOS
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter
- **Networking:** Dio cu configurare de mediu și failover automat
- **Autentificare:** Firebase Auth, Google Sign-In nativ
- **UI/UX:** Dark minimalist theme, frosted glass blur, haptic feedback, WAI-ARIA APG compliance

### Pachet Comun (`packages/shared`)
- Interfețe TypeScript de domeniu partajate.

---

## 📡 Catalog de Endpoint-uri API (Cloudflare Workers)

Backend-ul rulează pe Cloudflare Workers (`https://kurogane-api.kurogane-workers-api.workers.dev`) sau local pe portul `8787` (`wrangler dev`):

| Endpoint | Metodă | Descriere |
| :--- | :--- | :--- |
| `/api/health` | `GET` | Verificare stare server, versiune worker și stocare D1 |
| `/api/homepage` | `GET` | Secțiuni agregate pentru ecranul principal (hero, trending, popular) |
| `/api/search` | `GET` | Căutare avansată (query, genuri, format, sortare) |
| `/api/media/:id` | `GET` | Detalii complete ale unei serii (meta, scoruri, descriere) |
| `/api/media/:id/relations` | `GET` | Relațiile dinamice ale francizei (prequel, sequel, side-story) |
| `/api/media/:id/characters` | `GET` | Lista de personaje și actori vocali |
| `/api/media/:id/similar` | `GET` | Recomandări similare bazate pe afinitate de gen și format |
| `/api/categories` | `GET` | Rafturi tematice de categorii (Shonen, Dark Fantasy, etc.) |
| `/api/news` | `GET` | Feed dinamic agregat de știri anime (Anime News Network & Otaku USA) |
| `/api/watchlist` | `GET, POST` | Gestiunea listei personale de urmărire (necesită token) |
| `/api/watchlist/:mediaId` | `DELETE` | Eliminarea unei serii din lista personală |
| `/api/user/profile` | `GET, PUT` | Vizualizarea și actualizarea profilului de utilizator |
| `/api/auth/resolve-identifier` | `POST` | Rezolvare username -> email |
| `/api/auth/check-username` | `GET` | Verificare în timp real a disponibilității unui handle |
| `/api/auth/register-user` | `POST` | Înregistrare utilizator în baza de date D1 |

---

## 🚀 Rulare & Dezvoltare Rapidă

### 1. Dezvoltare Backend Local (Cloudflare Workers)
```bash
npm run dev:api
# Pornește Wrangler pe http://127.0.0.1:8787
```

### 2. Rularea Aplicației Mobile Flutter
```bash
# Rulare pe telefonul fizic conectat:
npm run dev:mobile:phone

# Rulare pe emulator:
npm run dev:mobile:emulator

# Port forwarding către telefon (Wrangler port 8787):
npm run mobile:reverse
```

### 3. Testare & Verificare
```bash
# Analiză statică Flutter:
cd apps/mobile && flutter analyze

# Rulare teste unitare Flutter:
cd apps/mobile && flutter test
```

---

## ⚙️ Variabile de Mediu & Configurare

Pentru Cloudflare Workers (`apps/workers-api`), configurați variabilele în `apps/workers-api/wrangler.jsonc` sau în `.dev.vars` pentru dezvoltare locală:

```env
JWT_SECRET=kurogane_super_secure_jwt_secret_key_change_in_production
ENVIRONMENT=development
```

---

## 📖 Documentație Tehnică Aprofundată

Pentru detalii complete de arhitectură, diagrame de flux, specificarea algoritmului Inverted-Index și rezultatele detaliate ale auditului de conformitate API <-> Mobile, consultați:

👉 **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

---

## 📄 Licență

Acest proiect este licențiat sub termenii [MIT License](LICENSE).
