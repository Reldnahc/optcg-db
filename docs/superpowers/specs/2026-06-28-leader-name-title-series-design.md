# Leader Name Title Series Design

## Goal

Add a generated leader-name title series that rewards playing leaders by canonical name, mixing all leader cards with the same normalized name into one progression track.

## Stat Source

Use the existing sim stat keys:

```text
leader_name_matches_completed:<leader-slug>
```

This mirrors Color Mastery, which uses completed matches rather than wins. No new stat emitters are required.

## Leader Discovery

Leader-name titles are dynamic, not hardcoded.

During profile title catalog sync:

1. Query distinct English leader card names from `cards`.
2. Normalize each name with the same slug rules as the sim uses for `leaderNameKey`.
3. Collapse duplicate slugs into one leader item.
4. Generate five titles per leader item.

This lets newly scraped leaders become title-eligible on the next catalog sync after the card data exists.

The generator must remain deterministic: the same database contents produce the same title keys, labels, styles, requirements, and sort order every run.

## Series

Add one new catalog series:

- `key`: `leader_name_mastery`
- `label`: `Leader Name Mastery`
- `description`: `Titles earned by completing games with leaders that share a canonical name.`
- `sort_order`: `300`

## Titles

Each leader receives five automatic titles:

| Tier Key | Label Pattern | Threshold |
| --- | --- | ---: |
| `novice` | `<Leader> Novice` | 10 |
| `adept` | `<Leader> Adept` | 25 |
| `enjoyer` | `<Leader> Enjoyer` | 100 |
| `expert` | `<Leader> Expert` | 500 |
| `master` | `<Leader> Master` | 1000 |

Title keys use:

```text
leader_name_mastery_<leader-slug>_<tier>
```

Requirements use:

```text
leader_name_matches_completed:<leader-slug>
```

## Styling

Do not derive leader-name title styling from card colors. A leader name can span several leader cards and color identities, so card-color styling would imply a false gameplay color identity.

Use deterministic non-semantic styling:

- Tier 1 uses the existing plain/default style.
- Tier 2 and above use a curated palette selected by hashing the leader slug.
- The palette is presentation-only. It does not represent OPTCG leader colors.
- The hash and palette order must be stable so existing title styles do not reshuffle.

Use this fixed palette list, in this order:

| Key | Primary | Secondary | Glow |
| --- | --- | --- | --- |
| `steel_gold` | `#e5e7eb` | `#facc15` | `#fde68a` |
| `cyan_violet` | `#22d3ee` | `#a78bfa` | `#67e8f9` |
| `rose_amber` | `#fb7185` | `#f59e0b` | `#fda4af` |
| `emerald_ice` | `#34d399` | `#bfdbfe` | `#86efac` |
| `white_blue` | `#f8fafc` | `#60a5fa` | `#93c5fd` |
| `crimson_silver` | `#dc2626` | `#d1d5db` | `#fca5a5` |
| `violet_gold` | `#8b5cf6` | `#fbbf24` | `#c4b5fd` |
| `teal_pearl` | `#14b8a6` | `#f8fafc` | `#5eead4` |
| `indigo_mint` | `#6366f1` | `#6ee7b7` | `#a5b4fc` |
| `magenta_cobalt` | `#d946ef` | `#3b82f6` | `#f0abfc` |
| `amber_slate` | `#f59e0b` | `#94a3b8` | `#fcd34d` |
| `lime_azure` | `#a3e635` | `#38bdf8` | `#bef264` |

Style power follows the existing tier convention:

- Novice: plain/default.
- Adept: palette color or gradient.
- Enjoyer: gradient plus subtle glow.
- Expert/Master: heavier gradient/glow/shine, with Master allowed to be the loudest currently supported static style.

## Sync Shape

The current static catalog builder remains usable for static series. Add a DB-backed catalog build path for sync:

- Static catalog: Color Mastery and Bot Wins.
- Dynamic catalog: Leader Name Mastery generated from leader rows.
- Final sync catalog: static plus dynamic.

Tests cover both:

- Static builder remains deterministic without a database.
- Dynamic leader generation collapses multiple leader cards with the same slug.
- Dynamic titles use the expected keys, labels, thresholds, and stat keys.
- Palette selection is stable for representative slugs.

## Out Of Scope

- Exact leader-card specialist titles.
- Win-based leader titles.
- Manual leader title curation.
- Backfill.
- Deployment or production catalog sync.
