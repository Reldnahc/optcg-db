ALTER TABLE card_images
  ADD COLUMN IF NOT EXISTS scan_derivative_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (scan_derivative_status IN ('pending', 'processing', 'succeeded', 'failed')),
  ADD COLUMN IF NOT EXISTS scan_derivative_error TEXT,
  ADD COLUMN IF NOT EXISTS scan_derivative_requested_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS scan_derivative_processed_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_card_images_scan_derivative_status
  ON card_images(scan_derivative_status);
