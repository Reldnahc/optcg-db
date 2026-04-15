ALTER TABLE products
  ADD COLUMN IF NOT EXISTS slug TEXT;

DO $$
DECLARE
  product_record RECORD;
  base_slug TEXT;
  candidate_slug TEXT;
  suffix INTEGER;
BEGIN
  FOR product_record IN
    SELECT
      id,
      language,
      COALESCE(
        NULLIF(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              LOWER(TRIM(name)),
              '[^a-z0-9]+',
              '-',
              'g'
            ),
            '(^-+|-+$)',
            '',
            'g'
          ),
          ''
        ),
        'product'
      ) AS normalized_base_slug
    FROM products
    WHERE slug IS NULL OR BTRIM(slug) = ''
    ORDER BY language, name, id
  LOOP
    base_slug := product_record.normalized_base_slug;
    candidate_slug := base_slug;
    suffix := 2;

    WHILE EXISTS (
      SELECT 1
      FROM products p
      WHERE p.language = product_record.language
        AND p.id <> product_record.id
        AND p.slug = candidate_slug
    ) LOOP
      candidate_slug := base_slug || '-' || suffix::text;
      suffix := suffix + 1;
    END LOOP;

    UPDATE products
    SET slug = candidate_slug
    WHERE id = product_record.id;
  END LOOP;
END $$;

ALTER TABLE products
  ALTER COLUMN slug SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_products_language_slug
  ON products(language, slug);
