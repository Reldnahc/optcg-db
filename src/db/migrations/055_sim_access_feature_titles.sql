INSERT INTO auth.profile_title_series (key, label, description, active, sort_order)
VALUES
  ('sim_access', 'Sim Access', 'Titles granted with simulator access permissions.', true, 50)
ON CONFLICT (key)
DO UPDATE SET
  label = EXCLUDED.label,
  description = EXCLUDED.description,
  active = EXCLUDED.active,
  sort_order = EXCLUDED.sort_order;

INSERT INTO auth.profile_titles (
  key,
  label,
  unlock_mode,
  style,
  active,
  sort_order,
  series_key,
  series_item_key,
  series_item_label,
  tier_key
)
VALUES
  (
    'tester',
    'Tester',
    'manual',
    '{"text_color":"#38bdf8","font_family":"display","font_weight":800,"gradient":{"from":"#38bdf8","to":"#a78bfa","angle":90},"glow_color":"#7dd3fc","animation":"none"}'::jsonb,
    true,
    50,
    'sim_access',
    'dev',
    'Dev Sim',
    'access'
  ),
  (
    'developer',
    'Developer',
    'manual',
    '{"text_color":"#34d399","font_family":"display","font_weight":800,"gradient":{"from":"#34d399","to":"#facc15","angle":90},"glow_color":"#86efac","animation":"none"}'::jsonb,
    true,
    51,
    'sim_access',
    'local',
    'Local Sim',
    'access'
  )
ON CONFLICT (key)
DO UPDATE SET
  label = EXCLUDED.label,
  unlock_mode = EXCLUDED.unlock_mode,
  style = EXCLUDED.style,
  active = EXCLUDED.active,
  sort_order = EXCLUDED.sort_order,
  series_key = EXCLUDED.series_key,
  series_item_key = EXCLUDED.series_item_key,
  series_item_label = EXCLUDED.series_item_label,
  tier_key = EXCLUDED.tier_key;

COMMENT ON TABLE auth.user_feature_overrides IS
  'Account-level feature overrides. sim_access_dev and sim_access_local gate simulator environments.';
