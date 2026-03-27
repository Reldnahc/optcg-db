-- Replace one-shot OCR tracking with explicit workflow state on card_images.

ALTER TABLE card_images
  ADD COLUMN IF NOT EXISTS artist_source TEXT,
  ADD COLUMN IF NOT EXISTS artist_ocr_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS artist_ocr_candidate TEXT,
  ADD COLUMN IF NOT EXISTS artist_ocr_confidence TEXT,
  ADD COLUMN IF NOT EXISTS artist_ocr_attempts INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS artist_ocr_last_error TEXT,
  ADD COLUMN IF NOT EXISTS artist_ocr_last_run_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS artist_ocr_source_url TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'card_images_artist_source_check'
  ) THEN
    ALTER TABLE card_images
      ADD CONSTRAINT card_images_artist_source_check
      CHECK (artist_source IS NULL OR artist_source IN ('manual', 'scrape', 'ocr'));
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'card_images_artist_ocr_status_check'
  ) THEN
    ALTER TABLE card_images
      ADD CONSTRAINT card_images_artist_ocr_status_check
      CHECK (artist_ocr_status IN ('pending', 'processing', 'succeeded', 'failed', 'needs_review', 'skipped'));
  END IF;
END $$;

UPDATE card_images
SET artist_source = 'scrape',
    artist_ocr_status = 'succeeded',
    artist_ocr_attempts = GREATEST(artist_ocr_attempts, CASE WHEN artist_ocr THEN 1 ELSE 0 END)
WHERE artist IS NOT NULL
  AND btrim(artist) <> '';

UPDATE card_images
SET artist_ocr_status = 'failed',
    artist_ocr_attempts = GREATEST(artist_ocr_attempts, 1)
WHERE (artist IS NULL OR btrim(artist) = '')
  AND artist_ocr = true;

UPDATE card_images
SET artist_ocr_status = 'pending'
WHERE (artist IS NULL OR btrim(artist) = '')
  AND artist_ocr = false;

CREATE INDEX IF NOT EXISTS idx_card_images_artist_ocr_status
  ON card_images(artist_ocr_status);
