CREATE SCHEMA IF NOT EXISTS sim;

CREATE TABLE IF NOT EXISTS sim.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status TEXT NOT NULL DEFAULT 'active',
  game_type TEXT NOT NULL,
  format_id TEXT NOT NULL,
  ladder_id TEXT,
  lobby_id TEXT,
  queue_id TEXT,
  creation_source JSONB NOT NULL DEFAULT '{}'::jsonb,
  spectator_policy JSONB NOT NULL DEFAULT '{}'::jsonb,
  disconnect_policy JSONB NOT NULL DEFAULT '{}'::jsonb,
  rollback_policy JSONB NOT NULL DEFAULT '{}'::jsonb,
  runtime_versions JSONB NOT NULL,
  card_manifest_hash TEXT NOT NULL,
  card_manifest_snapshot JSONB NOT NULL,
  first_player_seat_id TEXT,
  first_player_chooser_seat_id TEXT,
  winner_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  winner_seat_id TEXT,
  result_reason TEXT,
  win_type TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ,
  turn_count INTEGER,
  action_count INTEGER NOT NULL DEFAULT 0,
  final_state_hash TEXT,
  final_state_seq INTEGER,
  error_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT sim_matches_status_check
    CHECK (status IN ('active', 'completed', 'draw', 'abandoned', 'errored', 'no_contest')),
  CONSTRAINT sim_matches_game_type_check
    CHECK (game_type IN ('ranked', 'unranked', 'custom', 'dev')),
  CONSTRAINT sim_matches_ranked_ladder_check
    CHECK ((game_type = 'ranked' AND ladder_id IS NOT NULL) OR game_type <> 'ranked'),
  CONSTRAINT sim_matches_completed_ended_at_check
    CHECK (
      status NOT IN ('completed', 'draw', 'abandoned', 'errored', 'no_contest')
      OR ended_at IS NOT NULL
    ),
  CONSTRAINT sim_matches_turn_count_check
    CHECK (turn_count IS NULL OR turn_count >= 0),
  CONSTRAINT sim_matches_action_count_check
    CHECK (action_count >= 0),
  CONSTRAINT sim_matches_final_state_seq_check
    CHECK (final_state_seq IS NULL OR final_state_seq >= 0)
);

CREATE TABLE IF NOT EXISTS sim.match_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES sim.matches(id) ON DELETE CASCADE,
  seat_id TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  saved_deck_id UUID REFERENCES auth.saved_decks(id) ON DELETE SET NULL,
  handoff_token_id UUID REFERENCES auth.sim_handoff_tokens(id) ON DELETE SET NULL,
  display_name TEXT,
  leader_card_number TEXT NOT NULL,
  leader_variant_index INTEGER,
  deck_hash TEXT,
  deck_snapshot JSONB NOT NULL,
  resolved_loadout_snapshot JSONB NOT NULL,
  cosmetic_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  starting_deck_order_hash TEXT,
  result TEXT,
  result_reason TEXT,
  went_first BOOLEAN,
  chose_first BOOLEAN,
  is_winner BOOLEAN NOT NULL DEFAULT false,
  final_life_count INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT sim_match_players_unique_seat UNIQUE (match_id, seat_id),
  CONSTRAINT sim_match_players_unique_user UNIQUE (match_id, user_id),
  CONSTRAINT sim_match_players_seat_id_check CHECK (char_length(seat_id) BETWEEN 1 AND 32),
  CONSTRAINT sim_match_players_result_check
    CHECK (result IS NULL OR result IN ('win', 'loss', 'draw', 'no_contest', 'abandoned', 'errored')),
  CONSTRAINT sim_match_players_leader_variant_index_check
    CHECK (leader_variant_index IS NULL OR leader_variant_index >= 0),
  CONSTRAINT sim_match_players_final_life_count_check
    CHECK (final_life_count IS NULL OR final_life_count >= 0)
);

CREATE TABLE IF NOT EXISTS sim.match_replays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE REFERENCES sim.matches(id) ON DELETE CASCADE,
  replay_format_version TEXT NOT NULL,
  engine_version TEXT NOT NULL,
  rules_version TEXT NOT NULL,
  card_data_version TEXT NOT NULL,
  effect_definitions_version TEXT NOT NULL,
  custom_handler_version TEXT NOT NULL,
  banlist_version TEXT NOT NULL,
  protocol_version TEXT NOT NULL,
  rng_algorithm TEXT NOT NULL,
  rng_seed_commitment TEXT,
  rng_seed_revealed TEXT,
  manifest_hash TEXT NOT NULL,
  manifest_snapshot JSONB NOT NULL,
  initial_state_hash TEXT NOT NULL,
  final_state_hash TEXT,
  initial_snapshot JSONB,
  initial_deck_orders JSONB,
  deterministic_entries JSONB NOT NULL,
  audit_entries JSONB NOT NULL DEFAULT '[]'::jsonb,
  checkpoints JSONB NOT NULL DEFAULT '[]'::jsonb,
  final_state JSONB,
  compressed BOOLEAN NOT NULL DEFAULT false,
  artifact_storage TEXT,
  artifact_key TEXT,
  artifact_sha256 TEXT,
  artifact_size_bytes BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT sim_match_replays_rng_algorithm_check
    CHECK (rng_algorithm IN ('pcg32', 'xoshiro256ss', 'test-fixed')),
  CONSTRAINT sim_match_replays_reconstructable_check
    CHECK (
      initial_snapshot IS NOT NULL
      OR (rng_seed_revealed IS NOT NULL AND initial_deck_orders IS NOT NULL)
    ),
  CONSTRAINT sim_match_replays_artifact_size_check
    CHECK (artifact_size_bytes IS NULL OR artifact_size_bytes >= 0),
  CONSTRAINT sim_match_replays_artifact_pair_check
    CHECK (
      (artifact_storage IS NULL AND artifact_key IS NULL)
      OR (artifact_storage IS NOT NULL AND artifact_key IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS sim.match_rollbacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES sim.matches(id) ON DELETE CASCADE,
  mode TEXT NOT NULL,
  rollback_class TEXT NOT NULL,
  from_state_seq INTEGER NOT NULL,
  to_state_seq INTEGER NOT NULL,
  requested_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_by_user_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  admin_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT sim_match_rollbacks_mode_check
    CHECK (mode IN ('mutual', 'judge', 'auto')),
  CONSTRAINT sim_match_rollbacks_class_check
    CHECK (rollback_class IN ('safe', 'hidden-info-exposed', 'judge-only', 'not-rollbackable')),
  CONSTRAINT sim_match_rollbacks_seq_check CHECK (from_state_seq >= to_state_seq),
  CONSTRAINT sim_match_rollbacks_reason_check CHECK (char_length(reason) BETWEEN 1 AND 1000)
);

CREATE INDEX IF NOT EXISTS sim_matches_status_started_idx
  ON sim.matches(status, started_at DESC);

CREATE INDEX IF NOT EXISTS sim_matches_completed_format_started_idx
  ON sim.matches(game_type, format_id, started_at DESC)
  WHERE status IN ('completed', 'draw');

CREATE INDEX IF NOT EXISTS sim_matches_ladder_started_idx
  ON sim.matches(ladder_id, started_at DESC)
  WHERE ladder_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS sim_matches_winner_idx
  ON sim.matches(winner_user_id, ended_at DESC)
  WHERE winner_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS sim_match_players_user_match_idx
  ON sim.match_players(user_id, match_id)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS sim_match_players_saved_deck_idx
  ON sim.match_players(saved_deck_id)
  WHERE saved_deck_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS sim_match_players_handoff_token_idx
  ON sim.match_players(handoff_token_id)
  WHERE handoff_token_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS sim_match_players_leader_idx
  ON sim.match_players(leader_card_number);

CREATE INDEX IF NOT EXISTS sim_match_players_match_leader_idx
  ON sim.match_players(match_id, leader_card_number);

CREATE INDEX IF NOT EXISTS sim_match_replays_match_idx
  ON sim.match_replays(match_id);

CREATE INDEX IF NOT EXISTS sim_match_rollbacks_match_created_idx
  ON sim.match_rollbacks(match_id, created_at DESC);

COMMENT ON SCHEMA sim IS
  'Simulator-owned durable match, replay, and stats data. Account authority remains in auth.';

COMMENT ON TABLE sim.match_players IS
  'One row per player seat in a simulator match. Stores match-time loadout snapshots for replay and meta stats.';

COMMENT ON COLUMN sim.match_players.resolved_loadout_snapshot IS
  'Authoritative loadout package resolved server-side at match join time; historical and not recomputed from current account decks.';

COMMENT ON COLUMN sim.match_players.deck_snapshot IS
  'Normalized match-time decklist snapshot used for replay/meta; current auth.saved_decks rows are not historical authority.';
