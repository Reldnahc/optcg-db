WITH ranked_products AS (
  SELECT
    p.id,
    p.language,
    p.name,
    p.product_set_code,
    p.set_codes,
    p.released_at,
    p.created_at,
    candidate.set_code,
    ROW_NUMBER() OVER (
      PARTITION BY p.language, candidate.set_code
      ORDER BY
        CASE WHEN p.product_set_code = candidate.set_code THEN 0 ELSE 1 END,
        array_length(p.set_codes, 1) ASC NULLS LAST,
        p.released_at ASC NULLS LAST,
        p.name ASC,
        p.created_at ASC,
        p.id ASC
    ) AS rank_in_set
  FROM products p
  CROSS JOIN LATERAL (
    SELECT DISTINCT set_code
    FROM (
      VALUES
        (p.product_set_code),
        (p.set_codes[1])
    ) AS raw(set_code)
  ) AS candidate
  WHERE p.source = 'bandai'
    AND candidate.set_code IS NOT NULL
    AND candidate.set_code <> 'P'
),
primary_products AS (
  SELECT
    language,
    set_code,
    id AS product_id
  FROM ranked_products
  WHERE rank_in_set = 1
),
updated_cards AS (
  UPDATE cards c
  SET
    product_id = pp.product_id,
    needs_product_resolution = false,
    updated_at = NOW()
  FROM primary_products pp
  WHERE c.product_id IS NULL
    AND c.needs_product_resolution = true
    AND c.true_set_code <> 'P'
    AND pp.language = c.language
    AND pp.set_code = c.true_set_code
  RETURNING c.id, c.product_id
),
inserted_sources AS (
  INSERT INTO card_sources (card_id, product_id)
  SELECT id, product_id
  FROM updated_cards
  ON CONFLICT (card_id, product_id) DO NOTHING
)
UPDATE card_images ci
SET product_id = c.product_id
FROM cards c
WHERE ci.card_id = c.id
  AND ci.product_id IS NULL
  AND c.product_id IS NOT NULL
  AND (
    ci.label = 'Standard'
    OR ci.variant_index = 0
  );
