/**
 * TypeScript types mirroring the Postgres schema.
 * These are the row shapes returned by queries.
 */

export interface Product {
  id: string;
  language: Language;
  name: string;
  source: string;
  set_codes: string[] | null;
  tcgplayer_group_id: number | null;
  released_at: string | null;
  created_at: string;
}

export interface Card {
  id: string;
  card_number: string;
  language: string;
  product_id: string;
  true_set_code: string;
  name: string;
  card_type: string;
  rarity: string | null;
  color: string[];
  cost: number | null;
  power: number | null;
  counter: number | null;
  life: number | null;
  attribute: string[] | null;
  types: string[];
  effect: string | null;
  trigger: string | null;
  block: string | null;
  artist: string | null;
  artist_ocr: boolean;
  created_at: string;
  updated_at: string;
}

export interface CardImage {
  id: string;
  card_id: string;
  product_id: string | null;
  variant_index: number;
  image_url: string;
  source_url: string | null;
  is_default: boolean;
  label: string | null;
  classified: boolean;
  created_at: string;
}

export interface CardSource {
  id: string;
  card_id: string;
  product_id: string;
  created_at: string;
}

export interface DonCard {
  id: string;
  product_id: string;
  character: string;
  finish: string;
  image_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface Format {
  id: string;
  name: string;
  description: string | null;
  has_rotation: boolean;
  created_at: string;
}

export interface FormatLegalBlock {
  id: string;
  format_id: string;
  block: string;
  legal: boolean;
  rotated_at: string | null;
}

export interface FormatBan {
  id: string;
  format_id: string;
  card_number: string;
  banned_at: string;
  reason: string | null;
  unbanned_at: string | null;
}

export interface TcgplayerProduct {
  id: string;
  tcgplayer_product_id: number;
  name: string;
  clean_name: string | null;
  sub_type: string | null;
  ext_number: string | null;
  ext_rarity: string | null;
  group_id: number | null;
  tcgplayer_url: string | null;
  image_url: string | null;
  card_image_id: string | null;
  don_card_id: string | null;
  product_type: string;
  created_at: string;
  updated_at: string;
}

export interface TcgplayerPrice {
  id: string;
  tcgplayer_product_id: number;
  sub_type: string | null;
  low_price: string | null;
  mid_price: string | null;
  high_price: string | null;
  market_price: string | null;
  direct_low_price: string | null;
  fetched_at: string;
}

export interface ScrapeLog {
  id: string;
  ran_at: string;
  source: string | null;
  cards_added: number;
  cards_updated: number;
  errors: string | null;
  duration_ms: number | null;
}

/** Supported languages */
export type Language = "en" | "ja" | "fr" | "zh";

/** Card types in OPTCG */
export type CardType = "Leader" | "Character" | "Event" | "Stage";

/** Rarity codes */
export type Rarity = "C" | "UC" | "R" | "SR" | "SEC" | "L" | "P" | "SP";

/** Color values */
export type Color = "Red" | "Green" | "Blue" | "Purple" | "Black" | "Yellow";

/** Attribute values */
export type Attribute = "Strike" | "Slash" | "Special" | "Wisdom" | "Ranged";

/** DON!! card finish types */
export type DonFinish = "Normal" | "Foil" | "Gold";

/** TCGPlayer product types */
export type ProductType = "card" | "sealed" | "don";

/** Label mapping from TCGPlayer suffix to card_images label */
export const TCGPLAYER_LABEL_MAP: Record<string, string> = {
  "": "Standard",
  "(Alternate Art)": "Alternate Art",
  "(SP)": "SP Card",
  "(SP) (Gold)": "SP Card",
  "(SP) (Silver)": "SP Card",
  "(SP) (Wanted Poster)": "SP Card",
  "(Wanted Poster)": "SP Card",
  "(Manga)": "Manga Art",
  "(Parallel) (Manga)": "Manga Art",
  "(Alternate Art) (Manga)": "Manga Art",
  "(Parallel) (Manga) (Alternate Art)": "Manga Art",
  "(Gold)": "Gold",
  "(Dash Pack)": "Dash Pack",
  "(Box Topper)": "Box Topper",
  "(Full Art)": "Full Art",
  "(Promo)": "Promo",
  "(Promo Reprint)": "Reprint",
  "(Reprint)": "Reprint",
  "(Parallel)": "Alternate Art",
  "(Super Alternate Art)": "Alternate Art",
  "(Red Super Alternate Art)": "Alternate Art",
  "(Textured Foil)": "Alternate Art",
  "(Pirate Foil)": "Alternate Art",
  "(Jolly Roger Foil)": "Alternate Art",
  "(TR)": "Alternate Art",
};

/** Suffixes that indicate the gold variant of an SP Card */
export const TCGPLAYER_GOLD_SP_SUFFIXES = new Set(["(SP) (Gold)"]);
