ALTER TABLE card_images
  ADD COLUMN IF NOT EXISTS image_thumb_url TEXT;

UPDATE card_images
SET image_thumb_url = CASE
      WHEN image_url ~* '/images/[^/]+/[^/]+/stock/\d+/full\.(png|jpe?g|webp)(\?.*)?$'
        THEN regexp_replace(image_url, '/full\.(png|jpe?g|webp)(\?.*)?$', '/thumb.webp\2', 'i')
      WHEN image_url ~* '/images/[a-z]+/[^/?#]+\.(png|jpe?g|webp)(\?.*)?$'
        THEN regexp_replace(image_url, '/images/([a-z]+)/([^/?#]+)\.(png|jpe?g|webp)(\?.*)?$', '/images/\1/thumbs/\2.webp\4', 'i')
      ELSE image_thumb_url
    END
WHERE NULLIF(BTRIM(image_url), '') IS NOT NULL
  AND NULLIF(BTRIM(image_thumb_url), '') IS NULL;

INSERT INTO card_image_assets (card_image_id, role, public_url)
SELECT
  ci.id,
  'image_thumb',
  NULLIF(BTRIM(ci.image_thumb_url), '')
FROM card_images ci
WHERE NULLIF(BTRIM(ci.image_thumb_url), '') IS NOT NULL
ON CONFLICT (card_image_id, role) DO NOTHING;
