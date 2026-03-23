-- Initial schema for OPTCG Scryfall database.
-- See optcg-scryfall-spec.md for full documentation.

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- Tables
-- ============================================================

CREATE TABLE products (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  language    TEXT NOT NULL,                 -- scraped product language
  name        TEXT NOT NULL,                 -- product title from "Card Set(s)" field
  tcgplayer_group_id INT,                    -- TCGPlayer's groupId for this product
  source      TEXT NOT NULL DEFAULT 'bandai',  -- 'bandai' or 'tcgplayer'
  released_at DATE,                          -- official release date if known
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (name, language)
);

CREATE TABLE cards (
  -- Identity
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_number   TEXT NOT NULL,               -- e.g. "OP01-001", "ST01-012"
  language      TEXT NOT NULL DEFAULT 'en',  -- "en", "ja", "fr", "zh"
  product_id    UUID REFERENCES products(id) NOT NULL, -- product the card was first seen in
  true_set_code TEXT NOT NULL,               -- canonical set code derived from card_number prefix
  name          TEXT NOT NULL,
  -- Classification
  card_type     TEXT NOT NULL,               -- Leader, Character, Event, Stage
  rarity        TEXT,                        -- C, UC, R, SR, SEC, L, P, SP
  color         TEXT[] NOT NULL,             -- e.g. ['Red'], ['Red','Green'] for multicolor
  -- Stats
  cost          INT,                         -- NULL for Leaders
  power         INT,                         -- NULL for Events/Stages
  counter       INT,                         -- NULL if no counter value
  life          INT,                         -- Leaders only, NULL otherwise
  attribute     TEXT[],                      -- e.g. ['Strike'], ['Strike','Slash'] for multi-attribute
  -- Traits & text
  types         TEXT[] NOT NULL,             -- e.g. ['Straw Hat Crew', 'Supernovas']
  effect        TEXT,                        -- NULL if vanilla (no effect text)
  trigger       TEXT,                        -- trigger effect text, NULL if none
  -- Metadata
  block         TEXT,                        -- card-level block number scraped from Bandai
  artist        TEXT,                        -- card artist, NULL if uncredited
  artist_ocr    BOOLEAN NOT NULL DEFAULT false, -- true once OCR has been attempted
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (card_number, language)
);

CREATE TABLE card_images (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id       UUID REFERENCES cards(id) NOT NULL,
  product_id    UUID REFERENCES products(id), -- which product this image was scraped from
  variant_index INT NOT NULL DEFAULT 0,      -- 0 = standard, 1+ = alt arts
  image_url     TEXT,                        -- S3/CloudFront URL, NULL for placeholder entries
  source_url    TEXT,                        -- original Bandai URL, used for deduplication
  is_default    BOOLEAN NOT NULL DEFAULT false,
  label         TEXT,                        -- e.g. "Alternate Art", "Manga Art" — NULL until classified
  classified    BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (card_id, variant_index)
);

CREATE TABLE card_sources (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id    UUID REFERENCES cards(id) NOT NULL,
  product_id UUID REFERENCES products(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (card_id, product_id)
);

CREATE TABLE don_cards (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID REFERENCES products(id) NOT NULL,
  character     TEXT NOT NULL,               -- e.g. "Nami", "Uta"
  finish        TEXT NOT NULL,               -- "Normal", "Foil", "Gold"
  image_url     TEXT,                        -- S3/CloudFront URL
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (product_id, character, finish)
);

CREATE TABLE formats (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,          -- e.g. "Standard", "Extra Regulation"
  description TEXT,
  has_rotation BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE format_legal_blocks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  format_id   UUID REFERENCES formats(id) NOT NULL,
  block       TEXT NOT NULL,                 -- e.g. "1" — matches cards.block
  legal       BOOLEAN NOT NULL DEFAULT true,
  rotated_at  DATE,                          -- date the block rotated out
  UNIQUE (format_id, block)
);

CREATE TABLE format_bans (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  format_id   UUID REFERENCES formats(id) NOT NULL,
  card_number TEXT NOT NULL,
  banned_at   DATE NOT NULL,
  reason      TEXT,
  unbanned_at DATE,                          -- NULL if still banned
  UNIQUE (format_id, card_number)
);

CREATE TABLE tcgplayer_products (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tcgplayer_product_id  INT NOT NULL,
  name                  TEXT NOT NULL,
  clean_name            TEXT,
  sub_type              TEXT,                -- "Normal" or "Foil"
  ext_number            TEXT,                -- maps to our card_number
  ext_rarity            TEXT,
  group_id              INT,                 -- TCGPlayer set groupId
  tcgplayer_url         TEXT,
  image_url             TEXT,
  card_image_id         UUID REFERENCES card_images(id),
  don_card_id           UUID REFERENCES don_cards(id),
  product_type          TEXT NOT NULL DEFAULT 'card',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE (tcgplayer_product_id, sub_type)
);

CREATE TABLE tcgplayer_prices (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tcgplayer_product_id  INT NOT NULL,        -- denormalized for fast queries
  sub_type              TEXT,
  low_price             NUMERIC(10,2),
  mid_price             NUMERIC(10,2),
  high_price            NUMERIC(10,2),
  market_price          NUMERIC(10,2),
  direct_low_price      NUMERIC(10,2),
  fetched_at            TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE scrape_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ran_at        TIMESTAMPTZ DEFAULT now(),
  source        TEXT,                        -- "en", "ja", "fr", "zh", "tcgplayer"
  cards_added   INT DEFAULT 0,
  cards_updated INT DEFAULT 0,
  errors        TEXT,
  duration_ms   INT
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_cards_product_id ON cards(product_id);
CREATE INDEX idx_cards_true_set_code ON cards(true_set_code);
CREATE INDEX idx_cards_card_type ON cards(card_type);
CREATE INDEX idx_cards_rarity ON cards(rarity);
CREATE INDEX idx_cards_cost ON cards(cost);
CREATE INDEX idx_cards_power ON cards(power);
CREATE INDEX idx_cards_language ON cards(language);
CREATE INDEX idx_cards_color ON cards USING GIN(color);
CREATE INDEX idx_cards_types ON cards USING GIN(types);
CREATE INDEX idx_card_images_card_id ON card_images(card_id);
CREATE INDEX idx_card_sources_card_id ON card_sources(card_id);
CREATE INDEX idx_card_sources_product_id ON card_sources(product_id);
CREATE INDEX idx_don_cards_product_id ON don_cards(product_id);
CREATE INDEX idx_don_cards_character ON don_cards(character);
CREATE INDEX idx_format_legal_blocks_format_id ON format_legal_blocks(format_id);
CREATE INDEX idx_format_bans_format_id ON format_bans(format_id);
CREATE INDEX idx_format_bans_card_number ON format_bans(card_number);
CREATE INDEX idx_tcgplayer_products_ext_number ON tcgplayer_products(ext_number);
CREATE INDEX idx_tcgplayer_products_card_image_id ON tcgplayer_products(card_image_id);
CREATE INDEX idx_tcgplayer_products_don_card_id ON tcgplayer_products(don_card_id);
CREATE INDEX idx_tcgplayer_products_product_id ON tcgplayer_products(tcgplayer_product_id);
CREATE INDEX idx_tcgplayer_prices_product_id ON tcgplayer_prices(tcgplayer_product_id);
CREATE INDEX idx_tcgplayer_prices_fetched_at ON tcgplayer_prices(fetched_at);

-- ============================================================
-- Seed data: formats
-- ============================================================

INSERT INTO formats (name, description, has_rotation) VALUES
  ('Standard', 'The primary competitive format with block rotation.', true),
  ('Extra Regulation', 'All blocks legal, separate banlist.', false);
