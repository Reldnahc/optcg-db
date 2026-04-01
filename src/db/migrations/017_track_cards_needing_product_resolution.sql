ALTER TABLE cards
  ADD COLUMN IF NOT EXISTS needs_product_resolution BOOLEAN NOT NULL DEFAULT false;

UPDATE cards
SET needs_product_resolution = true
WHERE product_id IS NULL;

ALTER TABLE cards
  DROP CONSTRAINT IF EXISTS cards_product_resolution_state_check;

ALTER TABLE cards
  ADD CONSTRAINT cards_product_resolution_state_check
  CHECK (
    (product_id IS NULL AND needs_product_resolution = true)
    OR
    (product_id IS NOT NULL AND needs_product_resolution = false)
  );

CREATE INDEX IF NOT EXISTS idx_cards_needs_product_resolution
  ON cards(language, true_set_code)
  WHERE needs_product_resolution = true;
