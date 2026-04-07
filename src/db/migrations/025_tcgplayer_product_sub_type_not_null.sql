WITH ranked AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY tcgplayer_product_id, COALESCE(sub_type, '')
           ORDER BY
             (card_image_id IS NOT NULL) DESC,
             (don_card_id IS NOT NULL) DESC,
             updated_at DESC,
             created_at DESC,
             id ASC
         ) AS rn,
         FIRST_VALUE(id) OVER (
           PARTITION BY tcgplayer_product_id, COALESCE(sub_type, '')
           ORDER BY
             (card_image_id IS NOT NULL) DESC,
             (don_card_id IS NOT NULL) DESC,
             updated_at DESC,
             created_at DESC,
             id ASC
         ) AS keeper_id
  FROM tcgplayer_products
),
to_delete AS (
  SELECT id, keeper_id
  FROM ranked
  WHERE rn > 1
),
merged AS (
  UPDATE tcgplayer_products keeper
  SET name = COALESCE(NULLIF(keeper.name, ''), duplicate.name),
      clean_name = COALESCE(keeper.clean_name, duplicate.clean_name),
      ext_number = COALESCE(keeper.ext_number, duplicate.ext_number),
      ext_rarity = COALESCE(keeper.ext_rarity, duplicate.ext_rarity),
      group_id = COALESCE(keeper.group_id, duplicate.group_id),
      tcgplayer_url = COALESCE(keeper.tcgplayer_url, duplicate.tcgplayer_url),
      image_url = COALESCE(keeper.image_url, duplicate.image_url),
      card_image_id = COALESCE(keeper.card_image_id, duplicate.card_image_id),
      don_card_id = COALESCE(keeper.don_card_id, duplicate.don_card_id),
      product_type = COALESCE(NULLIF(keeper.product_type, ''), duplicate.product_type),
      updated_at = GREATEST(keeper.updated_at, duplicate.updated_at)
  FROM to_delete td
  JOIN tcgplayer_products duplicate ON duplicate.id = td.id
  WHERE keeper.id = td.keeper_id
)
DELETE FROM tcgplayer_products duplicate
USING to_delete td
WHERE duplicate.id = td.id;

UPDATE tcgplayer_products
SET sub_type = ''
WHERE sub_type IS NULL;

ALTER TABLE tcgplayer_products
  ALTER COLUMN sub_type SET DEFAULT '',
  ALTER COLUMN sub_type SET NOT NULL;

UPDATE tcgplayer_prices
SET sub_type = ''
WHERE sub_type IS NULL;

ALTER TABLE tcgplayer_prices
  ALTER COLUMN sub_type SET DEFAULT '',
  ALTER COLUMN sub_type SET NOT NULL;
