/**
 * TypeScript types mirroring the Postgres schema.
 * These are the row shapes returned by queries.
 */

export interface Product {
  id: string;
  language: Language;
  name: string;
  slug: string;
  source: string;
  set_codes: string[] | null;
  product_set_code: string | null;
  tcgplayer_group_id: number | null;
  released_at: string | null;
  created_at: string;
}

export interface Card {
  id: string;
  card_number: string;
  language: string;
  product_id: string | null;
  needs_product_resolution: boolean;
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
  manually_added: boolean;
  created_at: string;
  updated_at: string;
}

export interface CardImage {
  id: string;
  card_id: string;
  product_id: string | null;
  name: string | null;
  variant_index: number;
  image_url: string | null;
  image_thumb_url: string | null;
  scan_url: string | null;
  scan_thumb_s3_key: string | null;
  scan_thumb_url: string | null;
  scan_source_s3_key: string | null;
  scan_source_url: string | null;
  scan_derivative_status: ScanDerivativeStatus;
  scan_derivative_error: string | null;
  scan_derivative_requested_at: string | null;
  scan_derivative_processed_at: string | null;
  crop_focus_x: number | null;
  crop_focus_y: number | null;
  crop_focus_face_count: number | null;
  crop_focus_box_x: number | null;
  crop_focus_box_y: number | null;
  crop_focus_box_width: number | null;
  crop_focus_box_height: number | null;
  crop_focus_status: CropFocusStatus;
  crop_focus_error: string | null;
  crop_focus_attempts: number;
  crop_focus_source_url: string | null;
  crop_focus_source_kind: CropFocusSourceKind | null;
  crop_focus_model: string | null;
  crop_focus_processed_at: string | null;
  source_url: string | null;
  artist: string | null;
  artist_ocr: boolean;
  artist_source: ArtistSource | null;
  artist_ocr_status: ArtistOcrStatus;
  artist_ocr_candidate: string | null;
  artist_ocr_confidence: string | null;
  artist_ocr_attempts: number;
  artist_ocr_last_error: string | null;
  artist_ocr_last_run_at: string | null;
  artist_ocr_source_url: string | null;
  label: CardVariantLabel | null;
  classified: boolean;
  manually_added: boolean;
  created_at: string;
}

export interface CardImageAsset {
  id: string;
  card_image_id: string;
  role: CardImageAssetRole;
  storage_key: string | null;
  public_url: string | null;
  source_url: string | null;
  mime_type: string | null;
  bytes: number | null;
  width: number | null;
  height: number | null;
  derived_from_asset_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface CardSource {
  id: string;
  card_id: string;
  product_id: string;
  created_at: string;
}

export interface CardImageErratum {
  id: string;
  card_image_id: string;
  errata_date: string;
  label: CardVariantLabel | null;
  before_text: string | null;
  after_text: string | null;
  scan_source_s3_key: string | null;
  scan_source_url: string | null;
  scan_url: string | null;
  scan_display_url: string | null;
  scan_thumb_url: string | null;
  scan_derivative_status: ScanDerivativeStatus;
  scan_derivative_error: string | null;
  scan_derivative_requested_at: string | null;
  scan_derivative_processed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface BandaiFaqDocument {
  id: string;
  language: Language;
  source_key: string;
  title: string;
  pdf_url: string;
  updated_on: string;
  created_at: string;
  updated_at: string;
}

export interface BandaiFaqEntry {
  id: string;
  document_id: string;
  ordinal: number;
  card_number: string;
  card_name: string;
  question: string;
  answer: string;
  created_at: string;
  updated_at: string;
}

export interface DonCard {
  id: string;
  product_id: string;
  character: string;
  finish: string;
  image_url: string | null;
  tcgplayer_product_id: number | null;
  tcgplayer_url: string | null;
  tcgplayer_image_url: string | null;
  name: string | null;
  clean_name: string | null;
  source_label: string | null;
  created_at: string;
  updated_at: string;
}

export interface Sleeve {
  id: string;
  language: Language;
  source: SleeveSource;
  source_url: string | null;
  source_product_code: string | null;
  source_design_index: number;
  name: string;
  product_name: string | null;
  release_date: string | null;
  delivery_month: string | null;
  msrp_amount: string | null;
  msrp_currency: string | null;
  contents: string | null;
  image_url: string | null;
  thumbnail_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface SleeveImageAsset {
  id: string;
  sleeve_id: string;
  role: SleeveImageAssetRole;
  source: SleeveImageAssetSource;
  storage_key: string | null;
  public_url: string | null;
  source_url: string | null;
  content_type: string | null;
  width: number | null;
  height: number | null;
  byte_size: string | null;
  created_at: string;
  updated_at: string;
}

export interface DonImageAsset {
  id: string;
  don_card_id: string;
  role: DonImageAssetRole;
  source: DonImageAssetSource;
  storage_key: string | null;
  public_url: string | null;
  source_url: string | null;
  content_type: string | null;
  width: number | null;
  height: number | null;
  byte_size: string | null;
  created_at: string;
  updated_at: string;
}

export interface SleeveScanBatch {
  id: string;
  label: string | null;
  status: CosmeticScanBatchStatus;
  raw_prefix: string;
  total_files: number;
  total_items: number;
  processed_at: string | null;
  last_error: string | null;
  created_at: string;
  updated_at: string;
}

export interface SleeveScanFile {
  id: string;
  batch_id: string;
  file_name: string;
  s3_key: string;
  public_url: string;
  content_type: string | null;
  status: CosmeticScanFileStatus;
  processed_at: string | null;
  error: string | null;
  created_at: string;
  updated_at: string;
}

export interface SleeveScanItem {
  id: string;
  batch_id: string;
  file_id: string;
  ordinal: number;
  status: CosmeticScanItemStatus;
  source_s3_key: string | null;
  source_url: string | null;
  display_s3_key: string | null;
  display_url: string | null;
  thumb_s3_key: string | null;
  thumb_url: string | null;
  linked_sleeve_id: string | null;
  review_notes: string | null;
  error: string | null;
  created_at: string;
  updated_at: string;
}

export interface DonScanBatch {
  id: string;
  label: string | null;
  status: CosmeticScanBatchStatus;
  raw_prefix: string;
  total_files: number;
  total_items: number;
  processed_at: string | null;
  last_error: string | null;
  created_at: string;
  updated_at: string;
}

export interface DonScanFile {
  id: string;
  batch_id: string;
  file_name: string;
  s3_key: string;
  public_url: string;
  content_type: string | null;
  status: CosmeticScanFileStatus;
  processed_at: string | null;
  error: string | null;
  created_at: string;
  updated_at: string;
}

export interface DonScanItem {
  id: string;
  batch_id: string;
  file_id: string;
  ordinal: number;
  status: CosmeticScanItemStatus;
  source_s3_key: string | null;
  source_url: string | null;
  display_s3_key: string | null;
  display_url: string | null;
  thumb_s3_key: string | null;
  thumb_url: string | null;
  linked_don_card_id: string | null;
  review_notes: string | null;
  error: string | null;
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

export interface TcgcsvSyncState {
  source: string;
  upstream_last_updated: string;
  upstream_last_updated_at: string;
  last_successful_sync_at: string;
  created_at: string;
  updated_at: string;
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

export interface ScanIngestBatch {
  id: string;
  language: Language;
  label: CardVariantLabel | null;
  source: string;
  status: ScanIngestBatchStatus;
  raw_prefix: string;
  processed_prefix: string;
  total_files: number;
  total_items: number;
  processed_at: string | null;
  last_error: string | null;
  created_at: string;
  updated_at: string;
}

export interface ScanIngestFile {
  id: string;
  batch_id: string;
  file_name: string;
  s3_key: string;
  public_url: string;
  content_type: string | null;
  status: ScanIngestFileStatus;
  detected_cards: number | null;
  processed_at: string | null;
  error: string | null;
  created_at: string;
  updated_at: string;
}

export interface ScanIngestItem {
  id: string;
  batch_id: string;
  file_id: string;
  ordinal: number;
  status: ScanIngestItemStatus;
  raw_card_number: string | null;
  raw_artist: string | null;
  card_number: string | null;
  artist: string | null;
  artist_present: boolean;
  artist_confidence: string | null;
  card_number_confidence: string | null;
  fuzzy_artist: string | null;
  fuzzy_artist_score: string | null;
  fuzzy_artist_matched: boolean;
  suggested_filename: string | null;
  filename_slug: string | null;
  duplicate_index: number;
  processed_s3_key: string | null;
  processed_url: string | null;
  artist_crop_s3_key: string | null;
  artist_crop_url: string | null;
  footer_crop_s3_key: string | null;
  footer_crop_url: string | null;
  linked_card_id: string | null;
  linked_card_image_id: string | null;
  linked_card_errata_id: string | null;
  review_notes: string | null;
  error: string | null;
  created_at: string;
  updated_at: string;
}

export type AuthCosmeticSlot = "playmat" | "don_sleeve" | "deck_sleeve";
export type AuthAvatarImageSource = "render" | "scan";
export type AuthProfileTitleUnlockMode =
  | "no_requirement"
  | "manual"
  | "automatic";
export type AuthUserStatOperation = "increment" | "set" | "max";
export type AuthProfileTitleRequirementOperator = "gte";
export type DeckCollectionKind = "deck" | "list";

export interface AuthUser {
  id: string;
  username: string;
  display_name: string;
  email: string | null;
  email_verified_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface AuthUserProfile {
  user_id: string;
  avatar_card_image_id: string | null;
  avatar_image_source: AuthAvatarImageSource | null;
  avatar_crop_x: string | null;
  avatar_crop_y: string | null;
  avatar_crop_size: string | null;
  selected_title_key: string | null;
  created_at: string;
  updated_at: string;
}

export interface AuthProfileTitle {
  key: string;
  label: string;
  unlock_mode: AuthProfileTitleUnlockMode;
  style: Record<string, unknown>;
  active: boolean;
  sort_order: number;
  series_key: string | null;
  series_item_key: string | null;
  series_item_label: string | null;
  tier_key: string | null;
  created_at: string;
  updated_at: string;
}

export interface AuthProfileTitleSeries {
  key: string;
  label: string;
  description: string | null;
  active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface AuthUserTitleUnlock {
  id: string;
  user_id: string;
  title_key: string;
  granted_by_admin_email: string;
  granted_at: string;
  revoked_at: string | null;
  note: string | null;
  created_at: string;
  updated_at: string;
}

export interface AuthUserStat {
  user_id: string;
  stat_key: string;
  value: string;
  updated_at: string;
}

export interface AuthUserStatEvent {
  id: string;
  source_type: string;
  source_id: string;
  user_id: string;
  stat_key: string;
  operation: AuthUserStatOperation;
  value: string;
  created_at: string;
}

export interface AuthUserStatDailyActivity {
  user_id: string;
  play_date: string;
  first_source_type: string;
  first_source_id: string;
  created_at: string;
}

export interface AuthProfileTitleRequirement {
  id: string;
  title_key: string;
  stat_key: string;
  operator: AuthProfileTitleRequirementOperator;
  threshold: string;
  created_at: string;
  updated_at: string;
}

export interface AuthPasswordCredential {
  id: string;
  user_id: string;
  password_hash: string;
  password_algorithm: string;
  password_params: Record<string, unknown>;
  created_at: string;
  updated_at: string;
  last_used_at: string | null;
}

export interface AuthSession {
  id: string;
  user_id: string;
  token_hash: string;
  token_hash_algorithm: string;
  created_at: string;
  last_used_at: string | null;
  expires_at: string;
  revoked_at: string | null;
  created_ip: string | null;
  created_user_agent: string | null;
}

export interface SavedDeckFolder {
  id: string;
  user_id: string;
  name: string;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface SavedDeck {
  id: string;
  user_id: string;
  name: string;
  deck_hash: string | null;
  deck: Record<string, unknown> | null;
  folder_id: string | null;
  kind: DeckCollectionKind;
  leader_card_number: string | null;
  leader_variant_index: number | null;
  leader_copy_count: number;
  preview_card_number: string | null;
  preview_variant_index: number | null;
  max_copies_of_single_card: number;
  main_count: number;
  favorite: boolean;
  don_deck_id: string | null;
  playmat_cosmetic_id: string | null;
  playmat_cosmetic_slot: "playmat";
  don_sleeve_cosmetic_id: string | null;
  don_sleeve_cosmetic_slot: "don_sleeve";
  deck_sleeve_cosmetic_id: string | null;
  deck_sleeve_cosmetic_slot: "deck_sleeve";
  created_at: string;
  updated_at: string;
}

export interface SavedDonDeck {
  id: string;
  user_id: string;
  name: string;
  payload: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface Cosmetic {
  id: string;
  slot: AuthCosmeticSlot;
  key: string;
  name: string;
  description: string | null;
  asset: Record<string, unknown>;
  is_default: boolean;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface UserCosmeticEntitlement {
  id: string;
  user_id: string;
  cosmetic_id: string;
  source: string | null;
  granted_at: string;
  revoked_at: string | null;
}

export interface SimHandoffToken {
  id: string;
  user_id: string;
  session_id: string;
  loadout_id: string;
  lobby_id: string | null;
  seat_id: string | null;
  token_id: string;
  issued_at: string;
  expires_at: string;
  revoked_at: string | null;
}

export type SimMatchStatus =
  | "active"
  | "completed"
  | "draw"
  | "abandoned"
  | "errored"
  | "no_contest";

export type SimGameType = "ranked" | "unranked" | "custom" | "dev";

export type SimMatchPlayerResult =
  | "win"
  | "loss"
  | "draw"
  | "no_contest"
  | "abandoned"
  | "errored";

export type SimReplayRngAlgorithm = "pcg32" | "xoshiro256ss" | "test-fixed";

export type SimRollbackMode = "mutual" | "judge" | "auto";

export type SimRollbackClass =
  | "safe"
  | "hidden-info-exposed"
  | "judge-only"
  | "not-rollbackable";

export interface SimMatch {
  id: string;
  status: SimMatchStatus;
  game_type: SimGameType;
  format_id: string;
  ladder_id: string | null;
  lobby_id: string | null;
  queue_id: string | null;
  creation_source: Record<string, unknown>;
  spectator_policy: Record<string, unknown>;
  disconnect_policy: Record<string, unknown>;
  rollback_policy: Record<string, unknown>;
  runtime_versions: Record<string, unknown>;
  card_manifest_hash: string;
  card_manifest_snapshot: Record<string, unknown>;
  first_player_seat_id: string | null;
  first_player_chooser_seat_id: string | null;
  winner_user_id: string | null;
  winner_seat_id: string | null;
  result_reason: string | null;
  win_type: string | null;
  started_at: string;
  ended_at: string | null;
  turn_count: number | null;
  action_count: number;
  final_state_hash: string | null;
  final_state_seq: number | null;
  error_payload: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
}

export interface SimMatchPlayer {
  id: string;
  match_id: string;
  seat_id: string;
  user_id: string | null;
  saved_deck_id: string | null;
  handoff_token_id: string | null;
  display_name: string | null;
  leader_card_number: string;
  leader_variant_index: number | null;
  deck_hash: string | null;
  deck_snapshot: Record<string, unknown>;
  resolved_loadout_snapshot: Record<string, unknown>;
  cosmetic_snapshot: Record<string, unknown>;
  starting_deck_order_hash: string | null;
  result: SimMatchPlayerResult | null;
  result_reason: string | null;
  went_first: boolean | null;
  chose_first: boolean | null;
  is_winner: boolean;
  final_life_count: number | null;
  created_at: string;
}

export interface SimMatchReplay {
  id: string;
  match_id: string;
  replay_format_version: string;
  engine_version: string;
  rules_version: string;
  card_data_version: string;
  effect_definitions_version: string;
  custom_handler_version: string;
  banlist_version: string;
  protocol_version: string;
  rng_algorithm: SimReplayRngAlgorithm;
  rng_seed_commitment: string | null;
  rng_seed_revealed: string | null;
  manifest_hash: string;
  manifest_snapshot: Record<string, unknown>;
  initial_state_hash: string;
  final_state_hash: string | null;
  initial_snapshot: Record<string, unknown> | null;
  initial_deck_orders: Record<string, unknown> | null;
  deterministic_entries: unknown[];
  audit_entries: unknown[];
  checkpoints: unknown[];
  final_state: Record<string, unknown> | null;
  compressed: boolean;
  artifact_storage: string | null;
  artifact_key: string | null;
  artifact_sha256: string | null;
  artifact_size_bytes: string | null;
  created_at: string;
}

export interface SimMatchRollback {
  id: string;
  match_id: string;
  mode: SimRollbackMode;
  rollback_class: SimRollbackClass;
  from_state_seq: number;
  to_state_seq: number;
  requested_by_user_id: string | null;
  approved_by_user_ids: unknown[];
  admin_user_id: string | null;
  reason: string;
  created_at: string;
}

/** Supported languages */
export type Language = "en" | "ja" | "fr" | "zh";

/** Card types in OPTCG */
export type CardType = "Leader" | "Character" | "Event" | "Stage";

/** Rarity codes */
export type Rarity = "C" | "UC" | "R" | "SR" | "SEC" | "L" | "P" | "SP" | "TR";

/** Color values */
export type Color = "Red" | "Green" | "Blue" | "Purple" | "Black" | "Yellow";

/** Attribute values */
export type Attribute = "Strike" | "Slash" | "Special" | "Wisdom" | "Ranged";

/** DON!! card finish types */
export type DonFinish = "Normal" | "Foil" | "Gold";

/** Sleeve catalog source */
export type SleeveSource = "bandai" | "manual";

/** Sleeve image asset roles */
export type SleeveImageAssetRole =
  | "official_source"
  | "official_display"
  | "official_thumb"
  | "scan_source"
  | "scan_display"
  | "scan_thumb";

/** Sleeve image asset source */
export type SleeveImageAssetSource = "bandai" | "admin_upload";

/** DON!! image asset roles */
export type DonImageAssetRole =
  | "tcgplayer_source"
  | "tcgplayer_display"
  | "tcgplayer_thumb"
  | "scan_source"
  | "scan_display"
  | "scan_thumb";

/** DON!! image asset source */
export type DonImageAssetSource = "tcgplayer" | "admin_upload";

/** Shared scan workflow state for cosmetic ingest tables */
export type CosmeticScanBatchStatus =
  | "uploaded"
  | "processing"
  | "processed"
  | "needs_review"
  | "failed"
  | "linked";

export type CosmeticScanFileStatus =
  | "uploaded"
  | "processing"
  | "processed"
  | "failed";

export type CosmeticScanItemStatus =
  | "pending_review"
  | "linked"
  | "failed";

/** TCGPlayer product types */
export type ProductType = "card" | "sealed" | "don";

/** Source of the canonical variant artist value */
export type ArtistSource = "manual" | "scrape" | "ocr";

/** OCR workflow state for a card image variant */
export type ArtistOcrStatus =
  | "pending"
  | "processing"
  | "succeeded"
  | "failed"
  | "needs_review"
  | "skipped";

export type ScanDerivativeStatus =
  | "pending"
  | "processing"
  | "succeeded"
  | "failed";

export type CropFocusStatus =
  | "pending"
  | "processing"
  | "succeeded"
  | "failed";

export type CropFocusSourceKind =
  | "scan_display"
  | "scan"
  | "scan_source"
  | "sample";

export type ScanIngestBatchStatus =
  | "uploaded"
  | "processing"
  | "processed"
  | "needs_review"
  | "failed"
  | "linked";

export type ScanIngestFileStatus =
  | "uploaded"
  | "processing"
  | "processed"
  | "failed";

export type ScanIngestItemStatus =
  | "pending_review"
  | "ready_to_link"
  | "linked"
  | "failed";

export type CardImageAssetRole =
  | "image_url"
  | "image_thumb"
  | "scan_source"
  | "scan_url"
  | "scan_thumb"
  | "scan_display";

/** Canonical card image variant labels */
export const CARD_VARIANT_LABELS = [
  "Standard",
  "Alternate Art",
  "Manga Art",
  "Red Manga Art",
  "SP",
  "Gold SP",
  "Silver SP",
  "TR",
  "Jolly Roger Foil",
  "Textured Foil",
  "Full Art",
  "Dash Pack",
  "Promo",
  "Reprint",
  "Winner",
  "Offline Participant",
  "Offline Finalist",
  "Offline Champion",
  "Online Participant",
  "Online Finalist",
  "Online Champion",
  "Judge",
  "God Pack",
  "Release Event",
  "Other",
] as const;

export type CardVariantLabel = (typeof CARD_VARIANT_LABELS)[number];

/** Label mapping from TCGPlayer suffix to card_images label */
export const TCGPLAYER_LABEL_MAP: Record<string, CardVariantLabel> = {
  "": "Standard",
  "(Alternate Art)": "Alternate Art",
  "(SP)": "SP",
  "(SP) (Gold)": "Gold SP",
  "(SP) (Silver)": "Silver SP",
  "(SP) (Wanted Poster)": "SP",
  "(Wanted Poster)": "SP",
  "(Manga)": "Manga Art",
  "(Parallel) (Manga)": "Manga Art",
  "(Alternate Art) (Manga)": "Manga Art",
  "(Parallel) (Manga) (Alternate Art)": "Manga Art",
  "(Gold)": "Other",
  "(Dash Pack)": "Dash Pack",
  "(Box Topper)": "Other",
  "(Full Art)": "Full Art",
  "(Promo)": "Promo",
  "(Promo Reprint)": "Reprint",
  "(Reprint)": "Reprint",
  "(Parallel)": "Alternate Art",
  "(Super Alternate Art)": "Alternate Art",
  "(Red Super Alternate Art)": "Red Manga Art",
  "(Textured Foil)": "Textured Foil",
  "(Pirate Foil)": "Jolly Roger Foil",
  "(Jolly Roger Foil)": "Jolly Roger Foil",
  "(TR)": "TR",
};

/** Suffixes that indicate the gold variant of an SP label */
export const TCGPLAYER_GOLD_SP_SUFFIXES = new Set(["(SP) (Gold)"]);

/** Allowed asset roles for card_image_assets */
export const CARD_IMAGE_ASSET_ROLES = [
  "image_url",
  "image_thumb",
  "scan_source",
  "scan_url",
  "scan_thumb",
  "scan_display",
] as const satisfies readonly CardImageAssetRole[];

/** Allowed asset roles for sleeve_image_assets */
export const SLEEVE_IMAGE_ASSET_ROLES = [
  "official_source",
  "official_display",
  "official_thumb",
  "scan_source",
  "scan_display",
  "scan_thumb",
] as const satisfies readonly SleeveImageAssetRole[];

/** Allowed asset roles for don_image_assets */
export const DON_IMAGE_ASSET_ROLES = [
  "tcgplayer_source",
  "tcgplayer_display",
  "tcgplayer_thumb",
  "scan_source",
  "scan_display",
  "scan_thumb",
] as const satisfies readonly DonImageAssetRole[];
