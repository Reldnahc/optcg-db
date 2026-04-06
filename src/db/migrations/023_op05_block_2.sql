UPDATE cards
SET block = '2'
WHERE card_number LIKE 'OP05-%'
  AND block = '1';
