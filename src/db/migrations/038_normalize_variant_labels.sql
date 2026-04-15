UPDATE card_images
SET label = 'SP'
WHERE label = 'SP Card';

UPDATE card_images
SET label = 'Other'
WHERE label IN ('Box Topper', 'Gold');

UPDATE card_image_errata
SET label = 'SP'
WHERE label = 'SP Card';

UPDATE card_image_errata
SET label = 'Other'
WHERE label IN ('Box Topper', 'Gold');
