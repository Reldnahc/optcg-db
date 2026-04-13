ALTER TABLE scan_ingest_items
  ADD COLUMN IF NOT EXISTS linked_card_errata_id UUID REFERENCES card_image_errata(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_scan_ingest_items_linked_card_errata_id
  ON scan_ingest_items(linked_card_errata_id);
