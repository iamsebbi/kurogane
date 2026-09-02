# 📌 Audit & Plan de Dinamizare – Ecran Detaliu Serie (`media_detail_screen.dart`)

Acest document inventariază componentele ecranului de detaliu al unei serii ([`media_detail_screen.dart`](file:///d:/kurogane/apps/mobile/lib/views/media_detail_screen.dart)), elementele hardcodate sau redundante identificate și soluțiile arhitecturale propuse pentru alinierea la standardele **Zero Hardcoding** și **Design System Kurogane**.

---

## 📋 1. Ce conține ecranul unei serii

1. **Hero SliverAppBar Cinematic (400px)**:
   - Imagine de fundal extra-large (cover/banner HD) cu zoom & blur la over-scroll.
   - Buton Back rotund 52px (stânga) și buton Bookmark rapid (dreapta - adaugă/șterge din *De văzut*).
   - Scrim gradient dublu (top shadow pentru butoane, bottom fade spre fundalul paginii).
   - Buton plutitor glassmorphic de Trailer (*▶ Trailer*) – deschide trailerul extern.

2. **Antet & Identitate Serie**:
   - Nume studio de producție (uppercase, font 11.5, letter spacing 1.5).
   - Titlu principal (`Zalando Sans Expanded`, font 22, weight 900).
   - Titluri secundare centrate (Romaji + Japoneză Kanji/Kana separate prin `•`).
   - Rând inline de metadate: ⭐ Scor mediu / ponderat, Număr episoade, Status difuzare, Sezon/An (eliminat tagul redundant `TV`).

3. **Butoane de Acțiune Watchlist (Stare Duală)**:
   - **Seria nu este în listă**: Buton full-width proeminent *„+ Adaugă în Watchlist”*.
   - **Seria este deja în listă**:
     - Buton principal de status & progres episoade (ex: *„Vizionare • Ep. 3 / 12”*) – la tap deschide modalul de progres.
     - Buton dedicat de notare (ex: *„⭐ 8.5”* sau *„Notează”*) – la tap deschide modalul de rating.

4. **Genuri & Micro-Tag-uri**:
   - Badge-uri rotunjite ([`PillBadge`](file:///d:/kurogane/apps/mobile/lib/widgets/pill_badge.dart)) pentru genuri principale și tag-uri tematice.

5. **Sinopsis Expandabil**:
   - Descriere completă curățată automat de tag-uri HTML cu animație fluidă `AnimatedSize` (320ms, `Curves.easeInOutCubic`), feedback haptic și icon rotativ `PhosphorIcons.caretDown`.

6. **Sistem de Tab-uri (Pill Navigation)**:
   - 🌲 **Watch Order**: Arborele vizual semnătură Kurogane ([`WatchOrderTreeView`](file:///d:/kurogane/apps/mobile/lib/widgets/watch_order_tree_view.dart)) pentru relațiile din franciză (Sequel, Prequel, Spin-off).
   - 🎴 **Similare**: Grid pe 2 coloane cu anime-uri similare recomandate.
   - ℹ️ **Detalii**: Tabel cu metadate tehnice (Format, Episoade, Sezon/An, Status, Studio, Demografie).

7. **Modal Unificat Watchlist & Notare (Edit / Add Sheet)**:
   - Selector rotunjit de status (*Vizionare*, *Finalizat*, *De Văzut*, *În Pauză*, *Abandonat*).
   - **Stepper Progres Episoade** (`−` / `+`) cu logică de auto-completare.
   - **Stepper Notă Personală** (`−` / `+` întreg 1–10, `Fără notă` default, auto-start la media seriei).
   - **Selector Date Început & Sfârșit** (`startedAt`, `completedAt`) cu auto-populare pe *Vizionare* / *Finalizat*, selecție fluidă de dată și buton `x` de reset.
   - Buton de eliminare din listă (trash can roșu) dacă seria este deja salvată.
   - Buton unic de salvare: trimite statusul, episoadele, nota și datele către API/Supabase și sincronizează automat pe **AniList** dacă este conectat.

---

## ⚠️ 2. Tabel Sinoptic: Elemente Hardcodate & Soluții

| Nr. | Element Afectat | Linii în Cod | Stare Curentă (Hardcodat / Redundant) | Soluție Propusă | Prioritate |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Clasă Buton Plutitor Duplicată** | Liniile `1378–1446` | Re-implementare privată `_DetailFloatingCircleButton` | ✅ **Finalizat**: Înlocuit complet cu `FloatingCircleButton` (52px, blur 18, elastic tap) și eliminat 70 linii de cod redundant | 🟢 Rezolvat |
| **2** | **Scor Inițial Forțat la 8.0** | Linia `816` | `existingRecord.score ?? 8.0` forța orice serie | ✅ **Finalizat**: Calibrat dinamic după scorul ponderat/mediu al seriei (rotunjit la 0.5) sau 7.5 neutru | 🟢 Rezolvat |
| **3** | **Preset-uri Statice de Notare** | Linia `944` | `[10.0, 9.0, ...]` re-instanțiat în fiecare cadru | ✅ **Finalizat**: Extras în constantă `_ratingPresets` (inclusiv `9.5`), `AnimatedContainer` și contrast dinamic WCAG | 🟢 Rezolvat |
| **4** | **Culori Hex Inline Hardcodate** | Liniile `831–835`, `1360–1373` | Culori scrise direct cu `Color(0xFF...)` | ✅ **Finalizat**: Aliniat la token-urile din `AppColors` (`context.scoreGold`, `context.signalLive`, `context.error`) | 🟢 Rezolvat |
| **5** | **Înălțime Fixă Antet Hero (400px)** | Linia `170` | `expandedHeight: 400` rigid indiferent de dispozitiv | ✅ **Finalizat**: Calibrat adaptiv proporțional cu ecranul (`MediaQuery.height * 0.44`, clamp 340–450px) | 🟢 Rezolvat |
| **6** | **Fallback Demografie Static** | Linia `661` | `'General'` hardcodat dacă lipsește demografia | ✅ **Finalizat**: Eliminat fallback-ul fals; rândul se randează curat doar dacă demografia există în API | 🟢 Rezolvat |

---

## 🔍 Detalii & Pași de Remediere

### 1. Unificarea Butonului Plutitor cu `FloatingCircleButton`
- **Problema**: Ecranul `media_detail_screen.dart` conține o clasă întreagă `_DetailFloatingCircleButton` care duplică comportamentul butonului standard de 52px.
- **Remediere**:
  - Se importă `../widgets/floating_circle_button.dart`.
  - Se înlocuiesc instanțele din `SliverAppBar` cu `FloatingCircleButton(size: 52, child: ...)`.
  - Se șterg liniile `1378–1446`.

### 2. Calibrarea Scorului Inițial în Modalul de Rating
- **Problema**: La primul rating, sliderul pornește automat de la 8.0, influențând utilizatorul.
- **Remediere**:
  ```dart
  final animeAvg = (item.scores.weightedScore > 0 ? item.scores.weightedScore : item.scores.averageScore);
  final initialSliderValue = existingRecord.score ?? (animeAvg > 0 ? (animeAvg > 10 ? animeAvg / 10 : animeAvg) : 7.0);
  ```

### 3. Utilizarea Token-urilor de Culoare `AppColors`
- **Problema**:
  - `Color(0xFFFBBF24)` ➔ înlocuit cu `AppColors.scoreGold`
  - `Color(0xFF10B981)` ➔ înlocuit cu `AppColors.signalLive`
  - `Color(0xFFEF4444)` ➔ înlocuit cu `AppColors.error`
