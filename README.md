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

Kurogane este organizat ca un **npm workspaces monorepo**:

```text
kurogane/
├── apps/
│   ├── api/          # Express + TypeScript backend, Inverted Index, Supabase & AniList
│   ├── mobile/       # Flutter (Android/iOS) client cu Riverpod, Firebase & failover IP
│   └── web/          # Next.js 14 + TailwindCSS interfață web modernă
├── packages/
│   └── shared/       # Interfețe de domeniu TypeScript, constante și tipuri partajate
├── docs/
│   └── ARCHITECTURE.md # Specificații de sistem și raportul de audit API-Mobile
├── package.json      # Configurația rădăcină & scripturile unificate de dev/build
└── tsconfig.base.json# Configurație de bază TypeScript
```

---

## ⚡ Funcționalități Cheie

- **Clasificare Pan-Asiatică:** Suport de prim rang pentru Anime (Japonia), Donghua (China), Aeni (Coreea), Manga, Manhwa, Manhua și Webtoons.
- **Motor de Căutare Inverted-Index:**
  - **Rezolvare Acronime / Inițialisme:** Detectare automată a prescurtărilor uzuale (`aot` -> *Attack on Titan*, `jjk` -> *Jujutsu Kaisen*, `fmab` -> *Fullmetal Alchemist: Brotherhood*).
  - **Fuzzy Matching Levenshtein:** Toleranță ridicată la greșeli de tipar cu dicționar indexat în memorie.
  - **Multi-tier Caching:** Cache LRU cu expirare automată (TTL) pentru timpi de răspuns sub 5ms.
- **Relații Dinamice de Franciză:** Arbore nativ de legături între serii (Prequel, Sequel, Side Story, Spin-off, Adaptare) îmbogățit direct din AniList GraphQL.
- **Metrici Anti-Review Bombing:** Ponderare avansată a scorului (`ScoreMetrics`) pentru neutralizarea campaniilor de troll ratings.
- **Motor de Taxonomie & Micro-Taguri:** Clasificare automată în 37 de micro-taguri semantice (*Overpowered MC, Isekai, Anti-Hero, Xianxia, Cyberpunk, Time Travel*).
- **Persistență Hibridă & Offline Fallback:**
  - Bază de date JSON locală (`apps/api/data/`) cu replicare asincronă în cluster Supabase PostgreSQL.
  - Funcționare 100% autonomă în caz de deconectare de la cloud.
- **Client Mobil Rezistent la Erori de Rețea:**
  - `ApiClient` (Dio) cu auto-failover între gazde locale (`127.0.0.1`, `192.168.1.224`, `10.0.2.2`) și cloud Render.
  - UI reactiv prin Riverpod cu actualizări optimiste (Zero screen flash / 0ms latency percepție).
  - Autentificare nativă prin Android Credential Manager & Firebase Auth.

---

## 🛠️ Stack Tehnologic

### Backend (`apps/api`)
- **Runtime:** Node.js v18+ | Express.js 4 | TypeScript 5.3
- **Securitate:** Helmet, CORS restrictiv cu whitelist și bypass autorizat pentru mobile, Rate Limiters, Bcrypt, JWT
- **Bază de date:** JSON persistent local + Supabase PostgreSQL (Mirror Cloud) + Prisma ORM
- **Integrări Externe:** AniList GraphQL API, Resend Email API, Feed-uri RSS (Anime News Network, Otaku USA)

### Mobil (`apps/mobile`)
- **Framework:** Flutter 3 (Dart 3) — Android & iOS
- **State Management:** Riverpod (`flutter_riverpod`)
- **Networking:** Dio cu interceptori Bearer token și auto-failover multi-IP
- **Autentificare:** Firebase Auth, Google Sign-In nativ (Android Credential Manager)
- **UI/UX:** Cyberpunk Otaku Theme, Frosted Glass Blur, Border Beam, Haptic Feedback

### Web (`apps/web`)
- **Framework:** Next.js 14 (App Router) & React 18
- **Styling:** TailwindCSS, Lucide Icons, GSAP Animations

### Pachet Comun (`packages/shared`)
- Interfețe TypeScript de domeniu (`MediaItem`, `ScoreMetrics`, `WatchOrderGuide`, `UserProfile`, `NewsArticle`)

---

## 📡 Catalog de Endpoint-uri API

Backend-ul rulează pe portul `4000` (configurabil prin `.env`):

| Endpoint | Metodă | Descriere |
| :--- | :--- | :--- |
| `/api/health` | `GET` | Verificare stare server, număr elemente locale și versiune |
| `/api/homepage` | `GET` | Secțiuni agregate pentru ecranul principal (hero, seasonal, airing, recomandări) |
| `/api/search` | `GET` | Căutare avansată (query, filtre, genuri, micro-taguri, sortare) |
| `/api/media/:id` | `GET` | Detalii complete ale unei serii (meta, scoruri, personaje, staff) |
| `/api/media/:id/relations` | `GET` | Relațiile dinamice ale francizei (prequel, sequel, side-story) |
| `/api/media/:id/similar` | `GET` | Recomandări similare bazate pe afinitate de gen și format |
| `/api/categories` | `GET` | Rafturi tematice de categorii (populare, top rated, donghua, webtoons) |
| `/api/news` | `GET` | Feed agregat de știri anime & manga |
| `/api/watchlist` | `GET, POST` | Gestiunea listei personale de urmărire (necesită Bearer token) |
| `/api/watchlist/:mediaId` | `DELETE` | Eliminarea unei serii din lista personală |
| `/api/user/profile` | `GET, PUT` | Vizualizarea și actualizarea profilului de utilizator |
| `/api/auth/resolve-identifier` | `POST` | Rezolvare securizată username -> email (cu protecție timing-attack) |
| `/api/auth/check-username` | `GET` | Verificare în timp real a disponibilității unui handle |
| `/api/auth/register-user` | `POST` | Sincronizare profil la înregistrare |

---

## 🚀 Instalare & Pornire Rapidă

### 1. Clonare & Instalare Dependențe
```bash
git clone https://github.com/iamsebbi/kurogane.git
cd kurogane
npm install
```

### 2. Rulare în Mod Dezvoltare
```bash
# Pornire concomitentă API (localhost:4000) și Web (localhost:3000):
npm run dev

# Sau pornire individuală a componentelor:
npm run dev:api     # Doar backend-ul API
npm run dev:web     # Doar frontend-ul Next.js
```

### 3. Rularea Aplicației Mobile Flutter
```bash
cd apps/mobile
flutter pub get

# Pe emulator Android sau dispozitiv USB:
flutter run

# Pentru dispozitiv fizic conectat prin cablu USB (permite acces la localhost:4000):
adb reverse tcp:4000 tcp:4000
```

### 4. Testare & Verificare
```bash
# Rulare teste unitare API:
npm test --workspace=apps/api

# Analiză statică Flutter:
cd apps/mobile && flutter analyze
```

---

## ⚙️ Variabile de Mediu

Copiați fișierul `.env.example` în `apps/api/.env` și completați cheile necesare:

```env
PORT=4000
NODE_ENV=development
JWT_SECRET=kurogane_super_secure_jwt_secret_key_change_in_production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
RESEND_API_KEY=re_your_resend_api_key
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

---

## 📖 Documentație Tehnică Aprofundată

Pentru detalii complete de arhitectură, diagrame de flux, specificarea algoritmului Inverted-Index și rezultatele detaliate ale auditului de conformitate API <-> Mobile, consultați:

👉 **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

---

## 📄 Licență

Acest proiect este licențiat sub termenii [MIT License](LICENSE).
