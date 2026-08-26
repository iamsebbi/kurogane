# 🛠️ Kurogane — Audit Complet & Plan de Optimizare

Acest document sintetizează rezultatele unui audit amănunțit al proiectului: securitate, structură, dependențe, performanță și bune practici.

---

## 📋 Tabel Sinoptic

| Nr. | Categorie | Titlu | Severitate | Efort |  Stare |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **S1** | 🔴 Securitate | Credențiale Firebase hardcodate în cod sursă | 🔴 Critic | ~10 min | ✅ Finalizat |
| **S2** | 🔴 Securitate | CORS deschis complet (`cors()` fără origin) | 🔴 Critic | ~5 min | ✅ Finalizat |
| **S3** | 🔴 Securitate | Lipsa headerelor HTTP de securitate (`helmet`) | 🔴 Critic | ~5 min | ✅ Finalizat |
| **S4** | 🔴 Securitate | Token-uri de autentificare nesemnate — fără JWT real | 🔴 Critic | ~30 min | ✅ Finalizat |
| **S5** | 🟠 Securitate | OTP salt hardcodat, fără rotație | 🟠 Ridicat | ~5 min | ✅ Finalizat |
| **S6** | 🟠 Securitate | `express.json()` fără limită de body size | 🟠 Ridicat | ~2 min | ✅ Finalizat |
| **S7** | 🟠 Securitate | Lipsă handler pentru erori globale și crash-uri | 🟠 Ridicat | ~5 min | ✅ Finalizat |
| **S8** | 🟠 Securitate | User-Agent spoof în cererile către AniList | 🟡 Mediu | ~2 min | ✅ Finalizat |
| **R1** | 🧹 Repo | Fișiere binare mari în repository (1.5 GB `.exe`) | 🔴 Critic | ~2 min | ✅ Finalizat |
| **R2** | 🧹 Repo | `.gitignore` incomplet pentru Flutter/Dart | 🟠 Ridicat | ~2 min | ✅ Finalizat |
| **D1** | 📦 Dependențe | Dependențe web în `package.json` rădăcină | 🟡 Mediu | ~3 min | ✅ Finalizat |
| **D2** | 📦 Dependențe | `jsonwebtoken` instalat dar nefolosit | 🟡 Mediu | ~1 min | ✅ Finalizat |
| **D3** | 📦 Dependențe | Client Supabase (`supabase.ts`) — cod mort / dual-auth | 🟡 Mediu | ~10 min | ✅ Finalizat |
| **A1** | 🏗️ Arhitectură | Monolit `page.tsx` (2.250+ linii) — frontend web | 🟡 Mediu | ~30 min | ✅ Finalizat |
| **A2** | 🏗️ Arhitectură | Monolit `index.ts` (454 linii) — rute API inline | 🟡 Mediu | ~15 min | ✅ Finalizat |
| **A3** | 🏗️ Arhitectură | Directoare de date locale fragmentate (`data/` vs `src/data/`) | 🟡 Mediu | ~5 min | ✅ Finalizat |
| **A4** | 🏗️ Arhitectură | Persistență hibridă Supabase PostgreSQL + Offline JSON | 🟢 Cloud DB | ~30 min | ✅ Finalizat |
| **P1** | ⚡ Performanță | Cache în memorie fără limită superioară strictă | 🟡 Mediu | ~10 min | ✅ Finalizat |
| **P2** | ⚡ Performanță | `saveData()` sincron — blochează Event Loop-ul | 🟡 Mediu | ~10 min | ✅ Finalizat |
| **T1** | 🧪 Testare | Lipsă suite de teste unitare/integrare | 🟡 Mediu | ~2-4h | ✅ Finalizat |
| **T2** | 🧪 Testare | Lipsă CI/CD pipeline | 🟡 Mediu | ~1h | ✅ Finalizat |

---

## 🔴 SECURITATE

### S1. Credențiale Firebase Hardcodate în Cod Sursă

**Fișiere afectate:**
- `apps/web/src/lib/firebase.ts` (linia 16–21): chei API Firebase hardcodate ca fallback-uri.
- `apps/web/.env.local` (liniile 1–7): fișier `.env.local` cu chei reale comis în Git.
- `apps/mobile/lib/core/firebase/firebase_options.dart` (liniile 20–45): chei pentru web, Android, iOS hardcodate.

**Risc:** Cheile Firebase API nu sunt secrete critice în sine (sunt publice pentru client-side SDK-uri Firebase), dar expunerea lor în repository-uri publice facilitează abuzul (consumarea cotei gratuite, spam pe autentificare). `.env.local` **nu ar trebui niciodată comis în Git**.

**Remediere:**
1. Adaugă `.env.local` și `.env` la `.gitignore` (dacă nu sunt deja ignorate efectiv).
2. Creează un `.env.example` cu valori placeholder documentate.
3. Pentru Flutter, generează `firebase_options.dart` prin `flutterfire configure` și adaugă-l la `.gitignore`, sau extrage cheile în variabile de mediu la build-time.

---

### S2. CORS Deschis Complet

**Fișier:** `apps/api/src/index.ts` (linia 40):
```typescript
app.use(cors()); // Orice origin este permis
```

**Risc:** Orice site web terț poate face cereri către API-ul Kurogane din browser-ul utilizatorului, inclusiv endpoint-urile autentificate (watchlist, profil). Acest lucru facilitează atacuri CSRF.

**Remediere:**
```typescript
app.use(cors({
  origin: [
    'http://localhost:3000',
    'https://kurogane.vercel.app',
    // Alte domenii de producție
  ],
  credentials: true,
}));
```

---

### S3. Lipsa Headerelor HTTP de Securitate

**Fișier:** `apps/api/src/index.ts` — Niciun middleware de security headers.

Nu există `helmet` sau echivalent. Headerele lipsă includ:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Strict-Transport-Security` (HSTS)
- `X-XSS-Protection`
- `Content-Security-Policy`

**Remediere:**
```bash
npm install helmet --workspace=apps/api
```
```typescript
import helmet from 'helmet';
app.use(helmet());
```

---

### S4. Token-uri de Autentificare Nesemnate

**Fișier:** `apps/api/src/services/db-persistent.ts` → `verifyToken()` (liniile 67–129).

Token-ul din `Authorization: Bearer <token>` **nu este verificat criptografic**. Funcția `verifyToken()` parsează token-ul textual (ex: `fb-token:email@x.com:username`) fără semnătură sau secret — oricine care cunoaște formatul poate forja un token valid.

**Risc 🔴:** Un atacator poate accesa/modifica orice cont doar trimițând:
```
Authorization: Bearer fb-token:victima@email.com:victim
```

**Pachetul `jsonwebtoken` este instalat dar complet nefolosit.**

**Remediere:**
1. Implementează semnarea JWT cu `jsonwebtoken` (pachet deja instalat) folosind un `JWT_SECRET` din variabile de mediu.
2. Alternativ, validează Firebase ID Tokens pe server folosind Firebase Admin SDK (`firebase-admin`), care verifică semnătura și expirarea token-ului.

---

### S5. OTP Salt Hardcodat

**Fișier:** `apps/api/src/services/resend.ts` (linia 9):
```typescript
const OTP_SALT = process.env.OTP_SALT || 'kurogane_otp_security_salt_2026';
```

**Risc:** Dacă variabila de mediu `OTP_SALT` nu e setată, toți hash-urile OTP folosesc un salt static cunoscut din codul sursă. Un atacator cu acces la cod poate precalcula hash-uri OTP.

**Remediere:** Elimină valoarea de fallback și forțează setarea variabilei:
```typescript
const OTP_SALT = process.env.OTP_SALT;
if (!OTP_SALT) throw new Error('CRITICAL: OTP_SALT environment variable is not set.');
```

---

### S6. `express.json()` fără Limită de Body Size

**Fișier:** `apps/api/src/index.ts` (linia 41):
```typescript
app.use(express.json()); // Fără limită
```

**Risc:** Un atacator poate trimite un request JSON de sute de MB, epuizând memoria serverului (Denial of Service).

**Remediere:**
```typescript
app.use(express.json({ limit: '1mb' }));
```

---

### S7. Lipsă Handler Global pentru Erori și Crash-uri

**Fișier:** `apps/api/src/index.ts` — Nu există:
- Middleware global de error handling Express (cu 4 parametri: `err, req, res, next`).
- Handler `process.on('uncaughtException')` sau `process.on('unhandledRejection')` — o eroare neașteptată duce la crash fără logging.

**Remediere:**
```typescript
// Global Express error handler (ultima linie înainte de app.listen)
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error('[Unhandled Error]', err);
  res.status(500).json({ error: 'Eroare internă de server.' });
});

// Process-level safety net
process.on('uncaughtException', (err) => {
  console.error('[FATAL] Uncaught Exception:', err);
});
process.on('unhandledRejection', (reason) => {
  console.error('[FATAL] Unhandled Rejection:', reason);
});
```

---

### S8. User-Agent Spoof în Cererile AniList

**Fișier:** `apps/api/src/services/anilist.ts` (liniile 5–11):
```typescript
export const ANILIST_REQUEST_HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)...',
  Origin: 'https://anilist.co',
  Referer: 'https://anilist.co/',
};
```

**Observație:** Se simulează un browser real pentru a accesa API-ul AniList. Acest lucru nu este un risc de securitate pentru Kurogane, dar încalcă termenii de utilizare AniList și riscă bannarea IP-ului.

**Recomandare:** Folosește un `User-Agent` onest: `Kurogane/0.1.0 (https://kurogane.app)`. API-ul public AniList nu necesită headere false.

---

## 🧹 IGIENA REPOSITORY-ULUI

### R1. Fișiere Binare Mari în Repository

Fișiere detectate în rădăcina proiectului (necomise încă, dar neignorate):
- `android-studio-quail3-patch1-windows.exe` — **~1.5 GB**
- `dart-code-3.140.0.vsix` — **~16.6 MB**

**Risc:** Dacă sunt comise accidental (`git add .`), repository-ul devine inutilizabil. Git nu este conceput pentru fișiere binare mari.

---

### R2. `.gitignore` Incomplet

Lipsesc reguli esențiale pentru:
- Fișiere binare: `*.exe`, `*.vsix`, `*.apk`, `*.aab`
- Artefacte Flutter: `.dart_tool/`, `build/`, `.flutter-plugins*`
- Baze de date locale: `*.db`, `*.sqlite`
- `apps/web/.env.local` (deși `.env.local` e listat generic, confirmarea e necesară)

**Adăugări recomandate în `.gitignore`:**
```gitignore
# Binary Installers & Extensions
*.exe
*.msi
*.vsix
*.apk
*.aab

# Flutter / Dart ephemeral artifacts
apps/mobile/.dart_tool/
apps/mobile/build/
apps/mobile/.flutter-plugins
apps/mobile/.flutter-plugins-dependencies
apps/mobile/package_config.json
apps/mobile/package_graph.json

# Database files
*.db
*.sqlite

# Firebase generated options (conțin chei)
# apps/mobile/lib/core/firebase/firebase_options.dart
```

---

## 📦 DEPENDENȚE

### D1. Dependențe Web în `package.json` Rădăcină

Fișier: `package.json` (rădăcină, liniile 28–32):
```json
"dependencies": {
  "@gsap/react": "^2.1.2",
  "firebase": "^12.17.1",
  "gsap": "^3.15.0"
}
```

Acestea sunt pachete specifice frontend-ului web și nu ar trebui să fie în rădăcina monorepo-ului. Ar trebui mutate în `apps/web/package.json`.

---

### D2. `jsonwebtoken` — Instalat dar Nefolosit

Fișier: `apps/api/package.json` — `jsonwebtoken` și `@types/jsonwebtoken` sunt listate ca dependențe, dar nu sunt importate sau folosite nicăieri în codul API. Ori se implementează JWT-uri reale (vezi S4), ori se elimină pachetul.

---

### D3. Client Supabase — Cod Mort / Autentificare Duală

Fișier: `apps/web/src/lib/supabase.ts`:
- Conține un client Supabase complet implementat manual (fetch-uri directe, fără `@supabase/supabase-js` real).
- `@supabase/supabase-js` este listat în `apps/web/package.json` dar nu pare importat efectiv.
- Proiectul pare să fi migrat de la Supabase la Firebase pentru autentificare, dar codul Supabase a rămas.

**Recomandare:** Dacă Firebase este soluția de auth finală, elimină `supabase.ts` și dependența `@supabase/supabase-js` din `apps/web/package.json` pentru a evita confuzia.

---

## 🏗️ ARHITECTURĂ & STRUCTURĂ

### A1. Monolit Frontend — `page.tsx` (2.250+ linii)

**Fișier:** `apps/web/src/app/page.tsx` — **109 KB**, peste 2.250 de linii într-un singur fișier.

**Componente recomandate pentru extragere** în `apps/web/src/components/home/`:
1. `HeroFeaturedCarousel.tsx` — Sliderul principal cu GSAP.
2. `SeasonalShelfRow.tsx` — Rândurile orizontale de carduri media.
3. `SearchFilterDrawer.tsx` — Panoul lateral de filtre avansate.
4. `NewsFeedSection.tsx` — Grila de știri anime/manga.
5. `MediaQuickPreviewModal.tsx` — Previzualizare rapidă la click pe card.

**Alte fișiere mari de monitorizat:**
- `apps/web/src/components/AuthModal.tsx` — 45 KB
- `apps/web/src/app/media/page.tsx` — 40 KB
- `apps/web/src/app/profile/page.tsx` — 33 KB
- `apps/web/src/app/media/[id]/page.tsx` — 31 KB
- `apps/mobile/lib/views/profile_screen.dart` — 44 KB
- `apps/mobile/lib/views/media_detail_screen.dart` — 34 KB

---

### A2. Monolit Backend — `index.ts` (454 linii)

**Fișier:** `apps/api/src/index.ts` — toate endpoint-urile definite inline pe instanța `app`.

**Structură recomandată (`apps/api/src/routes/`):**
```text
apps/api/src/
├── middleware/
│   ├── auth.middleware.ts      # authenticateUser()
│   └── error-handler.ts       # Global error handler
├── routes/
│   ├── auth.routes.ts          # /api/auth/* (login, register, OTP)
│   ├── user.routes.ts          # /api/user/profile
│   ├── watchlist.routes.ts     # /api/watchlist
│   ├── media.routes.ts         # /api/media/:id, /api/media/:id/similar
│   ├── search.routes.ts        # /api/search
│   ├── franchise.routes.ts     # /api/media/:id/watch-order
│   ├── news.routes.ts          # /api/news
│   └── homepage.routes.ts      # /api/homepage, /api/health
└── index.ts                    # Bootstrap, CORS, helmet, rate limiter, app.use()
```

---

### A3. Directoare de Date Locale Fragmentate

Fișierele JSON locale sunt distribuite în 3 locuri:
- `apps/api/data/` (anilist-cache, news, users, watchlist)
- `apps/api/src/data/` (media-seed, tag-taxonomy)
- Rădăcina proiectului (`anime-offline-database-minified.json`)

**Recomandare:** Unificare în `apps/api/data/` cu constante centralizate pentru rezolvarea căilor.

---

### A4. Persistență pe Fișiere JSON — Nu Scalează

Datele utilizatorilor (profile, watchlist-uri) sunt persistate prin `fs.writeFileSync()` pe disc, sincron, la fiecare modificare. Acest lucru funcționează pentru dezvoltare dar:
- **Nu suportă concurență** (doi utilizatori scriind simultan pot corupe fișierul).
- **Nu suportă multi-instanță** (deploy pe mai multe instanțe pierde datele).

Soluția pe termen lung (conform `ROADMAP.md`): migrare la **Prisma + SQLite/PostgreSQL**.

---

## ⚡ PERFORMANȚĂ

### P1. Cache-uri în Memorie fără Limită Strictă

**Fișiere:**
- `apps/api/src/services/db.ts`: `searchCache` cu `maxCacheSize = 500`, dar `similarityCache` și `fuzzyWordCache` cresc nelimitat.
- `apps/api/src/services/rate-limiter.ts`: cleanup la 5 minute, dar stocarea este nelimitată.

**Recomandare:** Implementează evicție LRU cu dimensiune maximă pe toate cache-urile, sau folosește o bibliotecă precum `lru-cache`.

---

### P2. `saveData()` Sincron — Blochează Event Loop-ul

**Fișier:** `apps/api/src/services/db-persistent.ts` (liniile 54–62):
```typescript
fs.writeFileSync(WATCHLIST_FILE, JSON.stringify(...), 'utf-8');
fs.writeFileSync(USERS_FILE, JSON.stringify(...), 'utf-8');
```

Fiecare update de watchlist/profil blochează Event Loop-ul Express pe durata scrierii pe disc (serializare JSON + I/O sincron).

**Remediere:** Înlocuiește cu `fs.promises.writeFile()` (asincron) sau batching (scrie la intervale fixe, nu la fiecare operațiune).

---

## 🧪 TESTARE & CI/CD

### T1. Lipsă Suite de Teste

Nu există fișiere de test unitare sau de integrare pentru:
- Motorul de căutare și indexare (`db.ts`)
- Logica de autentificare și OTP
- Validarea inputurilor pe rute API
- Componente React sau ecrane Flutter

Există doar `test-search.ts` — un script de verificare manuală, nu un framework de test.

**Recomandare:** Adaugă `vitest` sau `jest` pentru API + `@testing-library/react` pentru Web.

---

### T2. Lipsă CI/CD Pipeline

Nu există `.github/workflows/`, `Jenkinsfile`, `Dockerfile`, sau altă configurație de continuous integration.

**Recomandare minimă:** Un workflow GitHub Actions cu:
1. `npm install` + `npm run build` (verifică compilarea tuturor workspace-urilor)
2. `npm run lint` (verifică stilul codului)
3. Run tests (când vor exista)

---

## 🔄 ORDINE RECOMANDATĂ DE IMPLEMENTARE

### Faza 1 — Securitate Critică (imediat)
1. **S2** — Restricționează CORS la origini specifice
2. **S3** — Instalează și configurează `helmet`
3. **S6** — Limitează body size pe `express.json()`
4. **S7** — Adaugă error handler global și process-level safety
5. **R1 + R2** — Actualizează `.gitignore` și elimină fișierele binare

### Faza 2 — Securitate Avansată (săptămâna curentă)
6. **S4** — Implementează JWT semnat sau Firebase Admin SDK verification
7. **S5** — Elimină OTP salt hardcodat
8. **S1** — Mută credențialele în variabile de mediu și `.env.example`

### Faza 3 — Curățare și Structurare (săptămâna viitoare)
9. **D1** — Mută dependențele web din rădăcină
10. **D2 + D3** — Elimină codul mort (JWT nefolosit, Supabase abandonat)
11. **A2** — Modularizează rutele API
12. **A3** — Unifică directoarele de date
13. **P2** — Înlocuiește `writeFileSync` cu varianta asincronă

### Faza 4 — Scalabilitate (termen mediu)
14. **A1** — Modularizează `page.tsx` în componente
15. **P1** — Implementează cache LRU cu limite
16. **A4** — Migrează persistența la Prisma/SQLite
17. **T1 + T2** — Adaugă teste și CI/CD

---

*Document generat prin audit automat al codului sursă Kurogane. Ultima actualizare: 26 August 2026.*
