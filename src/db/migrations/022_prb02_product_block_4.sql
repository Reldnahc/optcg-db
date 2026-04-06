UPDATE cards AS c
SET block = '4'
WHERE c.block = '1'
  AND EXISTS (
    SELECT 1
    FROM card_sources AS cs
    JOIN products AS p
      ON p.id = cs.product_id
    WHERE cs.card_id = c.id
      AND p.product_set_code = 'PRB02'
  );
