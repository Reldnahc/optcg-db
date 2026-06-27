CREATE TABLE IF NOT EXISTS auth.profile_titles (
  key TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  unlock_mode TEXT NOT NULL,
  style JSONB NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT profile_titles_key_format_check
    CHECK (key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  CONSTRAINT profile_titles_unlock_mode_check
    CHECK (unlock_mode IN ('no_requirement', 'manual')),
  CONSTRAINT profile_titles_label_length_check
    CHECK (char_length(label) BETWEEN 1 AND 64),
  CONSTRAINT profile_titles_style_object_check
    CHECK (jsonb_typeof(style) = 'object')
);

CREATE INDEX IF NOT EXISTS profile_titles_active_sort_idx
  ON auth.profile_titles(active, sort_order, key);

ALTER TABLE auth.user_profiles
  ADD COLUMN IF NOT EXISTS selected_title_key TEXT
    REFERENCES auth.profile_titles(key) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS user_profiles_selected_title_idx
  ON auth.user_profiles(selected_title_key)
  WHERE selected_title_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS auth.user_title_unlocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title_key TEXT NOT NULL REFERENCES auth.profile_titles(key) ON DELETE RESTRICT,
  granted_by_admin_email TEXT NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT user_title_unlocks_note_length_check
    CHECK (note IS NULL OR char_length(note) <= 500)
);

CREATE UNIQUE INDEX IF NOT EXISTS user_title_unlocks_active_unique_idx
  ON auth.user_title_unlocks(user_id, title_key)
  WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS user_title_unlocks_user_active_idx
  ON auth.user_title_unlocks(user_id, title_key)
  WHERE revoked_at IS NULL;

INSERT INTO auth.profile_titles (key, label, unlock_mode, style, active, sort_order)
VALUES
  (
    'pirate_rookie',
    'Pirate Rookie',
    'no_requirement',
    '{"text_color":"#e8e9ed","font_family":"display","font_weight":700,"animation":"none"}',
    true,
    10
  ),
  (
    'founder_gold',
    'Founder',
    'manual',
    '{"text_color":"#ffd76a","font_family":"display","font_weight":800,"gradient":{"from":"#fff1a8","to":"#d4a94c","angle":90},"glow_color":"#d4a94c","animation":"shine"}',
    true,
    20
  )
ON CONFLICT (key) DO UPDATE SET
  label = EXCLUDED.label,
  unlock_mode = EXCLUDED.unlock_mode,
  style = EXCLUDED.style,
  active = EXCLUDED.active,
  sort_order = EXCLUDED.sort_order,
  updated_at = now();
