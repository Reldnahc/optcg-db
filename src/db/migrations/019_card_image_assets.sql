CREATE TABLE card_image_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_image_id UUID NOT NULL REFERENCES card_images(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN (
    'image_url',
    'image_thumb',
    'scan_source',
    'scan_url',
    'scan_thumb',
    'scan_display'
  )),
  storage_key TEXT,
  public_url TEXT,
  source_url TEXT,
  mime_type TEXT,
  bytes INT,
  width INT,
  height INT,
  derived_from_asset_id UUID REFERENCES card_image_assets(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (card_image_id, role)
);

CREATE INDEX idx_card_image_assets_card_image_id
  ON card_image_assets(card_image_id);

CREATE INDEX idx_card_image_assets_role
  ON card_image_assets(role);
