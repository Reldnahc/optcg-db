CREATE TABLE IF NOT EXISTS sleeves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  language TEXT NOT NULL DEFAULT 'en'
    CHECK (language IN ('en', 'ja', 'fr', 'zh')),
  source TEXT NOT NULL DEFAULT 'manual'
    CHECK (source IN ('bandai', 'manual')),
  source_url TEXT,
  source_product_code TEXT,
  source_design_index INT NOT NULL DEFAULT 0,
  name TEXT NOT NULL,
  product_name TEXT,
  release_date DATE,
  delivery_month TEXT,
  msrp_amount NUMERIC(10,2),
  msrp_currency TEXT,
  contents TEXT,
  image_url TEXT,
  thumbnail_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sleeves_source_design_unique
  ON sleeves(source, language, source_product_code, source_design_index)
  WHERE source_product_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sleeves_language
  ON sleeves(language);

CREATE INDEX IF NOT EXISTS idx_sleeves_source_product_code
  ON sleeves(source_product_code)
  WHERE source_product_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sleeves_release_date
  ON sleeves(release_date);

CREATE INDEX IF NOT EXISTS idx_sleeves_name
  ON sleeves(name);

CREATE TABLE IF NOT EXISTS sleeve_image_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sleeve_id UUID NOT NULL REFERENCES sleeves(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN (
    'official_source',
    'official_display',
    'official_thumb',
    'scan_source',
    'scan_display',
    'scan_thumb'
  )),
  source TEXT NOT NULL CHECK (source IN ('bandai', 'admin_upload')),
  storage_key TEXT,
  public_url TEXT,
  source_url TEXT,
  content_type TEXT,
  width INT,
  height INT,
  byte_size BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (sleeve_id, role)
);

CREATE INDEX IF NOT EXISTS idx_sleeve_image_assets_sleeve_id
  ON sleeve_image_assets(sleeve_id);

CREATE INDEX IF NOT EXISTS idx_sleeve_image_assets_role
  ON sleeve_image_assets(role);

CREATE TABLE IF NOT EXISTS sleeve_scan_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT,
  status TEXT NOT NULL DEFAULT 'uploaded'
    CHECK (status IN ('uploaded', 'processing', 'processed', 'needs_review', 'failed', 'linked')),
  raw_prefix TEXT NOT NULL,
  total_files INT NOT NULL DEFAULT 0,
  total_items INT NOT NULL DEFAULT 0,
  processed_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sleeve_scan_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES sleeve_scan_batches(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  s3_key TEXT NOT NULL,
  public_url TEXT NOT NULL,
  content_type TEXT,
  status TEXT NOT NULL DEFAULT 'uploaded'
    CHECK (status IN ('uploaded', 'processing', 'processed', 'failed')),
  processed_at TIMESTAMPTZ,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (batch_id, file_name)
);

CREATE TABLE IF NOT EXISTS sleeve_scan_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES sleeve_scan_batches(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES sleeve_scan_files(id) ON DELETE CASCADE,
  ordinal INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending_review'
    CHECK (status IN ('pending_review', 'linked', 'failed')),
  source_s3_key TEXT,
  source_url TEXT,
  display_s3_key TEXT,
  display_url TEXT,
  thumb_s3_key TEXT,
  thumb_url TEXT,
  linked_sleeve_id UUID REFERENCES sleeves(id),
  review_notes TEXT,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (file_id, ordinal)
);

CREATE INDEX IF NOT EXISTS idx_sleeve_scan_batches_status
  ON sleeve_scan_batches(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sleeve_scan_files_batch_id
  ON sleeve_scan_files(batch_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_sleeve_scan_items_batch_id
  ON sleeve_scan_items(batch_id, ordinal ASC);

CREATE INDEX IF NOT EXISTS idx_sleeve_scan_items_status
  ON sleeve_scan_items(status, created_at DESC);

ALTER TABLE don_cards
  ADD COLUMN IF NOT EXISTS tcgplayer_product_id INT,
  ADD COLUMN IF NOT EXISTS tcgplayer_url TEXT,
  ADD COLUMN IF NOT EXISTS tcgplayer_image_url TEXT,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS clean_name TEXT,
  ADD COLUMN IF NOT EXISTS source_label TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_don_cards_tcgplayer_product_finish
  ON don_cards(tcgplayer_product_id, finish)
  WHERE tcgplayer_product_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS don_image_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  don_card_id UUID NOT NULL REFERENCES don_cards(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN (
    'tcgplayer_source',
    'tcgplayer_display',
    'tcgplayer_thumb',
    'scan_source',
    'scan_display',
    'scan_thumb'
  )),
  source TEXT NOT NULL CHECK (source IN ('tcgplayer', 'admin_upload')),
  storage_key TEXT,
  public_url TEXT,
  source_url TEXT,
  content_type TEXT,
  width INT,
  height INT,
  byte_size BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (don_card_id, role)
);

CREATE INDEX IF NOT EXISTS idx_don_image_assets_don_card_id
  ON don_image_assets(don_card_id);

CREATE INDEX IF NOT EXISTS idx_don_image_assets_role
  ON don_image_assets(role);

CREATE TABLE IF NOT EXISTS don_scan_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT,
  status TEXT NOT NULL DEFAULT 'uploaded'
    CHECK (status IN ('uploaded', 'processing', 'processed', 'needs_review', 'failed', 'linked')),
  raw_prefix TEXT NOT NULL,
  total_files INT NOT NULL DEFAULT 0,
  total_items INT NOT NULL DEFAULT 0,
  processed_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS don_scan_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES don_scan_batches(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  s3_key TEXT NOT NULL,
  public_url TEXT NOT NULL,
  content_type TEXT,
  status TEXT NOT NULL DEFAULT 'uploaded'
    CHECK (status IN ('uploaded', 'processing', 'processed', 'failed')),
  processed_at TIMESTAMPTZ,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (batch_id, file_name)
);

CREATE TABLE IF NOT EXISTS don_scan_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES don_scan_batches(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES don_scan_files(id) ON DELETE CASCADE,
  ordinal INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending_review'
    CHECK (status IN ('pending_review', 'linked', 'failed')),
  source_s3_key TEXT,
  source_url TEXT,
  display_s3_key TEXT,
  display_url TEXT,
  thumb_s3_key TEXT,
  thumb_url TEXT,
  linked_don_card_id UUID REFERENCES don_cards(id),
  review_notes TEXT,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (file_id, ordinal)
);

CREATE INDEX IF NOT EXISTS idx_don_scan_batches_status
  ON don_scan_batches(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_don_scan_files_batch_id
  ON don_scan_files(batch_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_don_scan_items_batch_id
  ON don_scan_items(batch_id, ordinal ASC);

CREATE INDEX IF NOT EXISTS idx_don_scan_items_status
  ON don_scan_items(status, created_at DESC);
