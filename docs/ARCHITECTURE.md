# Kurogane — Arhitectură Tehnică & Documentație de Sistem

> Documentație tehnică completă pentru platforma **Kurogane**: monorepo axat exclusiv pe **Aplicația Mobilă** (Flutter/Dart) și **Cloudflare Workers API** (Hono/Edge/D1/KV), pachet de tipuri partajate (TypeScript) și specificațiile de integrare.

---

## 1. Prezentare Generală a Arhitecturii

Kurogane este o platformă modernă de clasă enterprise dedicată descoperirii, clasificării și monitorizării conținutului media pan-asiatic: **Anime** (Japonia), **Donghua** (China), **Aeni** (Coreea de Sud), **Manga**, **Manhwa**, **Manhua** și **Webtoons**.

Platforma este structurată ca un **npm workspaces monorepo** simplificat și robust:

```text
kurogane/
├── apps/
│   ├── mobile/       # Aplicație mobilă Flutter (Android, iOS) cu Riverpod, GoRouter & Firebase
│   └── workers-api/  # Backend modern Cloudflare Workers (Hono, D1, KV, RSS & Kitsu Failover)
├── packages/
│   └── shared/       # Interfețe de domeniu TypeScript, constante și modele unificate
├── docs/             # Documentație tehnică și specificații de arhitectură
├── package.json      # Configurație workspace rădăcină & scripturi unificate
└── tsconfig.base.json# Configurație de bază TypeScript
```

---

## 2. Backend API Cloudflare Workers (`apps/workers-api`)

### 2.1 Tehnologii de Bază
- **Runtime:** Cloudflare Workers (Edge V8 Serverless)
- **Framework HTTP:** Hono v4 (ultrarapid, tipat, conform Web Standards)
- **Limbaj:** TypeScript 5.3+
- **Bază de date:** Cloudflare D1 (`kurogane-d1` — SQLite la Edge distribuit)
- **Cache Distribuit:** Cloudflare KV (`CACHE_KV`) pentru cache de cataloage media, seed-uri și feed-uri de știri cu TTL
- **Surse de Date Externe & Agregare:**
  - AniList GraphQL API (cu circuit de bypass și fallback la 403)
  - Kitsu API live (îmbogățire runtime a sinopsisurilor, imaginilor HD și ratingurilor)
  - Live RSS Feed Aggregator (Anime News Network, Otaku USA)
- **Securitate:** CORS complet conform cu suport pentru clienți nativi mobili, validare JWT Bearer, rate limiting nativ Edge.

### 2.2 Arhitectura de Rezistență (Hybrid Failover)
1. **Bypass Anti-Bot / WAF:** Când serverele upstream AniList emit blocaje WAF 403 Forbidden, worker-ul comută transparent și instantaneu pe catalogul îmbogățit D1/KV combinat cu runtime enrichment de la Kitsu API.
2. **Zero Hardcoding:** Nicio informație despre serii, personaje, actori vocali sau știri nu este hardcodată în clientul mobil. Toate datele sunt obținute dinamic.
3. **Agregator de Știri Live:** Parsare dinamică de feed-uri XML RSS, decodare entități HTML, extragere regex a tagurilor `<img>` și `<enclosure>` din conținut, formatare automată a datelor în limba română și caching în KV (`news:items`) cu TTL de 1800 secunde.

### 2.5 Catalog de Endpoint-uri API

| Metodă | Rută | Autentificare | Descriere |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/health` | Public | Starea serverului, număr de elemente indexate și versiune |
| `GET` | `/api/homepage` | Opțională | Secțiuni agregate pentru ecranul principal (hero, seasonal, airing, recomandări, trending) |
| `GET` | `/api/search` | Public | Căutare multi-criterială (text, fuzzy, genuri, micro-taguri, status, sortare) |
| `GET` | `/api/categories` | Public | Rafturi tematice de categorii (populare, cele mai bine cotate, donghua, webtoons) |
| `GET` | `/api/media/:id` | Public | Informații complete despre o serie media (detalii, imagini, scoruri, personaje, staff, teme sonore) |
| `GET` | `/api/media/:id/relations` | Public | Relațiile dinamice ale francizei (prequel, sequel, side story, spin-off, adaptare) |
| `GET` | `/api/media/:id/similar` | Public | Recomandări similare bazate pe scor de genuri comune și format |
| `GET` | `/api/media/:id/watch-order`| Opțională | Ghid de ordine de vizionare a francizei și propuneri comunitare |
| `POST`| `/api/media/:id/watch-order/presets` | `requireAuth` | Trimite o propunere comunitară de vizionare |
| `POST`| `/api/media/watch-order/presets/:presetId/vote` | `requireAuth` | Votează o propunere (+1 upvote / -1 downvote) |
| `POST`| `/api/media/watch-order/presets/:presetId/report`| `requireAuth` | Raportează o propunere pentru moderare |
| `GET` | `/api/news` | Public | Feed agregat de știri anime/manga din surse RSS oficiale |
| `GET` | `/api/watchlist` | `requireAuth` | Returnează lista personală de urmărire a utilizatorului curent |
| `POST`| `/api/watchlist` | `requireAuth` | Adaugă sau actualizează o serie în watchlist (status, scor, progres, date) |
| `DELETE`| `/api/watchlist/:mediaId` | `requireAuth` | Șterge o serie din lista personală |
| `GET` | `/api/user/profile` | `requireAuth` | Returnează profilul utilizatorului autentificat |
| `PUT` | `/api/user/profile` | `requireAuth` | Actualizează profilul (cu validare, sanitizare și cooldown de 14 zile la handle) |
| `POST`| `/api/auth/resolve-identifier` | Public (Rate Limited) | Rezolvă un @username în email pentru autentificarea unificată |
| `GET` | `/api/auth/check-username` | Public | Verificare disponibilitate username în timp real |
| `POST`| `/api/auth/register-user` | Public (Rate Limited) | Înregistrează sau sincronizează un profil de utilizator nou |
| `POST`| `/api/auth/send-otp` | Public (Rate Limited) | Trimite cod OTP de 6 cifre prin email (Resend API) |
| `POST`| `/api/auth/verify-otp` | Public (Rate Limited) | Verifică codul OTP și emite JWT semnat criptografic |

---

## 3. Aplicația Mobilă (`apps/mobile`)

### 3.1 Tehnologii & Arhitectură
- **Framework:** Flutter 3 (Dart 3)
- **State Management:** Riverpod (`flutter_riverpod`) — utilizare de `StateNotifierProvider` pentru stări mutabile (Watchlist, Profil, Setări), `FutureProvider` pentru cereri asincrone și `StreamProvider` pentru fluxul Firebase Auth.
- **Client HTTP:** Dio cu interceptori pentru tokeni Bearer și sistem de auto-failover inteligent.
- **Autentificare Nativă:**
  - Firebase Authentication (`firebase_auth`).
  - Google Sign-In nativ pe Android prin canal de platformă dedicat (**Android Credential Manager** bottom-sheet nativ).
  - Rezolvitor transparent @username -> email în backend pentru login fluent.
- **Sincronizare AniList:** Serviciu dedicat (`AnilistSyncService`) care permite conectarea cu token OAuth AniList GraphQL, importul listelor și sincronizarea progresului/notelor în ambele direcții.

### 3.2 Strategia de Rețea & Auto-Failover Multi-Host
Definită în `apps/mobile/lib/core/network/api_client.dart` și `api_constants.dart`:
Aplicația detectează automat mediul de execuție și dispune de o listă ordonată de URL-uri candidate:
1. `http://127.0.0.1:4000` — Conexiune locală prin USB (`adb reverse tcp:4000 tcp:4000`) sau loopback.
2. `http://192.168.1.224:4000` — IP-ul din rețeaua locală Wi-Fi (pentru testare directă pe dispozitiv fizic fără cablu).
3. `http://10.0.2.2:4000` — Alias-ul standard al emulatorului Android Studio pentru mașina gazdă.
4. `https://kurogane.onrender.com` — Fallback-ul de producție găzduit în cloud.

Dacă un URL este complet inaccesibil (eroare de conexiune sau timeout), `_executeWithFallback` comută automat pe următorul candidat valid și memorează noul `_workingBaseUrl` pentru toate cererile ulterioare. Dacă serverul returnează un cod HTTP valid (de exemplu `404 Not Found`), clientul știe că serverul este online și **nu** execută comutare inutilă.

### 3.3 Interfață & Design System
- **Paletă de Culori Otaku / Cyberpunk (`AppColors`):**
  - Fundal principal: `#090C0E` (Dark Canvas)
  - Suprafață carduri: `#11161B` / `#161D24`
  - Accent primar: Indigo electric `#6366F1`
  - Accente secundare: Coral `#FF5C5C`, Amber aurit `#F59E0B`, Cyan `#06B6D4`
- **Componente Avansate:**
  - `HeroCarousel`: Carusel cinematic cu auto-scroll fin, indicatori luminoși și gradient dinamic.
  - `BorderBeam`: Animație fluidă cu laser/border luminos de-a lungul chenarului cardurilor active.
  - `FloatingCircleButton`: Butoane circulare plutitoare cu efect Frosted Glass și feedback haptic.
  - `MediaRelationsView`: Vizualizare curată a întregii francize (Prequel, Sequel, Side Stories) cu etichete de relație clare și navigare directă.
  - `Optimistic UI`: Actualizarea instantanee a listei de urmărire și a profilului la interacțiunea utilizatorului, cu sincronizare silențioasă în fundal pentru eliminarea oricărui flicker sau delay vizual.

---

## 4. Raportul Complet de Audit API <-> Aplicație Mobilă

În urma analizei exhaustive a codului sursă din `apps/workers-api` și `apps/mobile`, s-au verificat contractele, DTO-urile, antetele și fluxurile de date:

### 4.1 Matricea de Conformitate a Endpoint-urilor

| Funcție Mobil (`ApiClient` / `AuthService`) | Endpoint Apelat | Metodă | Rută Corespondentă în Worker | Status Audit | Note |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `getHomepage()` | `/api/homepage` | `GET` | `/api/homepage` | ✅ Conform | Câmpurile DTO (`featuredSeason`, `recentlyAired`, `newsBeta`, `recommendations`, `topAiring`, `topUpcoming`, `top100`) se mapează identic. |
| `searchMedia(...)` | `/api/search` | `GET` | `/api/search` | ✅ Conform | Parametrii de query (`q`, `type`, `format`, `status`, `genres`, `sortBy`, `limit`, `page`) sunt acceptați și procesați identic. |
| `getMediaById(id)` | `/api/media/:id` | `GET` | `/api/media/:id` | ✅ Conform | Returnează `MediaItem` complet; 404 tratat cu `null` curat în mobil. |
| `getMediaRelations(id)` | `/api/media/:id/relations` | `GET` | `/api/media/:id/relations` | ✅ Conform | Răspunsul `{ relations: [...] }` este deserializat în `List<MediaRelation>`. |
| `getMediaCharacters(id)` | `/api/media/:id/characters` | `GET` | `/api/media/:id/characters` | ✅ Conform | Răspunsul `{ characters: [...] }` oferă personajele principale/secundare și actorii vocali. |
| `getSimilarMedia(id)` | `/api/media/:id/similar` | `GET` | `/api/media/:id/similar` | ✅ Conform | Extrage `similarItems[].item` în mod corect. |
| `getWatchOrder(id)` | `/api/media/:id/watch-order`| `GET` | `/api/media/:id/watch-order`| ✅ Conform | Deserializat în `WatchOrderGuide`. |
| `voteWatchOrderPreset` | `/api/media/watch-order/presets/:id/vote`| `POST` | `/api/media/watch-order/presets/:id/vote` | ✅ Conform | Suportă atât `vote: 1 / -1` cât și `voteType: UP / DOWN`. |
| `reportWatchOrderPreset`| `/api/media/watch-order/presets/:id/report`| `POST` | `/api/media/watch-order/presets/:id/report` | ✅ Conform | Raportare salvată persistent. |
| `createWatchOrderPreset`| `/api/media/:id/watch-order/presets` | `POST` | `/api/media/:id/watch-order/presets` | ✅ Conform | Status HTTP 201 Created validat. |
| `getCategories()` | `/api/categories` | `GET` | `/api/categories` | ✅ Conform | Rafturi tematice dinamice: Shonen, Dark Fantasy, Psychological, Sci-Fi, Romance. |
| `getNews()` | `/api/news` | `GET` | `/api/news` | ✅ Conform | Câmpurile `{ total, count, articles, items }` conțin articole agregate live din RSS. |
| `getWatchlist()` | `/api/watchlist` | `GET` | `/api/watchlist` | ✅ Conform | Necesită Bearer token; sincronizat cu baza de date D1. |
| `upsertWatchlistItem` | `/api/watchlist` | `POST` | `/api/watchlist` | ✅ Conform | Trimitere `mediaId`, `status`, `score`, `progressEpisodes`, `notes`, `startedAt`, `completedAt`. |
| `deleteWatchlistItem` | `/api/watchlist/:mediaId` | `DELETE` | `/api/watchlist/:mediaId` | ✅ Conform | Ștergere confirmată prin `{ success: true }`. |
| `getProfile()` | `/api/user/profile` | `GET` | `/api/user/profile` | ✅ Conform | Răspuns `{ profile }` mapat direct în `UserProfileData`. |
| `updateProfile` | `/api/user/profile` | `PUT` | `/api/user/profile` | ✅ Conform | Validează sanitizarea, lungimea și cooldown-ul de 14 zile la handle. |
| `resolveIdentifier` | `/api/auth/resolve-identifier` | `POST` | `/api/auth/resolve-identifier` | ✅ Conform | Rezolvă un @username în email pentru autentificarea unificată. |
| `checkUsernameAvailable`| `/api/auth/check-username` | `GET` | `/api/auth/check-username` | ✅ Conform | Query `username`, `excludeUserId`, `email`. |
| `signUp / registerUser`| `/api/auth/register-user` | `POST` | `/api/auth/register-user` | ✅ Conform | Sincronizează profilul inițial în baza de date D1. |

---

## 5. Ghid de Rulare & Comenzi Utile

### 5.1 Pornire Backend API (Cloudflare Workers)
```bash
# Pornire Wrangler în mod dezvoltare locală (port 8787):
npm run dev:api

# Deploy pe Cloudflare Workers Edge:
npm run deploy:api
```

### 5.2 Pornire Aplicație Mobilă Flutter
```bash
# Rulare pe telefon fizic conectat prin USB:
npm run dev:mobile:phone

# Rulare pe emulator Android:
npm run dev:mobile:emulator

# Reverse port forwarding pentru dispozitive fizice (port 8787):
npm run mobile:reverse
```

### 5.3 Rulare Teste & Verificare
```bash
# Analiză statică Flutter:
cd apps/mobile && flutter analyze

# Rulare teste unitare Flutter:
cd apps/mobile && flutter test
```

