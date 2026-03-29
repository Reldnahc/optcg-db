ALTER TABLE card_images
  ADD COLUMN IF NOT EXISTS scan_thumb_s3_key TEXT,
  ADD COLUMN IF NOT EXISTS scan_thumb_url TEXT;
