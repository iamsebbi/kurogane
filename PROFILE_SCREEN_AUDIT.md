# 📌 Audit & Plan de Dinamizare – Ecran Profil Utilizator (`apps/mobile`)

Acest document inventariază elementele ecranului de profil ([`profile_screen.dart`](file:///d:/kurogane/apps/mobile/lib/views/profile_screen.dart)), valorile hardcodate sau statice identificate și soluțiile arhitecturale propuse pentru trecerea la **Zero Hardcoding** conform regulilor de bază ale proiectului Kurogane.

---

## 📋 Tabel Sinoptic: Elemente Hardcodate & Soluții

| Nr. | Element Afectat | Linii în Cod | Stare Curentă (Hardcodat / Mock) | Soluție Dinamică Propusă | Impact / Prioritate |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Bifă de Verificare (`sealCheck`)** | Liniile `530–535` | Apare necondiționat pentru orice utilizator conectat | Condiționare pe baza unui câmp din profil: `userProfile.isVerified` / rol (`admin`, `contributor`, `pro`) salvat în Supabase / API | 🟠 Mediu (Identitate) |
| **2** | **Cover Banner Implicit** | Liniile `113–120`, `460–475`, `524–590` | URL Unsplash extern hardcodat | ✅ **Finalizat**: Înlocuit cu container nativ Liquid Glass (gradient atmosferic `bgAccent`/`bgPrimary`, orbi ambientali `accentPrimary` & `brandHighlight`) | 🟢 Rezolvat |
| **3** | **Tag-uri Genuri Fallback** | Liniile `68–109`, `770–780` | `['#Shonen', ...]` hardcodat | ✅ **Finalizat**: Înlocuit cu algoritmul *Taste Score* (scor ponderat pe status & note) + zonă curată fără tag-uri fictive | 🟢 Rezolvat |
| **4** | **AniList OAuth `client_id`** | Linia `1434` | `client_id=20894` scris direct în URL | Extras în `AppConfig` / variabile de mediu (`.env`) sau furnizat dinamic de backend la `/api/integrations/config` | 🔴 Ridicat (Arhitectură) |
| **5** | **Limitare Rigidă Activitate Recentă** | Linia `1125` | `watchlist.take(6)` fix | Buton *„Vezi tot”* sau redirecționare spre tab-ul dedicat de Watchlist cu filtru preselectat | 🟢 Îmbunătățire UX |
| **6** | **Arhitectură Conturi Conectate** | Liniile `830–1039` | Doar AniList este implementat fizic în layout | Interfață modulară de integrări (ex. AniList, MyAnimeList, Kitsu) încărcată pe baza unui provider de servicii externe | 🟡 Arhitectură pe termen lung |
| **7** | **Texte Guest / Auth Gatekeeper** | Liniile `267–282` | Stringuri de prezentare funcționalități statice | Păstrate în sistem de localizare / constante sau transmise dinamic | 🟢 Mentenanță |
| **8** | **Text Bio Mock & UX Editare** | `user_profile_provider.dart`, `db-persistent.ts`, `edit_profile_screen.dart` | Texte mock default hardcodate în engleză/română | ✅ **Finalizat**: Eliminat orice mock, setat default `''`, adăugat contor live `0 / 500` și call-to-action discret pentru adăugare bio | 🟢 Rezolvat |

---

## 🔍 Detalii & Pași de Remediere

### 1. Bifa de Verificare Unică (`sealCheck`)
- **Problema actuală**:
  ```dart
  Icon(
    PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
    size: 20,
    color: context.accentPrimary,
  ),
  ```
  Este randată fix lângă `displayName`, ceea ce face ca orice cont nou creat să pară „verificat oficial”.
- **Plan de remediere**:
  1. În `@kurogane/shared` (`user.types.ts`), adăugăm `isVerified?: boolean` sau `badge?: 'verified' | 'creator' | 'mod' | 'pro'`.
  2. În backend (`apps/api`), persistăm acest câmp în Supabase (`users.is_verified`).
  3. În `profile_screen.dart`, afișăm bifa doar dacă:
     ```dart
     if (profileData.isVerified == true) ...[
       const SizedBox(width: 7),
       Icon(PhosphorIcons.sealCheck(PhosphorIconsStyle.fill), ...),
     ]
     ```

---

### 2. Imaginea de Cover (Banner Profil) (✅ Finalizat)
- **Implementare realizată**:
  - Eliminat complet URL-ul extern Unsplash `_defaultCoverImage`.
  - Banner-ul anime este detectat inteligent din primul anime din watchlist care conține `bannerImage`.
  - Când lista utilizatorului este goală sau nu există banner, se randează metoda nativă `_buildNativeLiquidGlassCover`:
    - Gradient atmosferic `context.bgAccent` -> `context.bgSurface` -> `context.bgPrimary`.
    - Două auri radiale ambientale Liquid Glass (`context.accentPrimary` la 0.16 opacitate și `context.brandHighlight` la 0.10 opacitate).
    - Compatibil automat atât cu Dark Mode cât și cu Light Mode (fundal curat, minimalist).

---

### 3. Tag-urile Fallback de Genuri (✅ Finalizat)
- **Implementare realizată**:
  - Eliminat complet fallback-ul hardcodat `['#Shonen', '#Fantasy', ...]`.
  - Integrat algoritmul **Taste Score (Punctaj Ponderat)**:
    - Exclude seriile `DROPPED`.
    - `PLAN_TO_WATCH`: +1 punct.
    - `COMPLETED` / `WATCHING`:
      - Scor ≥ 8.0: +10 puncte.
      - Scor 6.0 – 7.9: +5 puncte.
      - Fără scor: +3 puncte.
      - Scor < 6.0: 0 puncte (nu sporește afinitatea).
    - **Prag minim de 2 serii**: dacă utilizatorul are sub 2 serii relevante sau nu există genuri, secțiunea de tag-uri rămâne curată și nu ocupă spațiu vertical inutil.

---

### 4. AniList OAuth `client_id`
- **Problema actuală**:
  ```dart
  const url = 'https://anilist.co/api/v2/oauth/authorize?client_id=20894&response_type=token';
  ```
- **Plan de remediere**:
  - Mutăm `20894` într-o clasă de configurare dedicată (de exemplu `AppConstants.anilistClientId` sau dinamic din `.env` prin `flutter_dotenv` / backend endpoint).

---

### 5. Secțiunea Activitate Recentă – Paginare & Vizualizare Extinsă
- **Problema actuală**:
  - Sunt afișate maxim 6 elemente prin `watchlist.take(6)` fără nicio posibilitate de a accesa restul anime-urilor din ecranul de profil.
- **Plan de remediere**:
  - Adăugăm un buton discret *„Vezi tot (X)”* în antetul secțiunii *Activitate Recentă*, care comută utilizatorul către tab-ul principal de Watchlist sau deschide o listă completă filtrabilă.
