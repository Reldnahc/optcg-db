UPDATE format_legal_blocks AS flb
SET rotated_at = MAKE_DATE(2025 + flb.block::integer, 4, 1)
FROM formats AS f
WHERE f.id = flb.format_id
  AND COALESCE(f.has_rotation, true) = true
  AND flb.rotated_at IS NULL
  AND flb.block ~ '^[0-9]+$';
