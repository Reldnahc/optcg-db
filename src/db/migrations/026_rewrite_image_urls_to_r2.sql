-- Rewrites all stored image URLs and S3 keys from the legacy AWS S3 layouts
-- to the canonical R2 layout served by https://cdn.poneglyph.one.
-- See image-migration-plan.md for the path mapping. This migration runs
-- AFTER the one-shot S3 -> R2 object copy (cli/migrate-images-to-r2.ts) so
-- that every URL it writes already resolves to a real object.
--
-- The new path scheme is fully derivable from (card_number, language,
-- variant_index, role), so each UPDATE here is idempotent: re-running it
-- always produces the same canonical value.

DO $$
DECLARE
  cdn TEXT := 'https://cdn.poneglyph.one';
BEGIN
  ----------------------------------------------------------------------------
  -- card_images: scalar URL/key columns
  ----------------------------------------------------------------------------

  -- Stock full image
  UPDATE card_images ci
  SET image_url = format(
        '%s/images/%s/%s/stock/%s/full.png',
        cdn, upper(c.card_number), lower(c.language), ci.variant_index
      )
  FROM cards c
  WHERE c.id = ci.card_id
    AND ci.image_url IS NOT NULL;

  -- Linked scan full
  UPDATE card_images ci
  SET scan_url = format(
        '%s/images/%s/%s/scans/%s/full.png',
        cdn, upper(c.card_number), lower(c.language), ci.variant_index
      )
  FROM cards c
  WHERE c.id = ci.card_id
    AND ci.scan_url IS NOT NULL;

  -- Linked scan thumb (url + s3 key)
  UPDATE card_images ci
  SET scan_thumb_url = format(
        '%s/images/%s/%s/scans/%s/thumb.webp',
        cdn, upper(c.card_number), lower(c.language), ci.variant_index
      ),
      scan_thumb_s3_key = format(
        'images/%s/%s/scans/%s/thumb.webp',
        upper(c.card_number), lower(c.language), ci.variant_index
      )
  FROM cards c
  WHERE c.id = ci.card_id
    AND (ci.scan_thumb_url IS NOT NULL OR ci.scan_thumb_s3_key IS NOT NULL);

  -- Scan source master (extension preserved from the old value)
  UPDATE card_images ci
  SET scan_source_url = format(
        '%s/images/%s/%s/scans/%s/source%s',
        cdn, upper(c.card_number), lower(c.language), ci.variant_index,
        CASE
          WHEN COALESCE(ci.scan_source_s3_key, ci.scan_source_url, '') ~* '\.jpe?g(\?|$)' THEN '.jpg'
          WHEN COALESCE(ci.scan_source_s3_key, ci.scan_source_url, '') ~* '\.webp(\?|$)' THEN '.webp'
          ELSE '.png'
        END
      ),
      scan_source_s3_key = format(
        'images/%s/%s/scans/%s/source%s',
        upper(c.card_number), lower(c.language), ci.variant_index,
        CASE
          WHEN COALESCE(ci.scan_source_s3_key, ci.scan_source_url, '') ~* '\.jpe?g(\?|$)' THEN '.jpg'
          WHEN COALESCE(ci.scan_source_s3_key, ci.scan_source_url, '') ~* '\.webp(\?|$)' THEN '.webp'
          ELSE '.png'
        END
      )
  FROM cards c
  WHERE c.id = ci.card_id
    AND (ci.scan_source_url IS NOT NULL OR ci.scan_source_s3_key IS NOT NULL);

  ----------------------------------------------------------------------------
  -- card_image_assets: one UPDATE per role
  ----------------------------------------------------------------------------

  UPDATE card_image_assets a
  SET public_url  = format('%s/images/%s/%s/stock/%s/full.png',
                           cdn, upper(c.card_number), lower(c.language), ci.variant_index),
      storage_key = format('images/%s/%s/stock/%s/full.png',
                           upper(c.card_number), lower(c.language), ci.variant_index)
  FROM card_images ci
  JOIN cards c ON c.id = ci.card_id
  WHERE a.card_image_id = ci.id
    AND a.role = 'image_url';

  UPDATE card_image_assets a
  SET public_url  = format('%s/images/%s/%s/stock/%s/thumb.webp',
                           cdn, upper(c.card_number), lower(c.language), ci.variant_index),
      storage_key = format('images/%s/%s/stock/%s/thumb.webp',
                           upper(c.card_number), lower(c.language), ci.variant_index)
  FROM card_images ci
  JOIN cards c ON c.id = ci.card_id
  WHERE a.card_image_id = ci.id
    AND a.role = 'image_thumb';

  UPDATE card_image_assets a
  SET public_url  = format('%s/images/%s/%s/scans/%s/full.png',
                           cdn, upper(c.card_number), lower(c.language), ci.variant_index),
      storage_key = format('images/%s/%s/scans/%s/full.png',
                           upper(c.card_number), lower(c.language), ci.variant_index)
  FROM card_images ci
  JOIN cards c ON c.id = ci.card_id
  WHERE a.card_image_id = ci.id
    AND a.role = 'scan_url';

  UPDATE card_image_assets a
  SET public_url  = format('%s/images/%s/%s/scans/%s/display.webp',
                           cdn, upper(c.card_number), lower(c.language), ci.variant_index),
      storage_key = format('images/%s/%s/scans/%s/display.webp',
                           upper(c.card_number), lower(c.language), ci.variant_index)
  FROM card_images ci
  JOIN cards c ON c.id = ci.card_id
  WHERE a.card_image_id = ci.id
    AND a.role = 'scan_display';

  UPDATE card_image_assets a
  SET public_url  = format('%s/images/%s/%s/scans/%s/thumb.webp',
                           cdn, upper(c.card_number), lower(c.language), ci.variant_index),
      storage_key = format('images/%s/%s/scans/%s/thumb.webp',
                           upper(c.card_number), lower(c.language), ci.variant_index)
  FROM card_images ci
  JOIN cards c ON c.id = ci.card_id
  WHERE a.card_image_id = ci.id
    AND a.role = 'scan_thumb';

  UPDATE card_image_assets a
  SET public_url  = format(
        '%s/images/%s/%s/scans/%s/source%s',
        cdn, upper(c.card_number), lower(c.language), ci.variant_index,
        CASE
          WHEN COALESCE(a.storage_key, a.public_url, '') ~* '\.jpe?g(\?|$)' THEN '.jpg'
          WHEN COALESCE(a.storage_key, a.public_url, '') ~* '\.webp(\?|$)' THEN '.webp'
          ELSE '.png'
        END),
      storage_key = format(
        'images/%s/%s/scans/%s/source%s',
        upper(c.card_number), lower(c.language), ci.variant_index,
        CASE
          WHEN COALESCE(a.storage_key, a.public_url, '') ~* '\.jpe?g(\?|$)' THEN '.jpg'
          WHEN COALESCE(a.storage_key, a.public_url, '') ~* '\.webp(\?|$)' THEN '.webp'
          ELSE '.png'
        END)
  FROM card_images ci
  JOIN cards c ON c.id = ci.card_id
  WHERE a.card_image_id = ci.id
    AND a.role = 'scan_source';

  ----------------------------------------------------------------------------
  -- don_cards: path layout is unchanged, only the host moves to cdn.poneglyph.one
  ----------------------------------------------------------------------------

  UPDATE don_cards
  SET image_url = regexp_replace(image_url, '^https?://[^/]+/', cdn || '/')
  WHERE image_url IS NOT NULL
    AND image_url LIKE '%amazonaws.com%';
END $$;
