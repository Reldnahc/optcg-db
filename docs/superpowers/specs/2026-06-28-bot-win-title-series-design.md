# Bot Win Title Series Design

## Goal

Replace the one-off `first_bot_win` title with a generated bot-win title series owned by the profile title catalog sync.

## Series

Add one new catalog series:

- `key`: `bot_wins`
- `label`: `Bot Wins`
- `description`: `Titles earned by winning games against the bot.`
- `sort_order`: `200`

The existing `first_bot_win` key remains valid for compatibility with any account that already unlocked or selected it.

## Titles

The series has five automatic titles. Every title uses the existing `bot_matches_won` stat key.

| Key | Label | Threshold | Style Tier |
| --- | --- | ---: | --- |
| `first_bot_win` | `Bot Basher` | 1 | Plain/default |
| `bot_wins_breaker` | `Bot Breaker` | 100 | Colored text |
| `bot_wins_hunter` | `Bot Hunter` | 500 | Color plus subtle glow |
| `bot_wins_slayer` | `Bot Slayer` | 1000 | Gradient/glow/shine |
| `bot_wins_machine_reaper` | `Machine Reaper` | 5000 | Loudest currently supported gradient/glow/shine |

`Bot Basher` loses its current green styled treatment and becomes a plain white/default title.

## Requirements

Each title has one requirement:

```text
bot_matches_won >= threshold
```

No new stats are added. Passive bot games already disable stats upstream, so this series only follows the existing `bot_matches_won` stat behavior.

## Implementation Notes

- Add the series and titles to `buildProfileTitleCatalog()`.
- Keep `first_bot_win` as the tier-one generated title key.
- Include the new series in the catalog sync output.
- Update catalog tests to assert two series total, 110 titles total, and 110 requirements total.
- Assert `first_bot_win` is still present, has threshold `1`, belongs to `bot_wins`, and uses the plain/default style.
- Assert the `Machine Reaper` title uses threshold `5000`.

## Out Of Scope

- New stat emitters.
- Backfill.
- Web selector layout changes.
- Deployment or catalog sync in production.
