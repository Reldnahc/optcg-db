CREATE TABLE IF NOT EXISTS scan_ingest_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  language TEXT NOT NULL DEFAULT 'en',
  label TEXT,
  source TEXT NOT NULL DEFAULT 'admin',
  status TEXT NOT NULL DEFAULT 'uploaded'
    CHECK (status IN ('uploaded', 'processing', 'processed', 'needs_review', 'failed', 'linked')),
  raw_prefix TEXT NOT NULL,
  processed_prefix TEXT NOT NULL,
  total_files INT NOT NULL DEFAULT 0,
  total_items INT NOT NULL DEFAULT 0,
  processed_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scan_ingest_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES scan_ingest_batches(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  s3_key TEXT NOT NULL,
  public_url TEXT NOT NULL,
  content_type TEXT,
  status TEXT NOT NULL DEFAULT 'uploaded'
    CHECK (status IN ('uploaded', 'processing', 'processed', 'failed')),
  detected_cards INT,
  processed_at TIMESTAMPTZ,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (batch_id, file_name)
);

CREATE TABLE IF NOT EXISTS scan_ingest_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES scan_ingest_batches(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES scan_ingest_files(id) ON DELETE CASCADE,
  ordinal INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending_review'
    CHECK (status IN ('pending_review', 'ready_to_link', 'linked', 'failed')),
  raw_card_number TEXT,
  raw_artist TEXT,
  card_number TEXT,
  artist TEXT,
  artist_present BOOLEAN NOT NULL DEFAULT false,
  artist_confidence TEXT,
  card_number_confidence TEXT,
  fuzzy_artist TEXT,
  fuzzy_artist_score NUMERIC(5,4),
  fuzzy_artist_matched BOOLEAN NOT NULL DEFAULT false,
  suggested_filename TEXT,
  filename_slug TEXT,
  duplicate_index INT NOT NULL DEFAULT 0,
  processed_s3_key TEXT,
  processed_url TEXT,
  linked_card_id UUID REFERENCES cards(id),
  linked_card_image_id UUID REFERENCES card_images(id),
  review_notes TEXT,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (file_id, ordinal)
);

CREATE INDEX IF NOT EXISTS idx_scan_ingest_batches_status
  ON scan_ingest_batches(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_scan_ingest_files_batch_id
  ON scan_ingest_files(batch_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_scan_ingest_items_batch_id
  ON scan_ingest_items(batch_id, ordinal ASC);

CREATE INDEX IF NOT EXISTS idx_scan_ingest_items_status
  ON scan_ingest_items(status, created_at DESC);
