# 📌 Audit & Plan de Refactorizare – Ecranul Acasă / Home Screen (`apps/mobile`)

Acest document inventariază structura ecranului Acasă ([`home_screen.dart`](file:///d:/kurogane/apps/mobile/lib/views/home_screen.dart)), valorile hardcodate sau statice identificate, datele API neutilizate și soluțiile tehnice pentru refactorizarea completă conform standardelor de design și arhitectură Kurogane.

---

## 📋 Tabel Sinoptic: Elemente Hardcodate, Redundanțe & Soluții

| Nr. | Element Afectat | Linii în Cod | Stare Curentă (Hardcodat / Redundant) | Soluție Tehnică Propusă | Impact / Prioritate |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Bulina Roșie Notificări** | Liniile `296–307` | Condiționată dinamic prin `unreadNotificationsCountProvider > 0` | ✅ **Rezolvat** | 🟢 Completat |
| **2** | **Buton Circular Duplicat (`_FloatingCircleButton`)** | Liniile `456–524` | Clasa privată ștearsă; se folosește widget-ul oficial partajat `FloatingCircleButton` | ✅ **Rezolvat** | 🟢 Completat |
| **3** | **Carduri Vechi `MediaCard`** | Liniile `176`, `205` | Înlocuite în totalitate cu caruselul partajat `HorizontalPosterCarousel` și `CleanPosterCard.fromMediaItem` (Trending & Capodopere) | ✅ **Rezolvat** | 🟢 Completat |
| **4** | **Dublare Date Hero vs. Sezon** | Liniile `115`, `148` | `SeasonalAnimeSection` și `HeroCarousel` consumă ambele `data.featuredSeason`, afișând aceleași anime-uri consecutiv | Hero Carousel rămâne pe `featuredSeason` (titlurile cheie), iar secțiunea sezonieră consumă `data.trendingSeason` sau `data.topAiring` | 🟠 Mediu (Conținut / UX) |
| **5** | **Date API Disponibile dar Neafișate** | Model `HomepageData` | Integrate caruselele orizontale *„Recommended For You”* (`data.recommendations`) și *„Coming Soon”* (`data.topUpcoming`) cu `CleanPosterCard` | ✅ **Rezolvat** | 🟢 Completat |
| **6** | **Carduri de Știri Pasive (`_buildNewsCard`)** | Liniile `376–452` | Extras în widget partajat `NewsArticleCard` cu micro-scale `TactileScaleButton` și lansare browser `url_launcher` | ✅ **Rezolvat** | 🟢 Completat |
| **7** | **Culori Statice Hardcodate** | Liniile `36`, `54`, `60`, `68`, `75`, `303` | `AppColors.accentPrimary`, `AppColors.alertCoral`, `AppColors.textPrimary`, `AppColors.textSecondary` hardcodate | Trecere la extensia de temă `context.accentPrimary`, `context.error`, `context.textPrimary`, etc. (suport nativ Light & Dark) | 🟢 Calitate Cod / Teme |
| **8** | **Secțiunea Sezonieră (`SeasonalAnimeCard`)** | `seasonal_anime_card.dart` | Descriere fallback statică (*„Sezon nou în difuzare pe Kurogane.”*), culori hex statice, bookmark manual | Curățare descriere, aliniere la culori semantice și integrare cu modalul unificat `showWatchlistEditModal` | 🟠 Mediu (Coerență) |
| **9** | **Card Episoade Noi (`AiringEpisodeCard`)** | `airing_episode_card.dart` | Border gri static (`borderSubtle`), tranziție standard `MaterialPageRoute` | Rafinare stilistică (0-border conform noului limbaj vizual) și navigare fluidă `BlurFadePageRoute` | 🟡 Polish Vizual |

---

## 🔍 Detalii & Plan de Implementare

### 1. Curățarea Header-ului & Butoanelor Frosted Glass
* Înlocuirea `_FloatingCircleButton` (privat) cu componenta partajată:
  ```dart
  import '../widgets/floating_circle_button.dart';
  ```
* Condiționarea bulinei roșii:
  - Dacă utilizatorul nu are notificări necitite, clopoțelul rămâne curat, fără indicator fals.

### 2. Standardizarea Cardurilor Poster pe Toate Listele Orizontale
* Înlocuirea:
  ```dart
  // VECHI:
  MediaCard(item: item, width: 155)
  ```
  cu:
  ```dart
  // NOU:
  CleanPosterCard.fromMediaItem(
    item: item,
    width: 140,
    posterAspectRatio: 1 / 1.42,
  )
  ```
* Oferă consistență vizuală 1:1 cu ecranele **Explorează**, **Căutare Rapidă** și **Watchlist**.

### 3. Integrarea Secțiunilor Noi din API
* **Recomandări Personalizate** (`data.recommendations`):
  - Afișează badge-ul de motivare (ex: *„Fiindcă ai vizionat Jujutsu Kaisen”* sau *„94% Potrivire”*).
* **Urmează să apară (Upcoming)** (`data.topUpcoming`):
  - Carusel cu cele mai așteptate titluri din sezoanele viitoare.

### 4. Interactivitate pentru Știri (`_buildNewsCard`)
* Adăugarea callback-ului de deschidere URL:
  ```dart
  onTap: () async {
    final uri = Uri.tryParse(article.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  ```

### 5. Curățenie de Cod și Performanță
* Eliminarea a peste 150 de linii de cod duplicat din `home_screen.dart`.
* Înlocuirea culorilor hardcodate `AppColors.*` cu proprietățile dinamice `context.*`.
* Validare completă cu `flutter analyze` la 0 issues.
