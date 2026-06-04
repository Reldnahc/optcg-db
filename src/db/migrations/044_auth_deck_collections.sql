CREATE TABLE IF NOT EXISTS auth.deck_folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT deck_folders_name_length_check CHECK (char_length(name) BETWEEN 1 AND 80),
  CONSTRAINT deck_folders_sort_order_check CHECK (sort_order >= 0),
  UNIQUE (user_id, id)
);

CREATE INDEX IF NOT EXISTS deck_folders_user_sort_idx
  ON auth.deck_folders(user_id, sort_order, created_at);

ALTER TABLE auth.saved_decks
  ADD COLUMN IF NOT EXISTS folder_id UUID,
  ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'deck',
  ADD COLUMN IF NOT EXISTS leader_card_number TEXT,
  ADD COLUMN IF NOT EXISTS leader_variant_index INT,
  ADD COLUMN IF NOT EXISTS leader_copy_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS preview_card_number TEXT,
  ADD COLUMN IF NOT EXISTS preview_variant_index INT,
  ADD COLUMN IF NOT EXISTS max_copies_of_single_card INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS main_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS favorite BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE auth.saved_decks
  ALTER COLUMN deck DROP NOT NULL;

ALTER TABLE auth.saved_decks
  DROP CONSTRAINT IF EXISTS saved_decks_kind_check,
  DROP CONSTRAINT IF EXISTS saved_decks_leader_copy_count_check,
  DROP CONSTRAINT IF EXISTS saved_decks_preview_variant_index_check,
  DROP CONSTRAINT IF EXISTS saved_decks_leader_variant_index_check,
  DROP CONSTRAINT IF EXISTS saved_decks_main_count_check,
  DROP CONSTRAINT IF EXISTS saved_decks_max_copies_check,
  DROP CONSTRAINT IF EXISTS saved_decks_user_folder_fk;

ALTER TABLE auth.saved_decks
  ADD CONSTRAINT saved_decks_kind_check CHECK (kind IN ('deck', 'list')),
  ADD CONSTRAINT saved_decks_leader_copy_count_check CHECK (leader_copy_count >= 0),
  ADD CONSTRAINT saved_decks_leader_variant_index_check CHECK (leader_variant_index IS NULL OR leader_variant_index >= 0),
  ADD CONSTRAINT saved_decks_preview_variant_index_check CHECK (preview_variant_index IS NULL OR preview_variant_index >= 0),
  ADD CONSTRAINT saved_decks_main_count_check CHECK (main_count >= 0),
  ADD CONSTRAINT saved_decks_max_copies_check CHECK (max_copies_of_single_card >= 0),
  ADD CONSTRAINT saved_decks_user_folder_fk
    FOREIGN KEY (user_id, folder_id)
    REFERENCES auth.deck_folders(user_id, id)
    ON DELETE SET NULL (folder_id);

CREATE INDEX IF NOT EXISTS saved_decks_user_folder_updated_idx
  ON auth.saved_decks(user_id, folder_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS saved_decks_user_favorite_updated_idx
  ON auth.saved_decks(user_id, favorite DESC, updated_at DESC);

CREATE INDEX IF NOT EXISTS saved_decks_user_hash_idx
  ON auth.saved_decks(user_id, deck_hash)
  WHERE deck_hash IS NOT NULL;

COMMENT ON TABLE auth.deck_folders IS
  'Account-owned folders for organizing saved deck collections.';

COMMENT ON COLUMN auth.saved_decks.deck_hash IS
  'Canonical deck collection payload used as gameplay authority.';

COMMENT ON COLUMN auth.saved_decks.deck IS
  'Optional decoded deck cache for editor/UI compatibility; not gameplay authority.';
