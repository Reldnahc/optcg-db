ALTER TABLE card_images
  ADD COLUMN IF NOT EXISTS crop_focus_x DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS crop_focus_y DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS crop_focus_face_count INT,
  ADD COLUMN IF NOT EXISTS crop_focus_box_x DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS crop_focus_box_y DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS crop_focus_box_width DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS crop_focus_box_height DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS crop_focus_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS crop_focus_error TEXT,
  ADD COLUMN IF NOT EXISTS crop_focus_attempts INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS crop_focus_source_url TEXT,
  ADD COLUMN IF NOT EXISTS crop_focus_source_kind TEXT,
  ADD COLUMN IF NOT EXISTS crop_focus_model TEXT,
  ADD COLUMN IF NOT EXISTS crop_focus_processed_at TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'card_images_crop_focus_status_check'
  ) THEN
    ALTER TABLE card_images
      ADD CONSTRAINT card_images_crop_focus_status_check
      CHECK (crop_focus_status IN ('pending', 'processing', 'succeeded', 'failed'));
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'card_images_crop_focus_source_kind_check'
  ) THEN
    ALTER TABLE card_images
      ADD CONSTRAINT card_images_crop_focus_source_kind_check
      CHECK (
        crop_focus_source_kind IS NULL
        OR crop_focus_source_kind IN ('scan_display', 'scan', 'scan_source', 'sample')
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_card_images_crop_focus_status
  ON card_images(crop_focus_status);
