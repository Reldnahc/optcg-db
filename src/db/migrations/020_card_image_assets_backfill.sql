INSERT INTO card_image_assets (card_image_id, role, public_url, source_url)
SELECT
  ci.id,
  'image_url',
  NULLIF(BTRIM(ci.image_url), ''),
  NULLIF(BTRIM(ci.source_url), '')
FROM card_images ci
WHERE NULLIF(BTRIM(ci.image_url), '') IS NOT NULL
ON CONFLICT (card_image_id, role) DO NOTHING;

INSERT INTO card_image_assets (card_image_id, role, storage_key, public_url)
SELECT
  ci.id,
  'scan_source',
  NULLIF(BTRIM(ci.scan_source_s3_key), ''),
  NULLIF(BTRIM(ci.scan_source_url), '')
FROM card_images ci
WHERE NULLIF(BTRIM(COALESCE(ci.scan_source_s3_key, ci.scan_source_url)), '') IS NOT NULL
ON CONFLICT (card_image_id, role) DO NOTHING;

INSERT INTO card_image_assets (card_image_id, role, public_url)
SELECT
  ci.id,
  'scan_url',
  NULLIF(BTRIM(ci.scan_url), '')
FROM card_images ci
WHERE NULLIF(BTRIM(ci.scan_url), '') IS NOT NULL
ON CONFLICT (card_image_id, role) DO NOTHING;

INSERT INTO card_image_assets (card_image_id, role, storage_key, public_url)
SELECT
  ci.id,
  'scan_thumb',
  NULLIF(BTRIM(ci.scan_thumb_s3_key), ''),
  NULLIF(BTRIM(ci.scan_thumb_url), '')
FROM card_images ci
WHERE NULLIF(BTRIM(COALESCE(ci.scan_thumb_s3_key, ci.scan_thumb_url)), '') IS NOT NULL
ON CONFLICT (card_image_id, role) DO NOTHING;
