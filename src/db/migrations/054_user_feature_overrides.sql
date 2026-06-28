CREATE TABLE IF NOT EXISTS auth.user_feature_overrides (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  granted_by_admin_email TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, feature_key),
  CONSTRAINT user_feature_overrides_feature_key_check
    CHECK (feature_key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  CONSTRAINT user_feature_overrides_note_length_check
    CHECK (note IS NULL OR char_length(note) <= 500)
);

CREATE INDEX IF NOT EXISTS user_feature_overrides_enabled_idx
  ON auth.user_feature_overrides(user_id, feature_key)
  WHERE enabled IS TRUE;
