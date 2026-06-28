ALTER TABLE cards
  ADD COLUMN IF NOT EXISTS effect_source TEXT NOT NULL DEFAULT 'bandai'
    CHECK (effect_source IN ('bandai', 'manual')),
  ADD COLUMN IF NOT EXISTS trigger_source TEXT NOT NULL DEFAULT 'bandai'
    CHECK (trigger_source IN ('bandai', 'manual'));

UPDATE cards
SET effect_source = 'manual',
    trigger_source = 'manual'
WHERE UPPER(card_number) IN ('P-052', 'OP12-034');
