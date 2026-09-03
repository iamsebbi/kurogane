# 📖 Sistemul de Relații Franciză & Serii Conexe — Arhitectură & Integrare Mobile

Acest document descrie arhitectura sistemului de **Relații de Franciză (Relations: Prequel / Sequel / Side Story / Spin-off)** din cadrul platformei Kurogane — de la evoluția conceptuală și decizia de a renunța la ghidurile manuale, până la logicile 100% dinamice din API și designul curat din Flutter.

---

## 1. Evoluția Conceptuală: De la Watch Order Manual la Relații Native

### 1.1 De ce s-a renunțat la sistemul „Watch Order” manual/comunitar
Inițial, platforma a experimentat cu un sistem de ghiduri cronologice manuale și propuneri comunitare (`WatchOrderPreset`). În practică, această abordare a prezentat dezavantaje majore:
* **Dependență de volum**: Necesita mii de votanți activi pentru ca ghidurile să fie relevante. În lipsa lor, 98% din anime-uri rămâneau fără ghiduri sau depindeau de euristică.
* **Fragilitate**: Risc permanent de fals-pozitive (asocieri greșite de ID-uri) și mentenanță infinită pentru fiecare sezon nou apărut în Japonia.
* **Redundanță**: În majoritatea cazurilor, utilizatorii căutau un răspuns rapid la: *„Care este sezonul 2 (Sequel)? Ce a fost înainte (Prequel)? Ce OVA-uri canonice există?”*.

### 1.2 Soluția Nativă: Graful Oficial de Relații AniList (Standard MAL/AniList)
S-a decis tranziția definitivă către **standardul recunoscut din industrie (Relations)**:
* **Zero Hardcoding**: Datele sunt extrase 100% dinamic din graful oficial AniList pentru **toate cele 15.000+ de anime-uri**.
* **Zero Mentenanță**: Când un sequel este anunțat oficial, el apare instantaneu în aplicație fără nicio intervenție manuală.
* **Navigare în Lanț**: Ești pe Sezonul 1 ➔ apeși pe `SEQUEL` ➔ ești pe Sezonul 2 ➔ apeși pe `SEQUEL` ➔ ești pe Sezonul 3.

---

## 2. Diagrama Fluxului de Date

```mermaid
sequenceDiagram
    autonumber
    actor User as Utilizator Mobile
    participant Flutter as Flutter App (MediaDetailScreen -> MediaRelationsView)
    participant API as Express Backend (/api/media/:id)
    participant AniList as AniList GraphQL Service (FETCH_MEDIA_BY_ID_QUERY)

    User->>Flutter: Deschide ecranul anime-ului (ex: Attack on Titan / Fate/Zero)
    Flutter->>API: GET /api/media/{id} (sau GET /api/media/{id}/relations)
    API->>AniList: Interogare GraphQL cu relations { edges { relationType node { ... } } }
    AniList-->>API: Returnează relațiile oficiale (SEQUEL, PREQUEL, SIDE_STORY, etc.)
    API->>API: mapAniListToMediaItem() construiește MediaRelation[]
    API-->>Flutter: Obiectul MediaItem complet cu câmpul relations
    Flutter->>Flutter: MediaRelationsView structurează categoriile (Fără border, full-rounded)
    Flutter-->>User: Randează secțiunile curate; tap pe SEQUEL deschide direct sezonul următor
```

---

## 3. Tipuri de Date & Clasificare Semantică

### 3.1 `@kurogane/shared` (`packages/shared/src/types/media.ts`)

```typescript
export type MediaRelationType =
  | 'PREQUEL'
  | 'SEQUEL'
  | 'PARENT'
  | 'SIDE_STORY'
  | 'SPIN_OFF'
  | 'ALTERNATIVE'
  | 'SUMMARY'
  | 'OTHER'
  | 'ADAPTATION'
  | 'CHARACTER';

export interface MediaRelation {
  id: string;          // ex: 'anilist-20958'
  anilistId: number;   // ex: 20958
  relationType: MediaRelationType;
  title: string;       // Titlu preferat
  format?: string;     // 'TV', 'MOVIE', 'OVA', 'SPECIAL', 'MANGA'
  type?: string;       // 'ANIME', 'MANGA'
  status?: string;     // 'FINISHED', 'RELEASING'
  episodes?: number;   // Număr episoade
  releaseYear?: number;// An lansare
  coverImage?: string; // URL poster HD AniList CDN
}
```

---

## 4. Design & Principii UI în Aplicația Mobilă

### 4.1 Ierarhia Secțiunilor în `MediaRelationsView`
1. **Povestea Principală (Prioritate Maximă)**:
   * Reunește **`SEQUEL`** (Continuare directă) și **`PREQUEL`** (Precursor).
   * **Doar în această secțiune** se afișează badge-ul semantic (`CONTINUARE DIRECTĂ • SEQUEL` cu accent primary, respectiv `PRECURSOR • PREQUEL` subtil), ambele concepute ca pastile **full-rounded** (`9999`).
2. **Povești Secundare & Speciale (`SIDE_STORY`)**:
   * OVA-uri canonice, episoade speciale. Fără badge intern — titlul secțiunii este autosuficient.
3. **Spin-off-uri & Paralele (`SPIN_OFF`)**:
   * Parodii sau serii derivate (ex: *Attack on Titan: Junior High*, *Koro-sensei Q!*).
4. **Versiuni Alternative (`ALTERNATIVE`)**:
   * Adaptări alternative ale aceleiași surse (ex: *FMA (2003)* vs *Brotherhood*).
5. **Filme Rezumat (`SUMMARY`)**:
   * Filme recapitulare pentru cei care vor să sară direct peste un sezon.
6. **Material Sursă (`SOURCE` / `ADAPTATION`)**:
   * Manga sau Light Novel-ul de la baza adaptării (afișat informativ).

### 4.2 Reguli Vizuale Kurogane Aplicate
* **Zero Bordere**: S-au eliminat toate borderele inutile de pe carduri, empty-state și din bara superioară, lăsând suprafețele să respire.
* **Full Rounded Organice**: Cardurile folosesc `borderRadius: BorderRadius.circular(20)` cu poster `12px` (raze concentrice optice). Pastilele folosesc `BorderRadius.circular(9999)`.
* **Tab-uri Fără Divider**: S-a setat `dividerColor: Colors.transparent` pe TabBar-ul ecranului de detalii pentru a elimina linia gri de separare.
* **Fără Etichetă `TV`**: Se omite mențiunea `TV`, afișându-se doar formatele speciale (`MOVIE`, `OVA`, `SPECIAL`).
