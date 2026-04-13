CREATE TABLE card_image_errata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_image_id UUID NOT NULL REFERENCES card_images(id) ON DELETE CASCADE,
  ordinal INT NOT NULL,
  label TEXT,
  notes TEXT,
  scan_source_s3_key TEXT,
  scan_source_url TEXT,
  scan_url TEXT,
  scan_display_url TEXT,
  scan_thumb_url TEXT,
  scan_derivative_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (scan_derivative_status IN ('pending', 'processing', 'succeeded', 'failed')),
  scan_derivative_error TEXT,
  scan_derivative_requested_at TIMESTAMPTZ,
  scan_derivative_processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (card_image_id, ordinal)
);

CREATE INDEX idx_card_image_errata_card_image_id
  ON card_image_errata(card_image_id, ordinal);

CREATE INDEX idx_card_image_errata_scan_derivative_status
  ON card_image_errata(scan_derivative_status);
