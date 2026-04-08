-- Safety net for databases that already marked 026 as applied before it
-- added/backfilled card_images.image_thumb_url.
ALTER TABLE card_images
  ADD COLUMN IF NOT EXISTS image_thumb_url TEXT;
