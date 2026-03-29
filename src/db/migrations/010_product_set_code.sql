ALTER TABLE products
  ADD COLUMN IF NOT EXISTS product_set_code TEXT;

UPDATE products
SET product_set_code = CASE
  WHEN set_codes IS NULL OR array_length(set_codes, 1) IS NULL OR array_length(set_codes, 1) = 0 THEN NULL
  WHEN array_length(set_codes, 1) = 1 THEN set_codes[1]
  WHEN set_codes @> ARRAY['EB04']::text[] THEN (
    SELECT code
    FROM unnest(set_codes) AS code
    WHERE code <> 'EB04'
    LIMIT 1
  )
  ELSE set_codes[1]
END
WHERE product_set_code IS NULL;

CREATE INDEX IF NOT EXISTS idx_products_product_set_code
  ON products(product_set_code);
