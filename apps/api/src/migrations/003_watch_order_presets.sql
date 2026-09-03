-- Migration: 003_watch_order_presets.sql
-- Description: Community Watch Order Presets, Items, Unique Votes, and Reports with Atomic Row-Locked RPCs

-- 1. Tabela Principală: watch_order_presets
CREATE TABLE IF NOT EXISTS watch_order_presets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  franchise_root VARCHAR(100) NOT NULL,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  submitted_by UUID REFERENCES users(id) ON DELETE SET NULL, -- Dacă autorul își șterge contul, presetul verificat rămâne patrimoniu comunitar
  status VARCHAR(30) DEFAULT 'pending_review' 
    CHECK (status IN ('draft', 'pending_review', 'community_verified', 'rejected', 'flagged')),
  upvotes INT DEFAULT 0 CHECK (upvotes >= 0),
  downvotes INT DEFAULT 0 CHECK (downvotes >= 0),
  report_count INT DEFAULT 0 CHECK (report_count >= 0),
  is_selective_curated BOOLEAN DEFAULT false, -- Indică selecție deliberată a autorului (omitere conștientă de fillere)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexuri pentru interogări rapide și prevenire spam concurent
CREATE INDEX IF NOT EXISTS idx_presets_franchise_status ON watch_order_presets(franchise_root, status);
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_user_franchise_preset 
ON watch_order_presets (submitted_by, franchise_root)
WHERE status IN ('pending_review', 'community_verified', 'flagged');

-- 2. Tabela Elementelor Secvențiale: watch_order_preset_items
CREATE TABLE IF NOT EXISTS watch_order_preset_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  preset_id UUID NOT NULL REFERENCES watch_order_presets(id) ON DELETE CASCADE,
  media_id VARCHAR(100) NOT NULL,
  position INT NOT NULL CHECK (position >= 1),
  is_canon BOOLEAN DEFAULT true,
  note VARCHAR(255),
  CONSTRAINT uq_preset_item_position UNIQUE (preset_id, position),
  CONSTRAINT uq_preset_item_media UNIQUE (preset_id, media_id)
);

CREATE INDEX IF NOT EXISTS idx_preset_items_lookup ON watch_order_preset_items(preset_id, position);

-- 3. Tabela Voturilor Unice: watch_order_preset_votes
CREATE TABLE IF NOT EXISTS watch_order_preset_votes (
  preset_id UUID NOT NULL REFERENCES watch_order_presets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vote SMALLINT NOT NULL CHECK (vote IN (-1, 1)),
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (preset_id, user_id)
);

-- Covering index pentru calcul instantaneu al voturilor fără scanare secvențială
CREATE INDEX IF NOT EXISTS idx_votes_preset_vote ON watch_order_preset_votes(preset_id, vote);

-- 4. Tabela Rapoartelor Unice: watch_order_preset_reports
CREATE TABLE IF NOT EXISTS watch_order_preset_reports (
  preset_id UUID NOT NULL REFERENCES watch_order_presets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (preset_id, user_id)
);

-- 5. Procedură Atomică de Votare cu SELECT ... FOR UPDATE (Zero Race Conditions)
CREATE OR REPLACE FUNCTION rpc_vote_watch_order_preset(
  p_preset_id UUID,
  p_user_id UUID,
  p_vote SMALLINT,
  p_threshold_votes INT DEFAULT 15,
  p_verify_ratio NUMERIC DEFAULT 0.75,
  p_demote_ratio NUMERIC DEFAULT 0.50
)
RETURNS JSONB AS $$
DECLARE
  v_author_id UUID;
  v_current_status VARCHAR(30);
  v_upvotes INT;
  v_downvotes INT;
  v_total INT;
  v_ratio NUMERIC;
BEGIN
  -- 1. Blochează rândul presetului pentru a serializa voturile concurente
  SELECT submitted_by, status INTO v_author_id, v_current_status
  FROM watch_order_presets
  WHERE id = p_preset_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Preset-ul nu există.' USING ERRCODE = 'P0002';
  END IF;

  -- 2. Verificare anti-self-vote (utilizatorul nu își poate vota propria propunere)
  IF v_author_id = p_user_id THEN
    RAISE EXCEPTION 'Nu poți vota propria ta propunere.' USING ERRCODE = '42501';
  END IF;

  -- 3. Upsert atomic al votului
  INSERT INTO watch_order_preset_votes (preset_id, user_id, vote, voted_at)
  VALUES (p_preset_id, p_user_id, p_vote, NOW())
  ON CONFLICT (preset_id, user_id)
  DO UPDATE SET vote = EXCLUDED.vote, voted_at = NOW();

  -- 4. Recalculare instantanee folosind indexul covering
  SELECT 
    COUNT(*) FILTER (WHERE vote = 1),
    COUNT(*) FILTER (WHERE vote = -1)
  INTO v_upvotes, v_downvotes
  FROM watch_order_preset_votes
  WHERE preset_id = p_preset_id;

  v_total := v_upvotes + v_downvotes;
  v_ratio := CASE WHEN v_total > 0 THEN v_upvotes::NUMERIC / v_total::NUMERIC ELSE 0 END;

  -- 5. Mașina de stări (Promovare & Retrogradare)
  IF v_current_status NOT IN ('flagged', 'rejected', 'draft') THEN
    IF v_current_status = 'pending_review' AND v_upvotes >= p_threshold_votes AND v_ratio >= p_verify_ratio THEN
      v_current_status := 'community_verified';
    ELSIF v_current_status = 'community_verified' AND (v_ratio < p_demote_ratio OR (v_upvotes - v_downvotes) < 5) THEN
      v_current_status := 'pending_review';
    END IF;
  END IF;

  -- 6. Actualizare stare agregată
  UPDATE watch_order_presets
  SET 
    upvotes = v_upvotes,
    downvotes = v_downvotes,
    status = v_current_status,
    updated_at = NOW()
  WHERE id = p_preset_id;

  RETURN jsonb_build_object(
    'success', true,
    'upvotes', v_upvotes,
    'downvotes', v_downvotes,
    'status', v_current_status,
    'ratio', ROUND(v_ratio, 2)
  );
END;
$$ LANGUAGE plpgsql;

-- 6. Procedură Atomică de Raportare & Auto-Hide
CREATE OR REPLACE FUNCTION rpc_report_watch_order_preset(
  p_preset_id UUID,
  p_user_id UUID,
  p_reason VARCHAR(100),
  p_flag_threshold INT DEFAULT 5
)
RETURNS JSONB AS $$
DECLARE
  v_current_status VARCHAR(30);
  v_reports INT;
BEGIN
  SELECT status INTO v_current_status
  FROM watch_order_presets
  WHERE id = p_preset_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Preset-ul nu există.' USING ERRCODE = 'P0002';
  END IF;

  -- Inserare unică a raportului (idempotent)
  INSERT INTO watch_order_preset_reports (preset_id, user_id, reason, created_at)
  VALUES (p_preset_id, p_user_id, p_reason, NOW())
  ON CONFLICT (preset_id, user_id) DO NOTHING;

  SELECT COUNT(*) INTO v_reports
  FROM watch_order_preset_reports
  WHERE preset_id = p_preset_id;

  IF v_reports >= p_flag_threshold AND v_current_status != 'rejected' THEN
    v_current_status := 'flagged';
  END IF;

  UPDATE watch_order_presets
  SET report_count = v_reports, status = v_current_status, updated_at = NOW()
  WHERE id = p_preset_id;

  RETURN jsonb_build_object('success', true, 'report_count', v_reports, 'status', v_current_status);
END;
$$ LANGUAGE plpgsql;
