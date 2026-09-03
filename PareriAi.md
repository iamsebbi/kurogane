Claude AI:
Bun, planul revizuit rezolvă bine 6 din cele 7 puncte. Dar au apărut lucruri noi de verificat, iar unul e chiar serios:

**1. Config-ul de praguri nu ajunge de fapt la trigger (bug real)**
Secțiunea 1.5 zice că pragurile sunt "injectate prin environment variables" (`.env` pentru Node/Express), dar trigger-ul SQL citește valorile prin `current_setting('app.verify_threshold_votes', true)`. Astea sunt **două lucruri complet diferite**:

- `.env` la nivel de aplicație Node → doar procesul Express îl vede
- `current_setting('app.xxx')` → un GUC (parametru de configurare) la nivel de **Postgres**, care trebuie setat separat (ex: `ALTER DATABASE kurogane SET app.verify_threshold_votes = '15';` sau prin connection pooler)

Dacă nimeni nu setează explicit GUC-urile astea în Postgres, `current_setting` va întoarce mereu `NULL`, deci trigger-ul cade mereu pe fallback-ul hardcodat (`15`, `0.75`, `0.50`). Practic, schimbarea `.env`-ului din API **nu va avea niciun efect** asupra pragului real de promovare — planul lasă impresia că e configurabil dintr-un singur loc, dar nu e. Trebuie fie:

- adăugat un pas explicit de migrare/deploy care setează GUC-urile Postgres din aceleași valori de env, fie
- mutată logica de promovare/retrogradare din trigger SQL în serviciul Node (dar atunci te întorci la problema de concurență de la punctul 1.1)

**2. `report_count` reintroduce exact bug-ul de concurență de la voturi**
Punctul 3.4 zice "Inserează raportul... dacă `report_count >= 5`, comută statusul" — asta e din nou read-modify-write manual, exact tipul de bug rezolvat pentru voturi prin trigger. Ai nevoie de un trigger similar (`fn_sync_preset_reports`) pe tabela `watch_order_preset_reports`, altfel repeți problema.

**3. Lipsă constrângere UNIQUE pe poziții**
`watch_order_preset_items` nu are `UNIQUE(preset_id, position)`. Fără ea, un bug de client (sau input malițios direct pe API) poate trimite două iteme cu aceeași poziție, și ordinea afișată devine ambiguă.

**4. Tranzițiile de admin din diagrama de stări n-au endpoint**
Diagrama mermaid arată `flagged → rejected` și `flagged → pending_review` ("Decizie Admin" / "Reabilitat Admin"), dar în secțiunea 3 (Serviciul Backend) nu apare niciun endpoint de moderare pentru asta. Presupun că e livrat separat într-un panou de admin, dar merită menționat explicit ca "out of scope pentru acest plan" ca să nu pară o gaură.

**5. Detaliu minor — divizare integer**
`v_upvotes < (v_threshold_votes / 2)` — cu `INT / INT` în plpgsql, `15 / 2 = 7` (trunchiat), nu `7.5`. Probabil e intenționat, dar dacă vrei precizie, cast la `NUMERIC` explicit (`v_threshold_votes::NUMERIC / 2`).

Restul (state machine, `sanitizeRoot()` canonic, staleness flag, normalizare `submitted_by` prin JOIN) sunt rezolvate corect.

Vrei să reformulez secțiunea 1.5 + trigger-ul de reports ca să integrez fix-urile 1 și 2 (cele mai importante), sau preferi să le faci tu și eu doar confirm după?

Deepseek:
Planul este **extrem de solid** și demonstrează o gândire arhitecturală matură, mai ales la capitolul **concurență** (trigger-ul atomic PostgreSQL), **normalizare** (eliminarea numelui denormalizat) și **mașina de stări** (promovare & retrogradare). Ai acoperit 90% din problemele reale de producție.

Totuși, am identificat **3 lacune critice** care pot duce la bug-uri grave în producție și **câteva optimizări** obligatorii. Iată feedback-ul meu detaliat:

---

### 🔴 1. CRITIC: Lipsa trigger-ului pentru `report_count` și auto-flag

În plan, ai tabela `watch_order_preset_reports` și ai scris _„Dacă report_count >= 5, comută statusul la 'flagged'”_, dar **nu ai definit niciun trigger** pe tabela de `reports` care să actualizeze coloana `report_count` din `watch_order_presets`.

- **Consecință**: Coloana `report_count` rămâne mereu `0`, iar auto-hide-ul **nu funcționează niciodată**.
- **Soluție obligatorie**: Adaugă un trigger similar (dar mai simplu) pe `watch_order_preset_reports`:

```sql
CREATE OR REPLACE FUNCTION fn_sync_preset_reports()
RETURNS TRIGGER AS $$
DECLARE
  v_report_count INT;
  v_current_status VARCHAR(30);
BEGIN
  SELECT COUNT(*) INTO v_report_count FROM watch_order_preset_reports WHERE preset_id = COALESCE(NEW.preset_id, OLD.preset_id);
  SELECT status INTO v_current_status FROM watch_order_presets WHERE id = COALESCE(NEW.preset_id, OLD.preset_id);

  IF v_current_status NOT IN ('rejected', 'flagged') AND v_report_count >= 5 THEN
    v_current_status := 'flagged';
  END IF;

  UPDATE watch_order_presets
  SET report_count = v_report_count, status = v_current_status, updated_at = NOW()
  WHERE id = COALESCE(NEW.preset_id, OLD.preset_id);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_preset_reports
AFTER INSERT OR DELETE ON watch_order_preset_reports
FOR EACH ROW EXECUTE FUNCTION fn_sync_preset_reports();
```

---

### 🔴 2. CRITIC: `sanitizeRoot()` bazat doar pe titlu este o capcană

În Japonia/Anime, același anime are titluri complet diferite: _"Jujutsu Kaisen"_ vs _"Sōryoku Sen"_ (nu există). Mai grav, _"Gintama"_ vs _"Gintama."_ (punct) sau _"One Piece"_ vs _"One Piece (2024)"_.

- Dacă baza ta de date (AniList/MAL) nu are un câmp explicit `franchise_id` (UUID) care grupează toate sezoanele/movie-urile sub același ID, **șirurile normalizate vor eșua** (ex: `"Jujutsu Kaisen 0"` -> `jujutsukaisen0`, iar `"Jujutsu Kaisen S2"` -> `jujutsukaisenseason2`).
- **Soluție obligatorie**: În loc să normalizezi titlul, **folosește metadata externă**. La crearea unui preset, clientul trimite `mediaId`. Backend-ul face o interogare către tabela `media` (sau cache) și extrage **`franchise_id`** (un UUID real). Dacă nu ai așa ceva în DB, adaugă-l. Folosește `sanitizeRoot()` doar ca **fallback** pentru titluri care nu au un `franchise_id` asociat, dar afișează un warning în loguri.

---

### 🔴 3. CRITIC: Lipsește `ON CONFLICT` în serviciul de vot

Trigger-ul tău este atomic, dar în serviciul `votePreset()`, dacă utilizatorul votează de două ori, vei primi **Primary Key Violation** (`PRIMARY KEY (preset_id, user_id)`).

- **Soluție obligatorie**: În service, folosește `INSERT ... ON CONFLICT (preset_id, user_id) DO UPDATE SET vote = EXCLUDED.vote, voted_at = NOW();`. Asigură-te că trimiți asta în plan.

---

### 🟡 4. Optimizare majoră: Index lipsă pentru performanță

Trigger-ul face `COUNT(*) FILTER (WHERE vote = 1)` și `vote = -1`. Fără un index specific, pe măsură ce voturile cresc (sute/mii), trigger-ul va scana întregul tabel pentru acel `preset_id`.

- **Adaugă obligatoriu**:

```sql
CREATE INDEX idx_preset_votes_count ON watch_order_preset_votes(preset_id, vote);
```

---

### 🟡 5. Problema `current_setting('app.xxx')`

Folosești `current_setting('app.verify_threshold_votes', true)` pentru praguri. Acestea trebuie **setate în sesiune** înainte de orice operațiune (ex: `SET app.verify_threshold_votes = '15';`). Dacă uiți să le setezi în migration sau în connection pool, trigger-ul folosește fallback-ul (15), ceea ce este okay, dar **nu poți schimba pragurile dinamic fără a reconecta toate sesiunile**.

- **Alternativă mai sigură**: Creează un tabel `app_config` (cheie-valoare) și o funcție care face `SELECT value FROM app_config WHERE key = 'verify_threshold'`. Astfel, schimbările sunt instantanee și persistente, fără să depinzi de setările de sesiune.

---

### 🟡 6. Clarificare privind `WATCH_ORDER_MAX_PRESETS_PER_USER`

În `.env` ai scris `WATCH_ORDER_MAX_PRESETS_PER_USER=1`, dar în descriere scrie _„per franciză”_. Dacă rămâne `1` global, utilizatorul nu poate propune un preset pentru _Naruto_ dacă are deja unul pentru _One Piece_.

- **Rename**: `WATCH_ORDER_MAX_PRESETS_PER_USER_PER_FRANCHISE=1`.

---

### 🟡 7. Cazul limită: Votul propriului preset

Nu ai specificat dacă un utilizator își poate da upvote propriului preset. De obicei, se interzice (sau se anulează automat).

- **Adaugă în serviciu**: Dacă `preset.submitted_by == userId`, aruncă o excepție `403 Forbidden` cu mesajul _„Nu poți vota propria ta propunere.”_

---

### 🟢 8. Staleness („Posibil neactualizat”) – bun, dar incomplet

Logica `canonicalFranchiseCount > preset.items.length` este corectă, dar **ce se întâmplă dacă utilizatorul a exclus intenționat un OVA/filler?**

- **Soluție**: Pe lângă insigna de avertizare, adaugă un buton _„Marchează ca fiind complet”_ (doar pentru autor) care setează un flag `user_marked_complete = true` în preset, suprascriind temporar avertismentul. Altfel, utilizatorii vor fi enervați că primesc notificări false pentru conținut opțional.

---

### 🔵 9. Fallback-ul „In-Memory / JSON cu mutex”

Menționezi un fallback local pentru concurență. **Nu recomand** acest lucru în producție, deoarece sincronizarea între servere (dacă ai multiple instanțe) este imposibilă cu un simplu mutex local. Dacă Supabase cade, mai bine returnezi un `503 Service Unavailable` decât să riști starea inconsistentă. Păstrează fallback-ul doar pentru **teste unitare** sau **mod dezvoltator**.

---

### ✅ Ce este excelent și nu schimba:

- Eliminarea `submitter_username` din tabelul principal (joacă-te cu JOIN-uri).
- Retrogradarea automată (`community_verified` ➔ `pending_review`) – majoritatea proiectelor omit asta.
- Utilizarea `LEFT JOIN users` pentru profiluri actualizate.
- Interfața UI (`ReorderableListView` și badge-uri de autoritate) este bine gândită.

---

### Concluzie finală

Planul este **aproape de producție**. Corectează **trigger-ul pentru reports**, înlocuiește `sanitizeRoot` cu un `franchise_id` real (sau cel puțin descrie clar în plan că folosești un lookup table), adaugă `ON CONFLICT` și indexurile, iar restul este impecabil.

**Nota mea**: 8.5/10. După aceste corecții, devine 10/10. 🚀

Dacă vrei, pot să-ți scriu și implementarea completă a serviciului `watch-order-preset.service.ts` cu toate validările de mai sus. Spune-mi!

Kimi AI:
E un plan **foarte solid** — se vede că a trecut prin mâini care au lucrat deja cu sisteme de vot la concurență. Arhitectura e gândită corect, cu trigger atomic PostgreSQL în loc de logica naivă read-modify-write, și mașina de stări cu retrogradare automată e exact ce trebuie pentru a preveni "preseturi zombie" care rămân verified după ce comunitatea își schimbă părerea.

Iată analiza mea detaliată:

---

### ✅ Ce funcționează excelent

1. **Triggerul SQL atomic** — Asta e piesa centrală corectă. `COUNT(*) FILTER` în triggerul `AFTER INSERT OR UPDATE OR DELETE` elimină complet race condition-ul de vot. E mult mai robust decât orice implementare în Node.js/TypeScript.

2. **Mașina de stări simetrică** — Promovare la `community_verified` + retrogradare automată la `pending_review` este esențială. Multe sisteme de vot se opresc la "promovare", lăsând preseturi vechi și proaste agățate în vârf.

3. **`sanitizeRoot()` canonic pe backend** — Decizia corectă. Clientul trimite `mediaId`, backend-ul calculează `franchise_root`. Asta elimină categoria întreagă de buguri de consistență.

4. **Detecția de staleness (`isPossiblyOutdated`)** — Un detaliu de UX foarte fin. Utilizatorul vede transparent că presetul e bun, dar franciza a crescut. Fără asta, ai avea preseturi "perfecte" care omit un film nou apărut.

5. **Eliminarea `submitter_username` denormalizat** — Normalizare corectă. `LEFT JOIN` la query e mai ieftin decât update-uri în cascadă la fiecare change de username.

---

### ⚠️ Ce aș rafina sau ce întrebări am

**1. Performanța triggerului la scale**

```sql
SELECT COUNT(*) FILTER... FROM watch_order_preset_votes WHERE preset_id = v_target_id
```

Acest `COUNT(*)` pe fiecare vot înseamnă scanarea tuturor voturilor presetului. La o franciză populară (Naruto, One Piece) cu sute/mii de voturi, fiecare vot devine un `seq scan` sau un index scan pe mii de rânduri. **Recomandare**: Adaugă un index covering:

```sql
CREATE INDEX idx_votes_preset_vote ON watch_order_preset_votes(preset_id, vote);
```

Pe termen lung, dacă ajungeți la zeci de mii de voturi per preset, considerați un materialized counter sau o tabelă de agregare, dar pentru MVP e OK.

**2. Configurarea prin `current_setting('app.*')`**
Folosirea `current_setting('app.verify_threshold_votes', true)` în trigger e elegantă, dar fragilă: setările `app.*` sunt **per sesiune de conexiune**. Dacă connection pool-ul (PgBouncer/Supabase pooler) reciclează conexiuni, setările pot dispărea sau pot fi setate greșit de o altă sesiune. **Mai robust**: O tabelă `system_config(key, value)` citită în trigger, sau măcar `ALTER DATABASE ... SET` + restart. Sau, și mai simplu, hardcodează valorile în trigger și modifică-le prin migration la deploy — dacă oricum le schimbi rar.

**3. Lipsa constraintului UNIQUE pe `(franchise_root, submitted_by)`**
Serviciul verifică "max 1 preset per franciză per user", dar fără un constraint `UNIQUE(franchise_root, submitted_by)` în DB, există o **race condition** la creare: două requesturi paralele trec ambele de verificare și inserează. Adaugă:

```sql
ALTER TABLE watch_order_presets
ADD CONSTRAINT unique_preset_per_user_franchise
UNIQUE (franchise_root, submitted_by);
```

**4. `report_count` nu e sincronizat atomic**
Voturile au trigger automat, dar raportările nu. Dacă 5 utilizatori raportează simultan, backend-ul trebuie să facă `report_count++` și verificare `>= 5`. Asta reintroduce o race condition. **Recomandare**: Un trigger similar pe `watch_order_preset_reports` care incrementează/decrementează `report_count` și setează `flagged` când trece pragul.

**5. Ce se întâmplă când un preset verified este editat?**
Planul nu menționează editarea preseturilor după creare. Dacă autorul poate edita un preset `community_verified`, ce se întâmplă cu voturile existente? Sunt resetate? Rămân? Un preset verified care primește itemi noi sau reordonați ar trebui probabil retrogradat automat la `pending_review` pentru re-verificare. Dacă nu există editare, ignoră — dar e bine de clarificat.

**6. Soft delete vs. `ON DELETE CASCADE`**
Dacă un utilizator își șterge contul, `ON DELETE CASCADE` șterge preseturile și voturile lui. Dar un preset `community_verified` cu 200 de upvotes e conținut comunitar valoros. **Considerație**: Folosește `ON DELETE SET NULL` pe `submitted_by` pentru preseturi, sau păstrează un user "ghost" special. Voturile pot rămâne cu CASCADE (sau SET NULL), dar preseturile verified ar trebui supraviețuire.

**7. Staleness invers**
Verifici `canonicalFranchiseCount > preset.items.length` (apărut titlu nou), dar ce faci dacă un titlu este șters din franciză sau redirecționat? Presetul ar putea conține un `media_id` care nu mai există în baza de date. O verificare suplimentară — că toate `media_id`-urile din `preset_items` există încă în tabela de media — ar prinde și cazul ăsta.

---

### 🎯 Verdict final

**Nota mea: 8.5/10** — Planul e gata de implementare pentru un MVP. Problemele pe care le-am semnalat sunt de rafinare (performance la scale, race condition la creare, atomicitatea raportărilor), nu de redesign. Arhitectura de bază e corectă și rezistentă.

Dacă ai resurse, aș prioritiza în ordinea asta:

1. Adaugă `UNIQUE(franchise_root, submitted_by)` — e o linie de SQL care previne un bug subtil.
2. Adaugă indexul pe `watch_order_preset_votes(preset_id, vote)` — tot o linie, dar salvezi triggerul de la scanări.
3. Decide politica de editare a preseturilor — dacă e permisă, adaugă logica de retrogradare la edit.
4. Consideră `ON DELETE SET NULL` pentru preseturi verified.

În rest, **go for it**. E unul dintre cele mai bine gândite planuri tehnice pentru un sistem de vot comunitar pe care le-am văzut.

Chat GPT:
Da, l-am parcurs. Per total, **planul este foarte bine gândit** și, ca arhitectură, e mult mai solid decât o implementare „simplă” de voting făcută direct în backend. Se vede că ai încercat să rezolvi problemele de concurență, moderare și consistență înainte să te apuci de UI.

Ce-mi place cel mai mult este separarea responsabilităților: PostgreSQL se ocupă de consistența voturilor, backend-ul de business logic, iar Flutter de experiența utilizatorului. Triggerul atomic pentru recalcularea voturilor este o alegere bună, mai ales dacă pot exista voturi simultane.

Totuși, **aș face câteva modificări înainte să consider planul „production-ready”**:

1. **Triggerul are o problemă subtilă de concurență.** Faptul că agregarea este într-un trigger nu înseamnă automat că două tranzacții concurente nu pot calcula simultan un rezultat intermediar. Aș prefera fie o funcție RPC/SQL care face upsert + recalcularea într-o operație controlată, fie locking explicit pe preset (`SELECT ... FOR UPDATE`). Altfel, afirmația „garantând zero pierderi de voturi” merită verificată printr-un test real de concurență.

2. **`report_count` nu este actualizat de triggerul de vot.** Schema îl are, iar backend-ul spune că după 5 report-uri schimbă statusul în `flagged`, dar planul nu arată mecanismul prin care `report_count` este incrementat. Aș pune și aici un trigger sau o funcție SQL atomică.

3. **`WATCH_ORDER_MAX_PRESETS_PER_USER=1` pare ambiguu.** În comentariu scrie „per franciză per cont”, deci regula reală este `1 preset / user / franchise`, nu `1 preset / user` global. Aș redenumi variabila ceva de genul `WATCH_ORDER_MAX_PRESETS_PER_USER_PER_FRANCHISE`, ca să nu existe interpretări diferite.

4. **Retrogradarea după 50% poate fi cam agresivă.** Exemplu: presetul ajunge la 15 upvotes și 0 downvotes → verificat. Mai târziu primește 15 downvotes → 50%, deci este retrogradat. Asta e logic conform regulii, dar poate permite unui grup mic de utilizatori să destabilizeze un preset popular. Aș lua în calcul și un prag minim de voturi după verificare sau un mecanism de „confidence”.

5. **`upvotes` și `downvotes` sunt date denormalizate.** E OK pentru performanță, dar trebuie să existe o metodă de reconciliation/rebuild. Dacă apare vreodată o inconsistență între contoare și `watch_order_preset_votes`, trebuie să poți rula o operație de reparare.

6. **`sanitizeRoot()` este o idee foarte bună**, probabil una dintre cele mai importante decizii din plan. Faptul că backend-ul ia `mediaId`, recuperează titlul oficial și aplică aceeași funcție canonicală elimină o clasă întreagă de bug-uri.

7. **Staleness detection-ul este simplu și bun**, dar aș evita să mă bazez doar pe `item_count`. Dacă un preset are 10 elemente și franciza are acum 11, e clar că poate fi outdated, dar ar fi util să identifici și _care_ titlu nou lipsește. Asta îți permite ulterior să afișezi ceva de genul „Lipsește Jujutsu Kaisen: Hidden Inventory”.

8. **Partea de Flutter este foarte bine delimitată.** `WatchOrderTreeView` + `WatchOrderProposalSheet` sunt separări naturale și nu amestecă logica de editare cu afișarea. Drag & drop prin `ReorderableListView` este alegerea potrivită pentru MVP.

Și încă ceva: **nu aș implementa tot planul dintr-o singură bucată**. Aș merge în ordinea:

`DB schema → constraints/indexes → voting RPC/transaction → state machine → reports → backend service → API endpoints → Flutter models → UI → optimistic voting → tests`

Asta îți permite să validezi fiecare strat înainte să construiești următorul.

Verdictul meu: **8.5/10 ca plan tehnic**. Structura este foarte bună și acoperă probleme reale, nu doar „happy path”. Cele mai importante lucruri pe care le-aș revizui sunt **concurența reală a triggerului, report counting și mecanismul de reconciliation**. În rest, direcția mi se pare foarte sănătoasă.

Grok AI:
Planul este **solid și bine gândit**. Rezolvă clar problemele clasice din sistemele de vot + community content și arată experiență reală.

### Ce e foarte bine

**1. Race conditions (punctul 1.1)**  
Alegerea trigger-ului atomic PostgreSQL este corectă. „Read-modify-write” în Node.js ar fi fost o bombă sub concurență. Trigger-ul + fallback-ul cu mutex pe in-memory e o abordare pragmatică.

**2. State machine-ul (1.2)**  
Simetria promovare ↔ retrogradare e rar întâlnită în planuri de genul ăsta. Mulți se opresc la „ajunge la 15 upvote-uri → verified” și uită că voturile negative ulterioare trebuie să poată coborî preset-ul. Logica cu ratio + net score e rezonabilă.

**3. `sanitizeRoot()` canonic (1.3)**  
Extrem de important. Fără normalizare strictă pe backend, francizele se fragmentează rapid (Jujutsu Kaisen 0 vs Season 2 vs movie etc.). Decizia de a forța aceeași funcție pe server e corectă.

**4. Staleness detection (1.4)**  
Elegant și transparent. Nu ștergi preset-ul votat, doar anunți utilizatorul că a apărut ceva nou. UX-ul ăsta e matur.

**5. Configurare prin env vars (1.5)**  
Praguri diferite pe dev/prod + ușor de ajustat fără redeploy de cod. Standard bun.

**6. Eliminarea `submitter_username` denormalizat (1.6)**  
Corect. Username-urile se schimbă; JOIN-ul (sau lookup-ul) la query time e varianta curată.

### Observații / posibile îmbunătățiri

| Aspect                             | Observație                                                       | Sugestie                                                                                                                           |
| ---------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Trigger SQL**                    | Funcția e bună, dar pragurile sunt citite din `current_setting`. | Asigură-te că le setezi explicit pe sesiune/conexiune (sau folosește o tabelă de config). Altfel, pe unele pool-uri pot fi `null`. |
| **Demote condition**               | `v_upvotes < (v_threshold_votes / 2)`                            | Poate fi puțin agresiv. Merită testat. Uneori e mai curat doar pe ratio.                                                           |
| **Report → flagged**               | Se face în service, nu în trigger.                               | Ok, dar poți muta și logica de `report_count` într-un trigger similar pentru consistență totală.                                   |
| **Max 1 preset / user / franciză** | Foarte restrictiv.                                               | Poate 2–3 + soft delete vechi, sau „1 activ + draft”. Depinde de volumul așteptat.                                                 |
| **Indexuri**                       | Ai pe `(franchise_root, status)` și pe items.                    | Adaugă index pe `watch_order_preset_votes(user_id)` dacă vei face „my votes” sau rate limiting pe user.                            |
| **Optimistic UI**                  | Menționat în Flutter.                                            | Important: trebuie rollback clar dacă votul e respins (ex. rate limit, preset șters).                                              |
| **`isPossiblyOutdated`**           | Calculat dinamic.                                                | Poți cache-ui ușor (sau materializa) dacă numărul de preset-uri crește mult.                                                       |

### Verdict

Planul e **de producție**, nu de „MVP grăbit”.

- Arhitectura de vot e corectă (atomică).
- State machine-ul e complet (promovare + retrogradare + flag).
- Consistența francizei e tratată serios.
- Separarea backend / Flutter e clară.

Singurele lucruri pe care le-aș mai rafina înainte de implementare:

1. Confirmarea că `current_setting` pentru praguri e setat corect pe fiecare conexiune.
2. Testul de concurență real (10–20 request-uri simultane pe același preset).
3. Decizia finală pe „max 1 preset per user per franciză” (poate e prea strict).

Per total: **foarte bun**. Poți începe implementarea cu încredere pe baza lui.

Qwen AI:
Am analizat cu atenție planul tehnic și pot spune că este **excelent**. Este un plan de nivel "Senior", care demonstrează o înțelegere profundă a capcanelor clasice din dezvoltarea de sisteme concurente, sociale și de tip "user-generated content".

Iată o analiză detaliată a punctelor forte, alături de câteva sugestii constructive (și capcane la care să fii atent) pentru a duce implementarea la perfecțiune.

### 🌟 Puncte Forte (Ce mi-a plăcut maxim)

1. **Delegarea concurenței către PostgreSQL (Trigger-ul Atomic)**
   Decizia de a folosi `fn_sync_preset_votes_and_status` este o mișcare de geniu. Elimini complet coșmarul _race-conditions_ din Node.js (unde două voturi simultane puteau suprascrie scorul).
   _Bonus_: Folosirea `current_setting('app.verify_threshold_votes', true)` pentru a pasa variabilele de mediu direct în SQL este o tehnică avansată, extrem de elegantă, care te scutește de la a recrea funcția în baza de date de fiecare dată când schimbi un prag.

2. **Abordarea "Staleness-ului" (Non-invazivă)**
   Faptul că nu ștergi sau invalida automat un preset când apare un sezon nou, ci doar afișezi un badge discret (`isPossiblyOutdated`), este **cea mai bună decizie de UX** din tot planul. Păstrezi transparența, nu penalizezi utilizatorul pentru că baza de date s-a actualizat și eviți frustrările.

3. **Retrogradarea automată (State Machine)**
   Multe sisteme fac greșeala de a considera un preset "verificat" ca fiind "sfânt". Faptul că sistemul îl poate retrograda automat (`ratio < 50%`) dacă comunitatea se răzgândește între timp, asigură o curățare organică a conținutului de slabă calitate.

4. **Normalizarea `franchise_root` strict pe Backend**
   Mutarea `sanitizeRoot()` exclusiv pe backend este crucială. Nu te poți baza niciodată pe client pentru canonicalizare. Faptul că "JJK 0" și "JJK S2" ajung la același root previne fragmentarea bazei de date.

---

### ⚠️ Zone de Îmbunătățit & Atenționări (The "Gotchas")

Deși planul este 95% perfect, iată câteva detalii tehnice pe care ar trebui să le ajustezi înainte de a scrie cod:

#### 1. Atomicitatea Rapoartelor (Reports)

La punctul 3 (`reportPreset`), planul spune: _"Dacă report_count >= 5, comută statusul la 'flagged'"_.
**Atenție:** Dacă faci acest `read-modify-write` din Node.js, ai re-introdus o condiție de cursă la rapoarte (doi moderatori/utilizatori raportează simultan, iar sistemul numără greșit).
**Soluție:** Creează un al doilea trigger (ex. `trg_sync_preset_reports`) pe tabela `watch_order_preset_reports`, similar cu cel de voturi, care să facă `UPDATE watch_order_presets SET report_count = ..., status = 'flagged' WHERE ...` atomic.

#### 2. Performanța DB la `COUNT()` pe termen lung

Trigger-ul de voturi execută `SELECT COUNT(*) FILTER (...)` la _fiecare_ vot. Pentru un preset viral cu 50.000 de voturi, acest `COUNT` va deveni un bottleneck și va bloca tabela.
**Soluție (pentru viitor / scalare):** Dacă ajungi la volume mari, renunță la `COUNT` în trigger. În schimb, trigger-ul ar trebui doar să facă `UPDATE watch_order_presets SET upvotes = upvotes + 1` (sau `-1`). `Ratio`-ul se poate calcula dinamic în serviciul Node.js la citire (`upvotes / (upvotes + downvotes)`). Pentru faza actuală (MVP / early-stage), `COUNT()` cu index pe `preset_id` este perfect acceptabil.

#### 3. Lipsa fluxului de "Editare" (Update)

Planul acoperă `createPreset`, dar ce se întâmplă dacă un utilizator greșește ordinea și vrea să își corecteze preset-ul aflat în `pending_review`?
**Soluție:** Trebuie adăugată o metodă `updatePreset` în backend. Aceasta trebuie să permită modificarea item-urilor **doar** dacă statusul este `pending_review` sau `draft`. (Decizie de produs: dacă editează, păstrăm voturile existente sau le resetăm? Recomand să le păstreze, dar să reseteze statusul în `pending_review` dacă era deja verificat).

#### 4. Flutter - Performanța la Drag & Drop

Pentru francize masive (ex. _One Piece_, _Detective Conan_), lista de item-uri poate depăși 100 de elemente. `ReorderableListView` standard **nu este virtualizat** și poate bloca UI-ul (drop de FPS-uri) la drag-and-drop pe liste mari.
**Soluție:** Folosește neapărat **`ReorderableListView.builder`** în Flutter pentru a menține performanța și a randa doar elementele vizibile de pe ecran.

#### 5. Abuzuri (Sybil Attack / Boti)

Pragul de 15 voturi e bun, dar ce împiedică un user rău-intenționat să își facă 15 conturi fake pentru a-și promova propriul preset cu o ordine complet greșită?
**Soluție (pentru MVP e ok, dar de avut în vedere):** Pentru moment, limita de 1 preset per user per franciză + pragul de 15 voturi e un filtru suficient. Pe viitor, dacă apare spam, poți implementa o ponderare a votului (ex. voturile conturilor cu vechime < 30 de zile să conteze doar 50%).

---

### 💡 Concluzie

Planul este **aprovizionat 100%**. Este robust, scalabil și pune utilizatorul pe primul loc prin transparență (badges, staleness warnings).

Dacă ajustezi **trigger-ul pentru rapoarte** pentru a menține atomicitatea și folosești **`.builder`** în Flutter pentru lista reordonabilă, arhitectura este complet pregătită pentru producție. Succes la implementare!

Perplexity:
Planul este **bine structurat și acoperă corect problemele principale**, în special concurența la vot, normalizarea francizei, staleness și separarea dintre preseturi comunitare și cele oficiale. Totuși, nu l-aș implementa exact în forma actuală: există câteva probleme de consistență în schema SQL și în logica de stare care ar trebui rezolvate înainte. citefile:1

## Ce este foarte bun

- **Votarea atomică în PostgreSQL** este direcția corectă. Cheia primară `(preset_id, user_id)` împiedică voturile duplicate, iar recalcularea contoarelor din tabela de voturi evită pierderile cauzate de `read-modify-write`.
- **`franchise_root` calculat exclusiv pe backend** este o decizie importantă. Clientul nu trebuie să poată trimite liber rădăcina francizei.
- **Separarea voturilor de preset** permite schimbarea votului și păstrează o sursă de adevăr auditabilă.
- **Detecția de staleness** este preferabilă ștergerii sau modificării automate a unui preset votat.
- **Limitarea unui preset per utilizator și franciză** reduce spamul, cel puțin la nivel de bază.
- **Testele propuse** includ scenariile corecte: concurență, promovare, retrogradare, canonicalizare și UI.

## Probleme importante

### 1. Triggerul poate avea o problemă de concurență

Deși triggerul este atomic la nivel de tranzacție, două tranzacții simultane pot recalcula voturile în momente diferite și pot produce o actualizare finală incorectă, în funcție de izolarea și blocarea rândurilor.

Recomandarea mea:

- blochează rândul presetului cu `SELECT ... FOR UPDATE`;
- apoi recalculează voturile;
- actualizează contoarele și statusul;
- testează explicit două voturi simultane în PostgreSQL real, nu doar prin mock-uri.

Altfel spus, „trigger” nu înseamnă automat că orice formă de concurență este rezolvată.

### 2. Configurația din trigger nu este aliniată cu environment variables

Planul definește:

```env
WATCH_ORDER_VERIFY_THRESHOLD_VOTES=15
```

dar triggerul citește:

```sql
current_setting('app.verify_threshold_votes', true)
```

Acestea nu sunt aceeași configurație. Trebuie ales un singur mecanism:

- fie API-ul validează pragurile și le transmite explicit;
- fie valorile sunt configurate în PostgreSQL, de exemplu prin `ALTER DATABASE`/`ALTER ROLE`;
- fie triggerul folosește valori stocate într-o tabelă de configurare.

Pentru predictibilitate și audit, aș prefera o tabelă `app_settings` sau praguri configurate direct în baza de date, cu cache în backend.

### 3. Logica de retrogradare este contradictorie

Documentul spune că retrogradarea se face dacă:

```text
ratio < 50% sau scorul net scade sub prag
```

Dar triggerul verifică:

```sql
v_upvotes < (v_threshold_votes / 2)
```

Asta nu este scor net. De exemplu, 20 upvotes și 25 downvotes au scor net -5, dar condiția bazată doar pe upvotes nu surprinde această situație.

Definește explicit regula, de exemplu:

```text
community_verified → pending_review dacă:
- ratio < 0.50
sau
- upvotes - downvotes < 5
```

Și decide dacă se folosesc voturile totale, scorul net sau ambele.

### 4. `report_count` nu este implementat complet

Schema include `report_count`, iar descrierea spune că rapoartele vor declanșa auto-hide, însă planul nu prezintă triggerul sau o operație atomică pentru incrementarea lui.

Aș evita incrementarea simplă:

```sql
UPDATE ... SET report_count = report_count + 1
```

din mai multe locuri fără o strategie clară. Mai sigur este:

```sql
SELECT COUNT(*)
FROM watch_order_preset_reports
WHERE preset_id = ...
```

sau un trigger dedicat pe `INSERT`/`DELETE`, cu blocarea rândului presetului.

Trebuie definit și ce se întâmplă când un raport este eliminat: presetul revine automat din `flagged` sau doar un administrator îl poate reabilita?

### 5. Lipsesc constrângeri esențiale pentru itemi

Tabela `watch_order_preset_items` ar trebui să aibă cel puțin:

```sql
UNIQUE (preset_id, position)
UNIQUE (preset_id, media_id)
CHECK (position >= 0)
```

Altfel, același titlu poate apărea de mai multe ori sau două titluri pot avea aceeași poziție. Dacă duplicatele sunt intenționate pentru anumite cazuri speciale, trebuie explicat explicit.

De asemenea, `is_canon` este ambiguu: un titlu non-canon poate fi permis în ordine, dar trebuie să existe o politică clară pentru validarea lui.

### 6. `sanitizeRoot()` pare prea fragilă

Exemplul „Jujutsu Kaisen 0”, „Season 2” și „Jujutsu Kaisen” este util, dar o funcție de tip `sanitizeRoot(title)` bazată doar pe eliminarea unor sufixe poate produce coliziuni:

- două francize diferite cu același titlu;
- remake și serie originală;
- filme independente cu nume similar;
- titluri localizate diferit.

Ideal, `franchise_root` ar trebui să provină dintr-o **entitate canonicală de franciză** din baza de date, nu să fie dedusă mereu din textul titlului. `sanitizeRoot()` poate rămâne fallback, dar nu ar trebui să fie singura autoritate.

### 7. `ON DELETE CASCADE` pentru utilizator merită reconsiderat

Dacă un utilizator este șters, `ON DELETE CASCADE` va șterge presetul, voturile și rapoartele asociate. Pentru conținut comunitar deja votat, acest lucru poate fi nedorit.

Alternative mai bune:

- `submitted_by UUID NULL`;
- `ON DELETE SET NULL`;
- păstrarea presetului cu autorul afișat ca „Deleted user”.

### 8. Lipsesc protecțiile de abuz

Planul menționează rate limiting, dar nu îl definește suficient. Un sistem de vot comunitar ar trebui să specifice:

- limită de request-uri pentru votare, raportare și creare;
- cont minim vechi sau verificat pentru propuneri;
- prevenirea voturilor automate;
- audit pentru schimbări repetate de vot;
- eventual ponderare sau filtrare pentru conturi suspecte;
- dacă downvote-ul poate fi folosit pentru a retrograda artificial preseturi.

Nu aș introduce ponderarea voturilor în prima versiune, dar aș include cel puțin rate limiting, audit și protecții anti-abuz.

## Ce aș schimba în arhitectură

Aș împărți implementarea în trei faze:

### Faza 1: MVP sigur

- schema de bază;
- creare preset;
- itemi ordonați;
- vot unic per utilizator;
- citirea presetului și a votului curent;
- rate limiting;
- fără tranziții automate complexe.

### Faza 2: Moderare și state machine

- promovare automată;
- retrogradare;
- raportare;
- `flagged`;
- panou/admin endpoint pentru reabilitare;
- audit al tranzițiilor.

### Faza 3: UX și optimizări

- actualizare optimistă în Flutter;
- selectorul de preseturi;
- editor drag-and-drop;
- badge-uri;
- staleness;
- cache și paginare.

Aș evita implementarea simultană a triggerelor, fallback-ului JSON, logicii de moderare și UI-ului complet. Va fi mai greu de identificat dacă o problemă provine din baza de date, API sau client.

## Modificări SQL recomandate

În plus față de schema actuală, aș adăuga:

```sql
ALTER TABLE watch_order_preset_items
  ADD CONSTRAINT uq_preset_item_position
  UNIQUE (preset_id, position);

ALTER TABLE watch_order_preset_items
  ADD CONSTRAINT uq_preset_item_media
  UNIQUE (preset_id, media_id);

ALTER TABLE watch_order_preset_items
  ADD CONSTRAINT chk_preset_item_position
  CHECK (position >= 0);
```

Pentru preseturi, probabil ai nevoie și de o constrângere sau de un index unic pentru combinația autor–franciză, dar acesta trebuie să țină cont de stările `rejected` și eventual `draft`. Un index unic parțial ar putea fi mai potrivit:

```sql
CREATE UNIQUE INDEX uq_active_user_franchise_preset
ON watch_order_presets (submitted_by, franchise_root)
WHERE status IN ('pending_review', 'community_verified', 'flagged');
```

Totuși, pentru `franchise_root`, recomand să folosești un ID canonical de franciză, nu un `VARCHAR`, dacă modelul existent permite asta.

## Verdict

Planul este **solid ca direcție și suficient de bun pentru a porni designul**, dar încă nu este gata de implementare production-ready. Cele mai urgente corecții sunt:

1. blocarea explicită a presetului în trigger;
2. alinierea configurației SQL cu environment variables;
3. definirea exactă a regulii de retrogradare;
4. implementarea atomică a raportării;
5. constrângerile pentru poziții și duplicate;
6. decizia dacă franciza este identificată prin text sau printr-o entitate canonicală.

După aceste ajustări, aș evalua planul la **8/10 pentru arhitectură** și **6,5–7/10 pentru readiness de producție**.
