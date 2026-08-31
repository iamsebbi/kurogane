# Audit Complet & Plan de Remediere: Comunicarea Mobile ↔ API ↔ Supabase / Firebase / Render

Acest document prezintă un audit end-to-end al modului în care **apps/mobile** (Flutter) și **apps/api** (Node.js/Express) comunică între ele și cu serviciile externe (Supabase PostgreSQL, Firebase Auth, Render hosting, Resend email, AniList GraphQL). Fiecare secțiune identifică probleme concrete și propune remedierea conform **procedurilor standard din industrie**.

---

## 📌 Sinteză Executivă

> **12 probleme critice și 8 probleme de severitate medie au fost identificate.**
> Cele mai grave afectează direct persistența datelor (watchlist gol după delogare), securitatea autentificării (token-uri neverificate criptografic pe backend) și fiabilitatea comunicării pe dispozitive mobile / emulatoare în producție.

---

## 🔴 Probleme Critice (Severitate: CRITICAL)

### C1. Firebase ID Tokens NU sunt verificate criptografic pe server

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/src/services/db-persistent.ts` (L168-L249) |
| **Problemă** | API-ul **nu are `firebase-admin` SDK instalat** și nu apelează `admin.auth().verifyIdToken()`. Când Flutter trimite un Firebase ID Token real (JWT semnat de Google), backend-ul încearcă să-l decodeze cu `jwt.verify(token, JWT_SECRET)` — dar secretul local ≠ cheia Google, deci verificarea eșuează. Codul cade în fallback-ul care face un `Buffer.from(parts[1], 'base64').toString()` brut, **fără nicio verificare de semnătură**, extragând `sub` și `email` fără a valida dacă token-ul a fost emis de Firebase. |
| **Impact** | ⚠️ **Oricine poate forja un JWT cu structură `header.payload.signature`**, pune orice `email` și `sub` în payload, și backend-ul îl acceptă ca valid. Este un **bypass complet de autentificare**. |
| **Standard** | OWASP Authentication Cheat Sheet: „Tokens should always be verified against the issuer's public key." |

---

### C2. Fallback token `fb-token:email:displayName` — autentificare prin plaintext

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/mobile/lib/core/network/api_client.dart` (L40-47), `apps/api/src/services/db-persistent.ts` (L208-L213) |
| **Problemă** | Când `getIdToken()` expiră (timeout 1500ms), Flutter construiește un token `fb-token:user@email.com:DisplayName` în plaintext. Backend-ul acceptă acest string, extrage emailul, generează `userId = user-hex(email)` și autentifică utilizatorul **fără nicio dovadă criptografică**. |
| **Impact** | **Impersonare trivială**: un atacator poate trimite `Authorization: Bearer fb-token:victim@email.com:Hacker` și primește acces complet la contul victimei. Nu este nevoie de parolă, token Firebase, sau alt secret. |
| **Standard** | RFC 6750 (Bearer Token Usage): tokens must be cryptographically protected. |

---

### C3. POST / DELETE nu au mecanism de fallback URL (watchlist nu se salvează pe device)

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/mobile/lib/core/network/api_client.dart` (L233-L266) |
| **Problemă** | Metoda `_get()` implementează un ciclu de fallback pe `candidateBaseUrls` (`127.0.0.1:4000`, `10.0.2.2:4000`, `cloudBaseUrl`). Dar `upsertWatchlistItem()` și `deleteWatchlistItem()` apelează direct `_dio.post()` / `_dio.delete()` pe un singur URL. Pe emulator Android, `127.0.0.1` pointează la dispozitivul însuși → **Connection Refused**. |
| **Impact** | Actualizarea optimistă din `WatchlistNotifier` face UI-ul să pară funcțional, dar datele nu ajung niciodată la server. La relogare, watchlist-ul este gol. **Aceasta este cauza principală a bug-ului raportat de utilizator.** |
| **Standard** | Retry pattern (Microsoft Cloud Design Patterns). |

---

### C4. Mismatch de status în CHECK constraint Supabase

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/supabase/schema.sql` (L25), `packages/shared/src/types/media.ts` (L15) |
| **Problemă** | Schema Supabase acceptă: `'WATCHING', 'PLANNING', 'COMPLETED', 'PAUSED', 'DROPPED'`. Shared types și Flutter folosesc: `'WATCHING', 'PLAN_TO_WATCH', 'COMPLETED', 'ON_HOLD', 'DROPPED'`. Când Flutter trimite `PLAN_TO_WATCH` sau `ON_HOLD`, Supabase refuză inserarea cu `CHECK constraint violation`. |
| **Impact** | Datele cu aceste statusuri nu se persistă niciodată în Supabase PostgreSQL. Doar JSON-urile locale de pe server le rețin (pierdute la redeploy pe Render). |
| **Standard** | Schema Consistency — toate layerele aplicației trebuie să folosească aceleași valori enum. |

---

### C5. Identități userId fragmentate (Firebase UID vs. email hash)

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/src/services/db-persistent.ts` (L172-L242) |
| **Problemă** | Un utilizator conectat prin Firebase Auth are `userId = Firebase UID` (ex: `AbC123XyZ`). Dacă token-ul expiră și se generează fallback `fb-token:`, userId devine `user-${hex(email).slice(0,16)}`. `getUserWatchlist()` caută strict `item.userId === userId`. Datele salvate sub un format nu apar când se interoghează cu celălalt. |
| **Impact** | Utilizatorul își pierde watchlistul, profilul și istoricul fără explicație vizibilă. |
| **Standard** | Single canonical identity per user (Identity Management best practices). |

---

### C6. Fișierele JSON persistente se pierd la fiecare redeploy pe Render

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/src/services/db-persistent.ts` (L10-L12) |
| **Problemă** | `watchlist-db.json` și `users-db.json` sunt stocate în `data/` pe filesystem-ul container-ului Render. Render Free Tier folosește **ephemeral filesystem** — la fiecare deploy sau restart, fișierele sunt șterse. `syncFromSupabase()` la startup restaurează din Supabase, dar dacă Supabase nu a primit datele (din cauza C4), restaurarea returnează date incomplete sau goale. |
| **Impact** | Pierdere completă de date la fiecare redeploy dacă Supabase sync a eșuat. |
| **Standard** | Twelve-Factor App: „Processes are stateless and share-nothing. Persistent data should be stored in a stateful backing service." |

---

## 🟠 Probleme de Severitate Medie (MEDIUM)

### M1. Profilul utilizator (bio, pronume) — local-only pe mobil

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/mobile/lib/providers/user_profile_provider.dart` (L24-L49) |
| **Problemă** | `UserProfileNotifier.updateProfile()` scrie doar în `SharedPreferences` locale. Nu apelează `PUT /api/user/profile`. La delogare, schimbare de dispozitiv, sau reinstalare, datele sunt pierdute. |
| **Standard** | Backend-as-source-of-truth pattern. |

### M2. `AuthService._dio` nu are fallback URL

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/mobile/lib/services/auth_service.dart` (L22-L31) |
| **Problemă** | `AuthService` creează un `Dio` propriu cu `baseUrl: ApiConstants.baseUrl` (hard `127.0.0.1:4000` pe Android debug). Nu folosește `candidateBaseUrls` fallback. Endpoint-urile `/api/auth/resolve-identifier` și `/api/auth/register-user` eșuează pe emulator. |
| **Impact** | Rezolvarea username → email și sincronizarea contului la înregistrare eșuează silențios. |

### M3. Supabase replication fire-and-forget (fără retry, fără error propagation)

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/src/services/db-persistent.ts` (L398-L431, L301-L321) |
| **Problemă** | Replicarea către Supabase se face în IIFE async `(async () => { ... })()` fără `await`, fără retry, fără queue. Dacă eșuează (rețea, constraint), datele rămân doar în JSON local. Utilizatorul primește `200 OK` deși datele nu au ajuns în baza de date cloud. |
| **Standard** | Outbox Pattern sau Transactional Outbox pentru eventual consistency. |

### M4. RLS (Row Level Security) permisiv pe Supabase

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/supabase/schema.sql` (L41-L62) |
| **Problemă** | Politicile RLS permit `SELECT` public pe toate rândurile (`USING (true)`). Orice client cu cheia anon poate citi toate profilurile, emailurile, și watchlist-urile. Politica `FOR ALL` cu `USING (true) WITH CHECK (true)` permite orice operațiune la nivel `service_role`. |
| **Impact** | Dacă `SUPABASE_ANON_KEY` este folosită (codul preferă `SERVICE_ROLE_KEY` dar fallback-ul este anon), un client terț poate citi date sensibile. |
| **Standard** | Supabase Best Practices: RLS policies should restrict access to the row owner. |

### M5. `.env.example` incomplet — lipsesc variabile critice

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/.env.example` |
| **Problemă** | `.env.example` conține doar `PORT` și `RESEND_API_KEY`. Lipsesc: `JWT_SECRET`, `OTP_SALT`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `CORS_ORIGINS`, `NODE_ENV`. Dezvoltatorii noi nu vor ști ce variabile sunt necesare. |
| **Standard** | 12-Factor App: config through environment, documented in `.env.example`. |

### M6. Lipsa validării input pe PUT /api/user/profile

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/src/routes/user.routes.ts` (L14-L33) |
| **Problemă** | Endpoint-ul acceptă orice valoare pentru `username`, `bio`, `pronouns`, `avatarUrl`, `bannerUrl` fără sanitizare sau validare de lungime. Un atacator autentificat poate injecta XSS prin `bio` sau seta un `avatarUrl` la un URL malițios. |
| **Standard** | OWASP Input Validation Cheat Sheet. |

### M7. `parseFloat` / `parseInt` în watchlist route pe valori potențial non-string

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/src/routes/watchlist.routes.ts` (L34-L35) |
| **Problemă** | `parseFloat(score)` și `parseInt(progressEpisodes, 10)` sunt apelate pe valori din `req.body`. Dacă Flutter trimite un `number` (JSON nativ), `parseFloat(8.5)` funcționează. Dar `parseInt(0, 10)` returnează `0`, iar condiția `progressEpisodes ? parseInt(progressEpisodes, 10) : 0` evaluează `0` ca falsy → mereu returnează `0` chiar dacă Flutter trimite progres. |
| **Impact** | Progresul episoadelor setate de utilizator nu se salvează corect dacă valoarea este `0` (start de serie). |

### M8. Env loader duplicat între `index.ts` și `env.ts`

| Aspect | Detalii |
|--------|---------|
| **Fișiere** | `apps/api/src/index.ts` (L8-L30), `apps/api/src/services/env.ts` |
| **Problemă** | Aceeași logică de parsare `.env` este duplicată verbatim. `env.ts` este importat de `db-persistent.ts` (automat la load), iar `index.ts` refă parsarea. Ordinea de import poate cauza race conditions în care variabilele nu sunt setate la momentul în care `db-persistent.ts` le citește. |
| **Standard** | DRY (Don't Repeat Yourself) principle. |

---

## 🟡 Observații & Recomandări Suplimentare

| # | Observație | Recomandare |
|---|-----------|-------------|
| O1 | Prisma schema definită dar **nefolosită** — codul folosește JSON files + Supabase | Eliminarea dependinței `@prisma/client` + `prisma` sau migrarea completă pe Prisma |
| O2 | Google OAuth `serverClientId` hardcodat în `auth_service.dart` (L231, L247) | Externalizare prin `String.fromEnvironment()` |
| O3 | AniList `client_id` hardcodat (`20894`) în `profile_screen.dart` (L1766) | Externalizare în constants |
| O4 | `usesCleartextTraffic="true"` în AndroidManifest | Acceptabil doar în debug; în release, dezactivare + network security config |
| O5 | Rate limiter in-memory — nu rezistă la scaleout | OK pentru single-instance Render, dar documentare limitare |
| O6 | Supabase heartbeat la 12h — free tier pauzează la 1 săptămână inactivitate | Reducere interval la 4h sau webhook Render health check |
| O7 | `bcryptjs` listat ca dependență dar **nefolosit** — parolele sunt gestionate de Firebase | Eliminare din `package.json` |
| O8 | Logurile expun coduri OTP în demo mode | OK în dev, dar condiționare strictă pe `NODE_ENV !== 'production'` |

---

## 🛠️ Plan de Remediere Structurat pe Componente

### Componenta 1: Securitate Autentificare (C1 + C2)

#### `apps/api/src/services/db-persistent.ts`
- Instalare `firebase-admin` SDK
- Implementare `admin.auth().verifyIdToken()` ca metodă primară de verificare a Firebase ID Tokens
- Eliminare acceptare `fb-token:*` plaintext — înlocuire cu un token temporar semnat local (JWT cu TTL scurt) emis după verificarea Firebase
- Fallback pe JWT-uri semnate local (`jwt.verify`) rămâne ca secundar

#### `apps/mobile/lib/core/network/api_client.dart`
- Eliminare construcție `fb-token:email:displayName`
- Implementare retry mai agresiv pe `getIdToken()` (3s timeout cu 1 retry) înainte de a abandona
- Dacă token-ul Firebase este complet indisponibil, redirecționare la ecranul de login (nu autentificare fake)

#### `apps/api/package.json`
- Adăugare `firebase-admin` în dependencies

---

### Componenta 2: Comunicare Rețea Mobile (C3 + M2)

#### `apps/mobile/lib/core/network/api_client.dart`
- Implementare metode private generice `_post()` și `_delete()` cu aceeași logică de fallback URL ca `_get()`
- `upsertWatchlistItem()` și `deleteWatchlistItem()` vor folosi `_post()` / `_delete()`
- Propagare header-elor de autorizare pe fiecare candidat fallback Dio

#### `apps/mobile/lib/services/auth_service.dart`
- Refactorizare `_dio` pentru a folosi `candidateBaseUrls` fallback

---

### Componenta 3: Schema Supabase & Normalizare Status (C4)

#### `apps/api/supabase/schema.sql`
- Actualizare CHECK constraint: `CHECK (status IN ('WATCHING', 'PLAN_TO_WATCH', 'PLANNING', 'COMPLETED', 'ON_HOLD', 'PAUSED', 'DROPPED'))`

#### `apps/api/src/services/db-persistent.ts`
- Adăugare funcție `normalizeWatchlistStatus()` care mapează `PLANNING → PLAN_TO_WATCH` și `PAUSED → ON_HOLD` la nivel de API
- Aplicare la `upsertWatchlistItem()`, `syncFromSupabase()`, `getUserWatchlist()`

---

### Componenta 4: Identitate Unificată (C5)

#### `apps/api/src/services/db-persistent.ts`
- `getUserWatchlist()`: căutare nu doar pe `userId`, ci și pe toate identitățile asociate aceluiași `email`
- Adăugare tabelă de alias-uri sau index secundar pe email în structura users Map
- La `verifyToken()`: dacă găsim user existent cu același email dar alt ID, unificare pe ID-ul canonic

---

### Componenta 5: Persistență Cloud Fiabilă (C6 + M3)

#### `apps/api/src/services/db-persistent.ts`
- Înlocuire IIFE fire-and-forget cu un micro-queue de replicare (retry 3x cu backoff exponențial)
- La startup, `syncFromSupabase()` devine obligatoriu (await) — datele Supabase sunt source of truth
- Dacă Supabase sync eșuează la startup, server-ul pornește dar logează warning critic

---

### Componenta 6: Sincronizare Profil Mobile ↔ API (M1)

#### `apps/mobile/lib/providers/user_profile_provider.dart`
- `updateProfile()` va apela `PUT /api/user/profile` prin `ApiClient`
- La login (init), va interoga `GET /api/user/profile` și va popula starea locală

#### `apps/mobile/lib/core/network/api_client.dart`
- Adăugare metode `getProfile()` și `updateProfile()`

---

### Componenta 7: Securizare RLS & Cleanup (M4 + M5 + M6 + M8)

#### `apps/api/supabase/schema.sql`
- Restricționare politici RLS: `SELECT` pe watchlist doar pentru rândurile proprii (`user_id = auth.uid()`)
- Sau, dacă se folosește doar `service_role_key`, documentare clară că anon key nu trebuie expusă

#### `apps/api/.env.example`
- Adăugare toate variabilele necesare cu comentarii

#### `apps/api/src/routes/user.routes.ts`
- Validare și sanitizare input pe `username` (lungime, caractere), `bio` (max 500 chars), `avatarUrl` (URL valid)

#### `apps/api/src/index.ts`
- Eliminare env loader duplicat, folosire doar `import './services/env'`

---

## 🧪 Plan de Verificare

### Teste Automate
```bash
# 1. Build API
cd apps/api && npm run build

# 2. Start API și verificare health
npm run dev
# GET http://localhost:4000/api/health → 200 OK

# 3. Test watchlist round-trip
# POST /api/watchlist cu status PLAN_TO_WATCH → verificare 200
# GET /api/watchlist → verificare item prezent
# DELETE /api/watchlist/:mediaId → verificare 200
```

### Verificare Manuală
- Test pe emulator Android: POST watchlist → logout → login → verificare watchlist persistent
- Verificare consola Supabase: datele apar în tabelele `users` și `watchlist`
- Test cu token Firebase real: verificare autentificare criptografică funcțională
- Test fallback URL: oprire server local → verificare comutare pe cloud URL

---

## 📊 Matrice de Prioritizare & Efort

| Prioritate | Problema | Risc | Efort Estimat |
|-----------|---------|------|----------------|
| 🔴 **P0** | C1 + C2: Firebase tokens neverificate + plaintext auth | **Securitate critică** | ~4h |
| 🔴 **P0** | C3: POST/DELETE fără fallback URL (Watchlist dispare) | **Data loss** | ~1h |
| 🔴 **P0** | C4: CHECK constraint mismatch în Supabase | **Data loss** | ~30min |
| 🔴 **P1** | C5: userId fragmentat (Firebase vs Hex) | **Data inconsistency** | ~2h |
| 🔴 **P1** | C6: Ephemeral filesystem pe Render | **Data loss la deploy** | ~1h |
| 🟠 **P2** | M1-M8: Profile sync, input validation, .env cleanup | **UX & mentenanță** | ~3h |
| 🟡 **P3** | O1-O8: Cleanup dependențe nefolosite & best practices | **Tech debt** | ~2h |
