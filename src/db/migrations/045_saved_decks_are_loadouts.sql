ALTER TABLE auth.saved_decks
  ADD COLUMN IF NOT EXISTS don_deck_id UUID,
  ADD COLUMN IF NOT EXISTS playmat_cosmetic_id UUID,
  ADD COLUMN IF NOT EXISTS playmat_cosmetic_slot TEXT GENERATED ALWAYS AS ('playmat') STORED,
  ADD COLUMN IF NOT EXISTS don_sleeve_cosmetic_id UUID,
  ADD COLUMN IF NOT EXISTS don_sleeve_cosmetic_slot TEXT GENERATED ALWAYS AS ('don_sleeve') STORED,
  ADD COLUMN IF NOT EXISTS deck_sleeve_cosmetic_id UUID,
  ADD COLUMN IF NOT EXISTS deck_sleeve_cosmetic_slot TEXT GENERATED ALWAYS AS ('deck_sleeve') STORED;

WITH latest_loadouts AS (
  SELECT DISTINCT ON (user_id, main_deck_id)
    user_id,
    main_deck_id,
    don_deck_id,
    playmat_cosmetic_id,
    don_sleeve_cosmetic_id,
    deck_sleeve_cosmetic_id,
    updated_at
  FROM auth.loadouts
  ORDER BY user_id, main_deck_id, updated_at DESC
)
UPDATE auth.saved_decks d
SET
  don_deck_id = latest_loadouts.don_deck_id,
  playmat_cosmetic_id = latest_loadouts.playmat_cosmetic_id,
  don_sleeve_cosmetic_id = latest_loadouts.don_sleeve_cosmetic_id,
  deck_sleeve_cosmetic_id = latest_loadouts.deck_sleeve_cosmetic_id,
  updated_at = GREATEST(d.updated_at, latest_loadouts.updated_at)
FROM latest_loadouts
WHERE d.user_id = latest_loadouts.user_id
  AND d.id = latest_loadouts.main_deck_id;

ALTER TABLE auth.saved_decks
  DROP CONSTRAINT IF EXISTS saved_decks_user_don_deck_fk,
  DROP CONSTRAINT IF EXISTS saved_decks_playmat_cosmetic_slot_fk,
  DROP CONSTRAINT IF EXISTS saved_decks_don_sleeve_cosmetic_slot_fk,
  DROP CONSTRAINT IF EXISTS saved_decks_deck_sleeve_cosmetic_slot_fk;

ALTER TABLE auth.saved_decks
  ADD CONSTRAINT saved_decks_user_don_deck_fk
    FOREIGN KEY (user_id, don_deck_id)
    REFERENCES auth.saved_don_decks(user_id, id)
    ON DELETE RESTRICT,
  ADD CONSTRAINT saved_decks_playmat_cosmetic_slot_fk
    FOREIGN KEY (playmat_cosmetic_id, playmat_cosmetic_slot)
    REFERENCES auth.cosmetics(id, slot)
    ON DELETE RESTRICT,
  ADD CONSTRAINT saved_decks_don_sleeve_cosmetic_slot_fk
    FOREIGN KEY (don_sleeve_cosmetic_id, don_sleeve_cosmetic_slot)
    REFERENCES auth.cosmetics(id, slot)
    ON DELETE RESTRICT,
  ADD CONSTRAINT saved_decks_deck_sleeve_cosmetic_slot_fk
    FOREIGN KEY (deck_sleeve_cosmetic_id, deck_sleeve_cosmetic_slot)
    REFERENCES auth.cosmetics(id, slot)
    ON DELETE RESTRICT;

ALTER TABLE auth.sim_handoff_tokens
  DROP CONSTRAINT IF EXISTS sim_handoff_tokens_loadout_id_fkey,
  DROP CONSTRAINT IF EXISTS sim_handoff_tokens_user_id_loadout_id_fkey;

UPDATE auth.sim_handoff_tokens h
SET loadout_id = l.main_deck_id
FROM auth.loadouts l
WHERE h.loadout_id = l.id;

ALTER TABLE auth.sim_handoff_tokens
  ADD CONSTRAINT sim_handoff_tokens_loadout_id_fkey
    FOREIGN KEY (loadout_id)
    REFERENCES auth.saved_decks(id)
    ON DELETE CASCADE,
  ADD CONSTRAINT sim_handoff_tokens_user_id_loadout_id_fkey
    FOREIGN KEY (user_id, loadout_id)
    REFERENCES auth.saved_decks(user_id, id)
    ON DELETE CASCADE;

DROP TABLE IF EXISTS auth.loadouts;

COMMENT ON COLUMN auth.saved_decks.don_deck_id IS
  'Optional DON!! deck selected for the account deck collection when used as a sim loadout.';

COMMENT ON COLUMN auth.saved_decks.playmat_cosmetic_id IS
  'Optional playmat cosmetic selected for the account deck collection when used as a sim loadout.';

COMMENT ON COLUMN auth.saved_decks.don_sleeve_cosmetic_id IS
  'Optional DON!! sleeve cosmetic selected for the account deck collection when used as a sim loadout.';

COMMENT ON COLUMN auth.saved_decks.deck_sleeve_cosmetic_id IS
  'Optional main deck sleeve cosmetic selected for the account deck collection when used as a sim loadout.';
