ALTER TABLE scan_ingest_items
  ADD COLUMN IF NOT EXISTS artist_crop_s3_key TEXT,
  ADD COLUMN IF NOT EXISTS artist_crop_url TEXT,
  ADD COLUMN IF NOT EXISTS footer_crop_s3_key TEXT,
  ADD COLUMN IF NOT EXISTS footer_crop_url TEXT;
