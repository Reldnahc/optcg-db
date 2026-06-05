CREATE TABLE IF NOT EXISTS tcgcsv_sync_state (
  source                   TEXT PRIMARY KEY,
  upstream_last_updated    TEXT NOT NULL,
  upstream_last_updated_at TIMESTAMPTZ NOT NULL,
  last_successful_sync_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);
