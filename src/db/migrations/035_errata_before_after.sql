ALTER TABLE card_image_errata
  DROP COLUMN IF EXISTS notes;

ALTER TABLE card_image_errata
  ADD COLUMN IF NOT EXISTS before_text TEXT,
  ADD COLUMN IF NOT EXISTS after_text TEXT;
