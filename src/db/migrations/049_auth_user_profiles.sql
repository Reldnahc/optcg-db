CREATE TABLE IF NOT EXISTS auth.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  avatar_card_image_id UUID REFERENCES card_images(id) ON DELETE RESTRICT,
  avatar_image_source TEXT,
  avatar_crop_x NUMERIC(7,6),
  avatar_crop_y NUMERIC(7,6),
  avatar_crop_size NUMERIC(7,6),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT user_profiles_avatar_source_check
    CHECK (avatar_image_source IS NULL OR avatar_image_source IN ('render', 'scan')),
  CONSTRAINT user_profiles_avatar_fields_check
    CHECK (
      (
        avatar_card_image_id IS NULL
        AND avatar_image_source IS NULL
        AND avatar_crop_x IS NULL
        AND avatar_crop_y IS NULL
        AND avatar_crop_size IS NULL
      )
      OR
      (
        avatar_card_image_id IS NOT NULL
        AND avatar_image_source IS NOT NULL
        AND avatar_crop_x IS NOT NULL
        AND avatar_crop_y IS NOT NULL
        AND avatar_crop_size IS NOT NULL
        AND avatar_crop_x >= 0
        AND avatar_crop_y >= 0
        AND avatar_crop_size > 0
        AND avatar_crop_size <= 1
        AND avatar_crop_x + avatar_crop_size <= 1
        AND avatar_crop_y + avatar_crop_size <= 1
      )
    )
);

CREATE INDEX IF NOT EXISTS user_profiles_avatar_card_image_idx
  ON auth.user_profiles(avatar_card_image_id)
  WHERE avatar_card_image_id IS NOT NULL;
