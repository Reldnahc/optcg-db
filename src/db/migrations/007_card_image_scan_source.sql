ALTER TABLE card_images
  ADD COLUMN IF NOT EXISTS scan_source_s3_key TEXT,
  ADD COLUMN IF NOT EXISTS scan_source_url TEXT;
