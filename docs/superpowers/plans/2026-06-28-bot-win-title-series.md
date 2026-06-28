# Bot Win Title Series Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move bot-win titles into the generated profile title catalog with five thresholds from 1 to 5000 wins.

**Architecture:** Extend `buildProfileTitleCatalog()` with a second generated series. The existing catalog sync script already handles multiple series, titles, and requirements, so only the catalog generator and catalog test need changes.

**Tech Stack:** TypeScript catalog generator in `optcg-db`, Node-based catalog test, npm scripts for build/test/typecheck.

---

## File Map

- Modify `optcg-db/src/db/profile-title-catalog.ts`: add `bot_wins` series, five bot-win title definitions, bot-win style function, and include the series/titles/requirements in `buildProfileTitleCatalog()`.
- Modify `optcg-db/test/profile-title-catalog.test.mjs`: assert the new series, title counts, requirements, labels, thresholds, stat key, and first-title plain style.

---

### Task 1: Add Bot Win Generated Titles

**Files:**
- Modify: `optcg-db/src/db/profile-title-catalog.ts`
- Modify: `optcg-db/test/profile-title-catalog.test.mjs`

- [ ] **Step 1: Update catalog test expectations first**

In `optcg-db/test/profile-title-catalog.test.mjs`, replace the current series/count assertions:

```js
assert.equal(catalog.series.length, 1);
assert.deepEqual(catalog.series[0], {
  key: "color_mastery",
  label: "Color Mastery",
  description: "Titles earned by completing games with specific leader color identities.",
  active: true,
  sort_order: 100,
});

assert.equal(titles.length, 105);
assert.equal(requirements.length, 105);
```

with:

```js
assert.equal(catalog.series.length, 2);
assert.deepEqual(catalog.series[0], {
  key: "color_mastery",
  label: "Color Mastery",
  description: "Titles earned by completing games with specific leader color identities.",
  active: true,
  sort_order: 100,
});
assert.deepEqual(catalog.series[1], {
  key: "bot_wins",
  label: "Bot Wins",
  description: "Titles earned by winning games against the bot.",
  active: true,
  sort_order: 200,
});

assert.equal(titles.length, 110);
assert.equal(requirements.length, 110);
```

Replace the loop assertion that every title has `series_key === "color_mastery"`:

```js
assert.equal(title.series_key, "color_mastery");
```

with:

```js
assert.ok(["color_mastery", "bot_wins"].includes(title.series_key));
```

After the existing color mastery assertions, add:

```js
const botTitles = titles.filter((title) => title.series_key === "bot_wins");
assert.deepEqual(
  botTitles.map((title) => [title.key, title.label, title.series_item_key, title.tier_key]),
  [
    ["first_bot_win", "Bot Basher", "bot", "basher"],
    ["bot_wins_breaker", "Bot Breaker", "bot", "breaker"],
    ["bot_wins_hunter", "Bot Hunter", "bot", "hunter"],
    ["bot_wins_slayer", "Bot Slayer", "bot", "slayer"],
    ["bot_wins_machine_reaper", "Machine Reaper", "bot", "machine_reaper"],
  ],
);
assert.deepEqual(
  botTitles.map((title) => title.style),
  [
    {
      text_color: "#e8e9ed",
      font_family: "display",
      font_weight: 700,
      animation: "none",
    },
    {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 750,
      animation: "none",
    },
    {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 800,
      glow_color: "#93c5fd",
      animation: "none",
    },
    {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 900,
      gradient: { from: "#60a5fa", to: "#c084fc", angle: 90 },
      glow_color: "#93c5fd",
      animation: "shine",
    },
    {
      text_color: "#f8fafc",
      font_family: "display",
      font_weight: 900,
      gradient: { from: "#f8fafc", via: "#60a5fa", to: "#c084fc", angle: 90 },
      glow_color: "#c084fc",
      animation: "shine",
    },
  ],
);
assert.deepEqual(
  requirements
    .filter((requirement) => requirement.title_key === "first_bot_win" || requirement.title_key.startsWith("bot_wins_"))
    .map((requirement) => [requirement.title_key, requirement.stat_key, requirement.threshold.toString()]),
  [
    ["first_bot_win", "bot_matches_won", "1"],
    ["bot_wins_breaker", "bot_matches_won", "100"],
    ["bot_wins_hunter", "bot_matches_won", "500"],
    ["bot_wins_slayer", "bot_matches_won", "1000"],
    ["bot_wins_machine_reaper", "bot_matches_won", "5000"],
  ],
);
```

- [ ] **Step 2: Run test to verify it fails**

Run in `optcg-db`:

```powershell
npm.cmd run test
```

Expected: test fails because the catalog still has only one series, 105 titles, and 105 requirements.

- [ ] **Step 3: Add bot-win catalog definitions**

In `optcg-db/src/db/profile-title-catalog.ts`, after `colorMasterySeries`, add:

```ts
export const botWinsSeries: ProfileTitleCatalogSeries = {
  key: "bot_wins",
  label: "Bot Wins",
  description: "Titles earned by winning games against the bot.",
  active: true,
  sort_order: 200,
};
```

After `colorMasteryTiers`, add:

```ts
type BotWinTier = {
  key: "basher" | "breaker" | "hunter" | "slayer" | "machine_reaper";
  titleKey: string;
  label: string;
  threshold: bigint;
};

const botWinTiers: readonly BotWinTier[] = [
  { key: "basher", titleKey: "first_bot_win", label: "Bot Basher", threshold: 1n },
  { key: "breaker", titleKey: "bot_wins_breaker", label: "Bot Breaker", threshold: 100n },
  { key: "hunter", titleKey: "bot_wins_hunter", label: "Bot Hunter", threshold: 500n },
  { key: "slayer", titleKey: "bot_wins_slayer", label: "Bot Slayer", threshold: 1000n },
  { key: "machine_reaper", titleKey: "bot_wins_machine_reaper", label: "Machine Reaper", threshold: 5000n },
];
```

After `colorMasteryStyle`, add:

```ts
function botWinStyle(tierIndex: number): Record<string, unknown> {
  if (tierIndex === 0) {
    return {
      text_color: "#e8e9ed",
      font_family: "display",
      font_weight: 700,
      animation: "none",
    };
  }
  if (tierIndex === 1) {
    return {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 750,
      animation: "none",
    };
  }
  if (tierIndex === 2) {
    return {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 800,
      glow_color: "#93c5fd",
      animation: "none",
    };
  }
  if (tierIndex === 3) {
    return {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 900,
      gradient: { from: "#60a5fa", to: "#c084fc", angle: 90 },
      glow_color: "#93c5fd",
      animation: "shine",
    };
  }
  return {
    text_color: "#f8fafc",
    font_family: "display",
    font_weight: 900,
    gradient: { from: "#f8fafc", via: "#60a5fa", to: "#c084fc", angle: 90 },
    glow_color: "#c084fc",
    animation: "shine",
  };
}
```

- [ ] **Step 4: Include bot titles in the catalog build**

In `buildProfileTitleCatalog()`, after the color mastery loop, add:

```ts
for (const [tierIndex, tier] of botWinTiers.entries()) {
  titles.push({
    key: tier.titleKey,
    label: tier.label,
    unlock_mode: "automatic",
    style: botWinStyle(tierIndex),
    active: true,
    sort_order: botWinsSeries.sort_order + tierIndex,
    series_key: botWinsSeries.key,
    series_item_key: "bot",
    series_item_label: "Bot",
    tier_key: tier.key,
  });
  requirements.push({
    title_key: tier.titleKey,
    stat_key: "bot_matches_won",
    operator: "gte",
    threshold: tier.threshold,
  });
}
```

Change the return value:

```ts
return {
  series: [colorMasterySeries],
  titles,
  requirements,
};
```

to:

```ts
return {
  series: [colorMasterySeries, botWinsSeries],
  titles,
  requirements,
};
```

- [ ] **Step 5: Verify DB package**

Run in `optcg-db`:

```powershell
npm.cmd run typecheck
npm.cmd run test
```

Expected: both commands exit `0`.

- [ ] **Step 6: Commit bot-win catalog slice**

Run in `optcg-db`:

```powershell
git add src/db/profile-title-catalog.ts test/profile-title-catalog.test.mjs
git commit -m "Add bot win title series"
```
