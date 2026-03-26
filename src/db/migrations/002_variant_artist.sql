-- Move artist tracking to the image/variant level.
-- Keep cards.artist as legacy/backfill data during transition, but stop treating it as canonical.

ALTER TABLE card_images
  ADD COLUMN IF NOT EXISTS artist TEXT,
  ADD COLUMN IF NOT EXISTS artist_ocr BOOLEAN NOT NULL DEFAULT false;

-- Backfill the default variant from the legacy card-level fields so existing prod data
-- still has an artist value in the most common display path.
UPDATE card_images ci
SET artist = c.artist,
    artist_ocr = c.artist_ocr
FROM cards c
WHERE ci.card_id = c.id
  AND ci.variant_index = 0
  AND (ci.artist IS NULL OR ci.artist = '')
  AND c.artist IS NOT NULL;
