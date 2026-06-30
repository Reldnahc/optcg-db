ALTER TABLE cards
  DROP CONSTRAINT IF EXISTS cards_effect_source_check,
  DROP CONSTRAINT IF EXISTS cards_trigger_source_check;

ALTER TABLE cards
  ADD CONSTRAINT cards_effect_source_check
    CHECK (effect_source IN ('bandai', 'manual', 'spoiler_raw', 'spoiler_llm')),
  ADD CONSTRAINT cards_trigger_source_check
    CHECK (trigger_source IN ('bandai', 'manual', 'spoiler_raw', 'spoiler_llm'));

CREATE TABLE IF NOT EXISTS card_rules_text_ingest_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_number TEXT NOT NULL,
  language TEXT NOT NULL DEFAULT 'en',
  source TEXT NOT NULL DEFAULT 'discord_spoiler',
  discord_channel_id TEXT,
  discord_message_id TEXT,
  raw_effect TEXT,
  raw_trigger TEXT,
  raw_validation JSONB,
  normalized_effect TEXT,
  normalized_trigger TEXT,
  normalized_validation JSONB,
  llm_model TEXT,
  llm_prompt_version TEXT,
  status TEXT NOT NULL CHECK (status IN ('raw_supported', 'llm_supported', 'unsupported')),
  active_effect_source TEXT CHECK (active_effect_source IN ('spoiler_raw', 'spoiler_llm')),
  active_trigger_source TEXT CHECK (active_trigger_source IN ('spoiler_raw', 'spoiler_llm')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS card_rules_text_ingest_attempts_card_language_created_idx
  ON card_rules_text_ingest_attempts (card_number, language, created_at DESC);

CREATE INDEX IF NOT EXISTS card_rules_text_ingest_attempts_discord_message_idx
  ON card_rules_text_ingest_attempts (discord_message_id)
  WHERE discord_message_id IS NOT NULL;
