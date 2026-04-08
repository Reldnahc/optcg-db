-- API query support indexes for public card/random endpoints.
--
-- Why these:
-- 1. Latest-price lookups repeatedly do:
--      WHERE tcgplayer_product_id = ? AND sub_type = ?
--      ORDER BY fetched_at DESC
--      LIMIT 1
--    The old schema only had separate indexes on product_id and fetched_at.
--
-- 2. Variant fetches repeatedly do:
--      WHERE card_id = ? AND classified = true
--    or:
--      WHERE card_id = ANY(...) AND classified = true
--
-- 3. Random-card selection now does:
--      WHERE language = ?
--      ORDER BY id
--      LIMIT 1 OFFSET n
--
-- The card_image_assets table already has a UNIQUE(card_image_id, role)
-- constraint, which provides the composite access path for per-role asset reads.

CREATE INDEX IF NOT EXISTS idx_tcgplayer_prices_product_sub_type_fetched_at_desc
  ON tcgplayer_prices(tcgplayer_product_id, sub_type, fetched_at DESC);

CREATE INDEX IF NOT EXISTS idx_card_images_card_id_classified_true
  ON card_images(card_id)
  WHERE classified = true;

CREATE INDEX IF NOT EXISTS idx_cards_language_id
  ON cards(language, id);
