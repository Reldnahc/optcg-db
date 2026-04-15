ALTER TABLE products
  ADD COLUMN IF NOT EXISTS slug TEXT;

WITH slug_bases AS (
  SELECT
    id,
    language,
    name,
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
    ) AS base_slug
  FROM products
),
slug_candidates AS (
  SELECT
    id,
    language,
    COALESCE(base_slug, 'product') AS normalized_base_slug,
    ROW_NUMBER() OVER (
      PARTITION BY language, COALESCE(base_slug, 'product')
      ORDER BY id
    ) AS slug_rank
  FROM slug_bases
)
UPDATE products p
SET slug = CASE
  WHEN sc.slug_rank = 1 THEN sc.normalized_base_slug
  ELSE sc.normalized_base_slug || '-' || sc.slug_rank::text
END
FROM slug_candidates sc
WHERE p.id = sc.id
  AND (p.slug IS NULL OR BTRIM(p.slug) = '');

ALTER TABLE products
  ALTER COLUMN slug SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_products_language_slug
  ON products(language, slug);
