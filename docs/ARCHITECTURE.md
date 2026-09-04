# Kurogane — Arhitectură Tehnică & Documentație de Sistem

> Documentație tehnică completă pentru platforma **Kurogane**: monorepo, backend API (Node.js/Express), client mobil (Flutter/Dart), pachet de tipuri partajate (TypeScript) și auditul de integrare API <-> Mobile.

---

## 1. Prezentare Generală a Arhitecturii

Kurogane este o platformă modernă dedicată descoperirii, clasificării și monitorizării conținutului media pan-asiatic: **Anime** (Japonia), **Donghua** (China), **Aeni** (Coreea de Sud), **Manga**, **Manhwa**, **Manhua** și **Webtoons**.

Platforma este structurată ca un **npm workspaces monorepo**:

```text
kurogane/
├── apps/
│   ├── api/          # Backend Express + TypeScript, Inverted Index, Supabase & AniList
│   ├── mobile/       # Aplicație mobilă Flutter (Android, iOS) cu Riverpod & Firebase
│   └── web/          # Frontend Web Next.js 14 (App Router) + TailwindCSS
├── packages/
│   └── shared/       # Interfețe de domeniu TypeScript, constante și modele unificate
├── docs/             # Documentație tehnică și specificații de arhitectură
├── package.json      # Configurație workspace rădăcină & scripturi unificate
└── tsconfig.base.json# Configurație de bază TypeScript
```

---

## 2. Backend API (`apps/api`)

### 2.1 Tehnologii de Bază
- **Runtime:** Node.js (v18+)
- **Framework HTTP:** Express.js 4
- **Limbaj:** TypeScript 5.3 (compilare rapidă cu `esbuild`, dezvoltare cu `ts-node-dev`)
- **Securitate:** `helmet` (politici Cross-Origin), `cors` (politici restrictive per domeniu + bypass autorizat pentru clienți nativi/mobile), `bcryptjs`, `jsonwebtoken`, limitatoare de rată personalizate în memorie.
- **Bază de date & Persistență:**
  - *Primary Local Layer:* JSON storage persistent (`apps/api/data/`) cu flush asincron și atomic.
  - *Cloud Mirror / Cluster:* Supabase PostgreSQL via `@supabase/supabase-js` și Prisma ORM (`prisma/schema.prisma`).
  - *In-Memory Search:* Motor bazat pe Inverted Index cu dicționar de cuvinte și distanță Levenshtein.

### 2.2 Motorul de Căutare Inverted-Index
Aflat în `apps/api/src/services/db.ts`:
1. **Indexare Multi-Token:** Tokenizează titlurile (romaji, engleză, nativ, userPreferred) și sinonimele într-o hartă `Map<string, Set<number>>`.
2. **Rezolvitor de Acronime & Inițialisme:** Detectează automat prescurtări uzuale ale comunității (ex: `aot` -> *Attack on Titan*, `jjk` -> *Jujutsu Kaisen*, `fmab` -> *Fullmetal Alchemist: Brotherhood*, `mha` -> *My Hero Academia*).
3. **Fuzzy Matching Levenshtein:** Permite toleranță la greșeli de tipar (1 sau 2 caractere distanță în funcție de lungimea termenului), cu dicționar pre-indexat și cache LRU pentru tokeni.
4. **Filtrare Hibridă:** Permite combinarea filtrelor de tip media, format, an, sezon, stare, demografie, genuri multiple și micro-taguri.
5. **Cache cu Expirare (TTL):** Memorează rezultatele căutărilor frecvente timp de 5 minute cu eliminare automată LRU.

### 2.3 Taxonomie & Micro-Taguri
Definită în `apps/api/data/tag-taxonomy.json`:
- Clasifică automat conținutul în **37 de micro-taguri** tematice (ex: *Overpowered MC, Isekai, Anti-Hero, Xianxia, Cyberpunk, Post-Apocalyptic, Time Travel, Revenge, Dungeon/Towers*) pe baza analizei semantice a descrierilor, titlurilor și genurilor.
- Asociază automat demografiile (*Shounen, Seinen, Shoujo, Josei, Kids*).

### 2.4 Sistemul de Persistență & Replicare Cloud
Aflat în `apps/api/src/services/db-persistent.ts`:
- **Utilizatori (`users-db.json`):** Salvează profilele locale cu @handle, email, avatar, bio, pronume, genuri favorite și istoricul modificării numelui (restricție de 14 zile).
- **Liste de Urmărire (`watchlist-db.json`):** Salvează intrările de urmărire cu status, scor personal, episoade parcurse, notițe, dată de început și dată de finalizare.
- **Replicare Supabase:** Când variabilele `SUPABASE_URL` și `SUPABASE_SERVICE_ROLE_KEY` sunt configurate, orice mutație locală este replicată asincron în baza PostgreSQL din cloud. La pornire, serverul execută `syncFromSupabase()` pentru a recupera starea cloud.
- **Fallback Offline:** Dacă serverul rulează fără conexiune la cloud sau fără credențiale, funcționează 100% autonom pe baza fișierelor JSON locale.

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

În urma analizei exhaustive a codului sursă din `apps/api` și `apps/mobile`, s-au verificat contractele, DTO-urile, antetele și fluxurile de date:

### 4.1 Matricea de Conformitate a Endpoint-urilor

| Funcție Mobil (`ApiClient` / `AuthService`) | Endpoint Apelat | Metodă | Rută Corespondentă în API | Status Audit | Note |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `getHomepage()` | `/api/homepage` | `GET` | `homepage.routes.ts` (`/homepage`) | ✅ Conform | Câmpurile DTO (`featuredSeason`, `recentlyAired`, `newsBeta`, `recommendations`, `topAiring`, `topUpcoming`, `top100`) se mapează identic. |
| `searchMedia(...)` | `/api/search` | `GET` | `search.routes.ts` (`/`) | ✅ Conform | Parametrii de query (`q`, `type`, `format`, `status`, `demographic`, `genres`, `microTags`, `sortBy`, `minScore`, `limit`, `page`) sunt acceptați și procesați identic. |
| `getMediaById(id)` | `/api/media/:id` | `GET` | `media.routes.ts` (`/:id`) | ✅ Conform | Returnează `MediaItem` complet; 404 tratat cu `null` curat în mobil. |
| `getMediaRelations(id)` | `/api/media/:id/relations` | `GET` | `media.routes.ts` (`/:id/relations`) | ✅ Conform | Răspunsul `{ relations: [...] }` este deserializat în `List<MediaRelation>`. |
| `getSimilarMedia(id)` | `/api/media/:id/similar` | `GET` | `media.routes.ts` (`/:id/similar`) | ✅ Conform | Extrage `similarItems[].item` în mod corect. |
| `getWatchOrder(id)` | `/api/media/:id/watch-order`| `GET` | `media.routes.ts` (`/:id/watch-order`)| ✅ Conform | Deserializat în `WatchOrderGuide`. |
| `voteWatchOrderPreset` | `/api/media/watch-order/presets/:id/vote`| `POST` | `media.routes.ts` | ✅ Conform | Validat 1/-1, gestiune corectă a erorilor de auto-vot (403). |
| `reportWatchOrderPreset`| `/api/media/watch-order/presets/:id/report`| `POST` | `media.routes.ts` | ✅ Conform | Raportare salvată persistent. |
| `createWatchOrderPreset`| `/api/media/:id/watch-order/presets` | `POST` | `media.routes.ts` | ✅ Conform | Status HTTP 201 Created validat. |
| `getNews()` | `/api/news` | `GET` | `news.routes.ts` (`/`) | ✅ Conform | Câmpurile `articles[].{id, title, category, tagBadge, summary, imageUrl, date, readTime, source}` se potrivesc 100%. |
| `getWatchlist()` | `/api/watchlist` | `GET` | `watchlist.routes.ts` (`/`) | ✅ Conform | Necesită Bearer token; returnează lista îmbogățită cu `mediaItem`. |
| `upsertWatchlistItem` | `/api/watchlist` | `POST` | `watchlist.routes.ts` (`/`) | ✅ Conform | Trimitere `mediaId`, `status`, `score`, `progressEpisodes`, `notes`, `startedAt`, `completedAt`. |
| `deleteWatchlistItem` | `/api/watchlist/:mediaId` | `DELETE` | `watchlist.routes.ts` (`/:mediaId`) | ✅ Conform | Ștergere confirmată prin `{ success: true }`. |
| `getProfile()` | `/api/user/profile` | `GET` | `user.routes.ts` (`/profile`) | ✅ Conform | Răspuns `{ profile }` mapat direct în `UserProfileData`. |
| `updateProfile` | `/api/user/profile` | `PUT` | `user.routes.ts` (`/profile`) | ✅ Conform | Validează sanitizarea, lungimea și cooldown-ul de 14 zile. |
| `resolveIdentifier` | `/api/auth/resolve-identifier` | `POST` | `auth.routes.ts` (`/resolve-identifier`)| ✅ Conform | Protecție împotriva atacurilor de sincronizare temporală (timing attack dummy hash). |
| `checkUsernameAvailable`| `/api/auth/check-username` | `GET` | `auth.routes.ts` (`/check-username`) | ✅ Conform | Query `username`, `excludeUserId`, `email`. |
| `signUp / registerUser`| `/api/auth/register-user` | `POST` | `auth.routes.ts` (`/register-user`) | ✅ Conform | Sincronizează profilul inițial în DB după crearea Firebase. |

### 4.2 Verificarea Fluxului de Autentificare & Securitate
- **Mecanism Token:** Mobilul apelează `FirebaseAuth.instance.currentUser?.getIdToken()` și îl trimite ca antet `Authorization: Bearer <token>`.
- **Verificare Backend:**
  1. Încearcă verificarea cu cheia simetrică locală (`jwt.verify(token, JWT_SECRET)`).
  2. Dacă eșuează (fiind token Google Firebase), verifică criptografic prin `firebaseAdmin.auth().verifyIdToken(token)`.
  3. În cazul în care serverul rulează în regim offline sau certurile Google sunt inaccesibile temporar, există fallback-ul de securitate prin decodarea sigură a payload-ului JWT Google (`securetoken.google.com`) pentru extragerea `uid` și `email`.
- **Concluzie:** Handshake-ul de autentificare este complet robust și funcționează atât online cât și în mod de dezvoltare locală.

### 4.3 Componente Identificate ca Învechite / Orfane
- Fișierele `apps/mobile/lib/widgets/watch_order_tree_view.dart` și `apps/mobile/lib/widgets/watch_order_proposal_sheet.dart` au rămas neutilizate în interfață deoarece ecranul de detalii serie a fost migrat complet la noul sistem nativ de `MediaRelationsView` (Prequel/Sequel dinamice). Acestea pot fi păstrate ca arhivă sau eliminate dacă se dorește curățarea strictă a codului mort.

---

## 5. Ghid de Rulare & Comenzi Utile

### 5.1 Pornire Backend API
```bash
# Pornire în mod dezvoltare cu auto-reload
npm run dev:api

# Sau direct din directorul aplicației
cd apps/api
npm run dev
```

### 5.2 Pornire Aplicație Mobilă Flutter
```bash
cd apps/mobile

# Rulare pe emulator Android sau dispozitiv conectat prin USB
flutter run

# În cazul în care dispozitivul fizic e conectat prin USB, redirecționează portul:
adb reverse tcp:4000 tcp:4000
```

### 5.3 Rulare Teste & Verificare
```bash
# Teste unitare API
npm test --workspace=apps/api

# Analiză statică Flutter
cd apps/mobile
flutter analyze
```
