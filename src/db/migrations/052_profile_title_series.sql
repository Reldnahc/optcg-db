CREATE TABLE IF NOT EXISTS auth.profile_title_series (
  key TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT profile_title_series_key_format_check
    CHECK (key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  CONSTRAINT profile_title_series_label_length_check
    CHECK (char_length(label) BETWEEN 1 AND 64),
  CONSTRAINT profile_title_series_description_length_check
    CHECK (description IS NULL OR char_length(description) <= 500)
);

CREATE INDEX IF NOT EXISTS profile_title_series_active_sort_idx
  ON auth.profile_title_series(active, sort_order, key);

ALTER TABLE auth.profile_titles
  ADD COLUMN IF NOT EXISTS series_key TEXT
    REFERENCES auth.profile_title_series(key) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS series_item_key TEXT,
  ADD COLUMN IF NOT EXISTS series_item_label TEXT,
  ADD COLUMN IF NOT EXISTS tier_key TEXT;

ALTER TABLE auth.profile_titles
  DROP CONSTRAINT IF EXISTS profile_titles_series_item_key_format_check,
  DROP CONSTRAINT IF EXISTS profile_titles_tier_key_format_check,
  DROP CONSTRAINT IF EXISTS profile_titles_series_item_label_length_check;

ALTER TABLE auth.profile_titles
  ADD CONSTRAINT profile_titles_series_item_key_format_check
    CHECK (series_item_key IS NULL OR series_item_key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  ADD CONSTRAINT profile_titles_tier_key_format_check
    CHECK (tier_key IS NULL OR tier_key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  ADD CONSTRAINT profile_titles_series_item_label_length_check
    CHECK (series_item_label IS NULL OR char_length(series_item_label) BETWEEN 1 AND 64);

CREATE INDEX IF NOT EXISTS profile_titles_series_idx
  ON auth.profile_titles(series_key, series_item_key, tier_key)
  WHERE series_key IS NOT NULL;
