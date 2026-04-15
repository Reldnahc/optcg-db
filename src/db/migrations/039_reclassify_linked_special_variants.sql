UPDATE card_images ci
SET label = 'Gold SP'
FROM tcgplayer_products tp
WHERE tp.card_image_id = ci.id
  AND tp.name LIKE '%(SP) (Gold)%'
  AND ci.label = 'SP';

UPDATE card_images ci
SET label = 'Silver SP'
FROM tcgplayer_products tp
WHERE tp.card_image_id = ci.id
  AND tp.name LIKE '%(SP) (Silver)%'
  AND ci.label = 'SP';

UPDATE card_images ci
SET label = 'Red Manga Art'
FROM tcgplayer_products tp
WHERE tp.card_image_id = ci.id
  AND tp.name LIKE '%(Red Super Alternate Art)%'
  AND ci.label = 'Alternate Art';
