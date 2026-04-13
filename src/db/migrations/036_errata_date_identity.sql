ALTER TABLE card_image_errata
  DROP CONSTRAINT IF EXISTS card_image_errata_card_image_id_ordinal_key;

DROP INDEX IF EXISTS idx_card_image_errata_card_image_id;

ALTER TABLE card_image_errata
  DROP COLUMN IF EXISTS ordinal;

ALTER TABLE card_image_errata
  ADD COLUMN IF NOT EXISTS errata_date DATE;

ALTER TABLE card_image_errata
  ALTER COLUMN errata_date SET NOT NULL;

ALTER TABLE card_image_errata
  ADD CONSTRAINT card_image_errata_card_image_id_errata_date_key UNIQUE (card_image_id, errata_date);

CREATE INDEX idx_card_image_errata_card_image_id
  ON card_image_errata(card_image_id, errata_date);
