CREATE SCHEMA IF NOT EXISTS auth;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS auth.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  email TEXT,
  email_verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT users_username_lowercase_check CHECK (username = lower(username)),
  CONSTRAINT users_username_format_check CHECK (username ~ '^[a-z0-9][a-z0-9_]{2,23}$'),
  CONSTRAINT users_display_name_length_check CHECK (char_length(display_name) BETWEEN 3 AND 32)
);

CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique_lower_idx
  ON auth.users(lower(email))
  WHERE email IS NOT NULL;

CREATE TABLE IF NOT EXISTS auth.auth_password_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  password_hash TEXT NOT NULL,
  password_algorithm TEXT NOT NULL,
  password_params JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_used_at TIMESTAMPTZ,
  UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS auth.auth_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  token_hash_algorithm TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_ip INET,
  created_user_agent TEXT,
  UNIQUE (user_id, id)
);

CREATE INDEX IF NOT EXISTS auth_sessions_user_active_idx
  ON auth.auth_sessions(user_id)
  WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS auth_sessions_expires_at_idx
  ON auth.auth_sessions(expires_at);

CREATE TABLE IF NOT EXISTS auth.saved_decks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  deck_hash TEXT,
  deck JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT saved_decks_name_length_check CHECK (char_length(name) BETWEEN 1 AND 80),
  UNIQUE (user_id, id)
);

CREATE INDEX IF NOT EXISTS saved_decks_user_updated_idx
  ON auth.saved_decks(user_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS auth.saved_don_decks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT saved_don_decks_name_length_check CHECK (char_length(name) BETWEEN 1 AND 80),
  UNIQUE (user_id, id)
);

CREATE INDEX IF NOT EXISTS saved_don_decks_user_updated_idx
  ON auth.saved_don_decks(user_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS auth.cosmetics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slot TEXT NOT NULL,
  key TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  asset JSONB NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT cosmetics_slot_check CHECK (slot IN ('playmat', 'don_sleeve', 'deck_sleeve')),
  CONSTRAINT cosmetics_key_format_check CHECK (key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  UNIQUE (id, slot)
);

CREATE UNIQUE INDEX IF NOT EXISTS cosmetics_one_active_default_per_slot_idx
  ON auth.cosmetics(slot)
  WHERE active IS TRUE AND is_default IS TRUE;

CREATE INDEX IF NOT EXISTS cosmetics_slot_active_idx
  ON auth.cosmetics(slot, active);

INSERT INTO auth.cosmetics (slot, key, name, description, asset, is_default, active)
VALUES
  ('playmat', 'default_playmat', 'Default Playmat', 'Default Poneglyph playmat', '{"image_url": "/assets/cosmetics/default-playmat.png"}', true, true),
  ('don_sleeve', 'default_don_sleeves', 'Default DON!! Sleeves', 'Default DON!! sleeve back', '{"image_url": "/assets/cosmetics/default-don-sleeves.png"}', true, true),
  ('deck_sleeve', 'default_deck_sleeves', 'Default Deck Sleeves', 'Default main deck sleeve back', '{"image_url": "/assets/cosmetics/default-deck-sleeves.png"}', true, true)
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS auth.user_cosmetic_entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cosmetic_id UUID NOT NULL REFERENCES auth.cosmetics(id) ON DELETE CASCADE,
  source TEXT,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS user_cosmetic_entitlements_active_unique_idx
  ON auth.user_cosmetic_entitlements(user_id, cosmetic_id)
  WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS auth.loadouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  main_deck_id UUID NOT NULL REFERENCES auth.saved_decks(id) ON DELETE RESTRICT,
  don_deck_id UUID REFERENCES auth.saved_don_decks(id) ON DELETE RESTRICT,
  playmat_cosmetic_id UUID REFERENCES auth.cosmetics(id) ON DELETE RESTRICT,
  playmat_cosmetic_slot TEXT GENERATED ALWAYS AS ('playmat') STORED,
  don_sleeve_cosmetic_id UUID REFERENCES auth.cosmetics(id) ON DELETE RESTRICT,
  don_sleeve_cosmetic_slot TEXT GENERATED ALWAYS AS ('don_sleeve') STORED,
  deck_sleeve_cosmetic_id UUID REFERENCES auth.cosmetics(id) ON DELETE RESTRICT,
  deck_sleeve_cosmetic_slot TEXT GENERATED ALWAYS AS ('deck_sleeve') STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT loadouts_name_length_check CHECK (char_length(name) BETWEEN 1 AND 80),
  UNIQUE (user_id, id),
  FOREIGN KEY (user_id, main_deck_id) REFERENCES auth.saved_decks(user_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (user_id, don_deck_id) REFERENCES auth.saved_don_decks(user_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (playmat_cosmetic_id, playmat_cosmetic_slot) REFERENCES auth.cosmetics(id, slot) ON DELETE RESTRICT,
  FOREIGN KEY (don_sleeve_cosmetic_id, don_sleeve_cosmetic_slot) REFERENCES auth.cosmetics(id, slot) ON DELETE RESTRICT,
  FOREIGN KEY (deck_sleeve_cosmetic_id, deck_sleeve_cosmetic_slot) REFERENCES auth.cosmetics(id, slot) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS loadouts_user_updated_idx
  ON auth.loadouts(user_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS auth.sim_handoff_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES auth.auth_sessions(id) ON DELETE CASCADE,
  loadout_id UUID NOT NULL REFERENCES auth.loadouts(id) ON DELETE CASCADE,
  lobby_id TEXT,
  seat_id TEXT,
  token_id TEXT NOT NULL UNIQUE,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  FOREIGN KEY (user_id, session_id) REFERENCES auth.auth_sessions(user_id, id) ON DELETE CASCADE,
  FOREIGN KEY (user_id, loadout_id) REFERENCES auth.loadouts(user_id, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS sim_handoff_tokens_user_issued_idx
  ON auth.sim_handoff_tokens(user_id, issued_at DESC);
