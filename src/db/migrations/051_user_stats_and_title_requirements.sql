CREATE TABLE IF NOT EXISTS auth.user_stats (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stat_key TEXT NOT NULL,
  value BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, stat_key),
  CONSTRAINT user_stats_stat_key_format_check
    CHECK (stat_key ~ '^[A-Za-z0-9_:-]+$'),
  CONSTRAINT user_stats_value_nonnegative_check
    CHECK (value >= 0)
);

CREATE INDEX IF NOT EXISTS user_stats_stat_key_value_idx
  ON auth.user_stats(stat_key, value DESC);

CREATE TABLE IF NOT EXISTS auth.user_stat_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type TEXT NOT NULL,
  source_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stat_key TEXT NOT NULL,
  operation TEXT NOT NULL,
  value BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT user_stat_events_source_type_format_check
    CHECK (source_type ~ '^[a-z0-9][a-z0-9_-]*$'),
  CONSTRAINT user_stat_events_source_id_format_check
    CHECK (source_id ~ '^[A-Za-z0-9_.:-]+$'),
  CONSTRAINT user_stat_events_stat_key_format_check
    CHECK (stat_key ~ '^[A-Za-z0-9_:-]+$'),
  CONSTRAINT user_stat_events_operation_check
    CHECK (operation IN ('increment', 'set', 'max')),
  CONSTRAINT user_stat_events_value_nonnegative_check
    CHECK (value >= 0),
  CONSTRAINT user_stat_events_source_unique
    UNIQUE (source_type, source_id, user_id, stat_key, operation)
);

CREATE INDEX IF NOT EXISTS user_stat_events_user_created_idx
  ON auth.user_stat_events(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS auth.user_stat_daily_activity (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  play_date DATE NOT NULL,
  first_source_type TEXT NOT NULL,
  first_source_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, play_date),
  CONSTRAINT user_stat_daily_activity_source_type_format_check
    CHECK (first_source_type ~ '^[a-z0-9][a-z0-9_-]*$'),
  CONSTRAINT user_stat_daily_activity_source_id_format_check
    CHECK (first_source_id ~ '^[A-Za-z0-9_.:-]+$')
);

CREATE INDEX IF NOT EXISTS user_stat_daily_activity_user_play_date_idx
  ON auth.user_stat_daily_activity(user_id, play_date DESC);

ALTER TABLE auth.profile_titles
  DROP CONSTRAINT IF EXISTS profile_titles_unlock_mode_check;

ALTER TABLE auth.profile_titles
  ADD CONSTRAINT profile_titles_unlock_mode_check
    CHECK (unlock_mode IN ('no_requirement', 'manual', 'automatic'));

CREATE TABLE IF NOT EXISTS auth.profile_title_requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title_key TEXT NOT NULL REFERENCES auth.profile_titles(key) ON DELETE CASCADE,
  stat_key TEXT NOT NULL,
  operator TEXT NOT NULL DEFAULT 'gte',
  threshold BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT profile_title_requirements_stat_key_format_check
    CHECK (stat_key ~ '^[A-Za-z0-9_:-]+$'),
  CONSTRAINT profile_title_requirements_operator_check
    CHECK (operator IN ('gte')),
  CONSTRAINT profile_title_requirements_threshold_positive_check
    CHECK (threshold > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS profile_title_requirements_unique_idx
  ON auth.profile_title_requirements(title_key, stat_key, operator, threshold);

CREATE INDEX IF NOT EXISTS profile_title_requirements_title_idx
  ON auth.profile_title_requirements(title_key);

CREATE INDEX IF NOT EXISTS profile_title_requirements_stat_idx
  ON auth.profile_title_requirements(stat_key);
