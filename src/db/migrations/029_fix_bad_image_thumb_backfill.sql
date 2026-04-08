UPDATE card_images
SET image_thumb_url = CASE
      WHEN split_part(image_url, '?', 1) ~* '/images/[^/]+/[^/]+/stock/\d+/full\.(png|jpe?g|webp)$'
        THEN regexp_replace(split_part(image_url, '?', 1), '/full\.(png|jpe?g|webp)$', '/thumb.webp', 'i')
             || CASE WHEN position('?' in image_url) > 0 THEN '?' || split_part(image_url, '?', 2) ELSE '' END
      WHEN split_part(image_url, '?', 1) ~* '/images/[a-z]+/[^/?#]+\.(png|jpe?g|webp)$'
        THEN substring(split_part(image_url, '?', 1) FROM '^(https?://[^/]+)')
             || '/images/'
             || substring(split_part(image_url, '?', 1) FROM '/images/([a-z]+)/')
             || '/thumbs/'
             || substring(split_part(image_url, '?', 1) FROM '/images/[a-z]+/([^/?#]+)\.(?:png|jpe?g|webp)$')
             || '.webp'
             || CASE WHEN position('?' in image_url) > 0 THEN '?' || split_part(image_url, '?', 2) ELSE '' END
      ELSE image_thumb_url
    END
WHERE NULLIF(BTRIM(image_url), '') IS NOT NULL
  AND (
    NULLIF(BTRIM(image_thumb_url), '') IS NULL
    OR image_thumb_url LIKE '%\\1%'
    OR image_thumb_url LIKE '%\\2%'
    OR image_thumb_url LIKE '%\\4%'
  );

INSERT INTO card_image_assets (card_image_id, role, public_url)
SELECT
  ci.id,
  'image_thumb',
  NULLIF(BTRIM(ci.image_thumb_url), '')
FROM card_images ci
WHERE NULLIF(BTRIM(ci.image_thumb_url), '') IS NOT NULL
ON CONFLICT (card_image_id, role) DO UPDATE
SET public_url = EXCLUDED.public_url
WHERE card_image_assets.public_url IS DISTINCT FROM EXCLUDED.public_url;
