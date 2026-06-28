# Color Mastery Title Catalog Design

## Summary

Add a code-owned title catalog with an idempotent sync command. The first catalog family is Color Mastery: 105 automatic unlockable titles generated from leader color match volume.

This pass does not add a locked-title viewer, does not emit unlock notifications, and does not change the current unlocked-title selector behavior.

## Goals

- Support a large number of stable, code-owned profile titles without hand-writing every title row in SQL migrations.
- Add first-class metadata for organizing titles into catalog families and per-series items.
- Generate Color Mastery titles for all 21 leader color buckets.
- Keep title rendering driven by the existing title `label` and `style` fields.
- Keep locked titles hidden from the current profile selector until a separate unlock viewer is designed.

## Non-Goals

- No public locked-title/progress viewer in this pass.
- No Discord, webhook, or public notification when a title unlocks.
- No historical backfill. There are no existing users that need it now.
- No runtime enforcement of title style tiers.
- No locked-title/progress API in this pass.
- No per-card, win-based, streak-based, or general stat title catalogs in this first pass.

## Existing Behavior To Preserve

- `/me` returns the selected profile title and unlocked profile titles.
- Web account/profile title selection only shows no-requirement and unlocked titles.
- Sim displays the title returned by auth.
- Clients render titles from the title `label` and `style`.
- Automatic unlocks are evaluated after stat updates through the existing auth stat pipeline.

## Data Model

Add a new table:

- `auth.profile_title_series`
  - `key TEXT PRIMARY KEY`
  - `label TEXT NOT NULL`
  - `description TEXT`
  - `active BOOLEAN NOT NULL DEFAULT true`
  - `sort_order INTEGER NOT NULL DEFAULT 0`
  - timestamps

Add catalog metadata to `auth.profile_titles`:

- `series_key TEXT REFERENCES auth.profile_title_series(key)`
- `series_item_key TEXT`
- `series_item_label TEXT`
- `tier_key TEXT`

Keep existing title identity and rendering fields:

- `key`
- `label`
- `unlock_mode`
- `style`
- `active`
- `sort_order`

Do not add `style_tier`. Title tier is a catalog convention used while generating content, not a database or runtime enforcement rule.

Keep `auth.profile_title_requirements` as-is for this pass. Color Mastery only needs one `gte` stat requirement per title.

## Stable Keys

Title keys must be semantic and stable. They should not depend on display order or integer ids.

Color Mastery title keys use this shape:

```text
color_mastery_<color_bucket>_<tier_key>
```

Examples:

```text
color_mastery_mono_red_novice
color_mastery_mono_red_master
color_mastery_red_blue_adept
color_mastery_purple_black_enjoyer
```

Series metadata:

- `series_key`: `color_mastery`
- `series_item_key`: color bucket, such as `mono_red` or `red_blue`
- `series_item_label`: display color bucket, such as `Red` or `Red-Blue`
- `tier_key`: one of `novice`, `adept`, `enjoyer`, `expert`, `master`

## Color Mastery Catalog

Generate 105 titles:

- 21 leader color buckets
- 5 titles per bucket

Requirement stat:

```text
leader_color_matches_completed:<color_bucket>
```

Counting rules:

- Any completed match that emits stats counts.
- PvP counts.
- Active bot games count.
- Passive bot does not count because it does not emit stats.

Unlock behavior:

- Unlocks are cumulative.
- If a player crosses multiple thresholds, every reached title unlocks.
- Unlocks are silent.
- No backfill is run when the catalog is first synced.

## Thresholds And Labels

Each color bucket has the same five-tier ladder:

| Tier Key | Threshold | Rank Label |
| --- | ---: | --- |
| `novice` | 10 | Novice |
| `adept` | 25 | Adept |
| `enjoyer` | 100 | Enjoyer |
| `expert` | 500 | Expert |
| `master` | 1000 | Master |

Mono color labels omit "Mono":

- `Red Novice`
- `Blue Master`

Dual color labels use hyphenated color names:

- `Red-Blue Novice`
- `Purple-Black Master`

## Style Convention

The catalog generator follows a five-tier style convention. This is not enforced by the database.

- Tier 1: default/plain white style, matching the current default title treatment.
- Tier 2: custom text color or text gradient.
- Tier 3: glow/highlight allowed.
- Tier 4: more distinctive typography allowed.
- Tier 5: stored/generated now, using current style capabilities until future higher-tier effects exist.

Color Mastery styles should be generated from the color bucket:

- Mono color titles use that color.
- Dual color titles use a two-color gradient.
- Higher tiers get more visible treatment according to the convention above.

The implementation should use helper functions such as `colorMasteryStyle(bucket, tier)` rather than hand-authoring 105 style objects.

## Catalog Sync

Add an idempotent sync command that:

1. Generates the Color Mastery catalog.
2. Upserts `profile_title_series`.
3. Upserts `profile_titles`.
4. Replaces or upserts requirements for catalog-owned titles.
5. Marks removed catalog-owned titles inactive instead of deleting them.

For this pass, catalog ownership is scoped by `series_key = 'color_mastery'`. The sync command only rewrites titles and requirements for that series. Manually managed titles such as `founder_gold` have no `series_key` and must not be touched.

No retroactive user unlock backfill runs in this pass.

## API And UI

The current title APIs remain unlocked-only, but unlocked title objects should include optional catalog metadata so clients can build grouped selectors without a locked-title viewer.

Selected and unlocked title objects keep the existing fields:

- `key`
- `label`
- `style`

Add optional metadata fields:

- `series_key`
- `series_label`
- `series_item_key`
- `series_item_label`
- `tier_key`

For Color Mastery:

- `series_key`: `color_mastery`
- `series_label`: `Color Mastery`
- `series_item_key`: color bucket, such as `mono_red` or `red_blue`
- `series_item_label`: display color bucket, such as `Red` or `Red-Blue`
- `tier_key`: `novice`, `adept`, `enjoyer`, `expert`, or `master`

The metadata fields must be optional or nullable so existing titles such as `pirate_rookie` and `founder_gold` remain valid without catalog membership.

Locked title catalog data and progress are not exposed yet.

The web account page continues to show only unlocked/no-requirement titles. The future unlock viewer will be designed separately.

## Testing

Add tests for:

- Catalog generation produces exactly 105 Color Mastery titles.
- All generated title keys are stable and match the allowed key format.
- All 21 color buckets are represented.
- Each bucket has exactly `novice`, `adept`, `enjoyer`, `expert`, and `master`.
- Generated labels follow mono and dual formatting rules.
- Requirements use `leader_color_matches_completed:<bucket>` with thresholds `10`, `25`, `100`, `500`, and `1000`.
- The sync command only manages catalog-owned titles.
- Existing unlocked-title selector behavior remains unchanged.
- Unlocked title payloads include catalog metadata for Color Mastery titles and preserve existing fields.
- Manual/no-requirement titles without catalog membership serialize with absent or null metadata fields.
