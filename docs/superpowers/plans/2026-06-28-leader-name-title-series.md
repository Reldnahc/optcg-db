# Leader Name Title Series Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate profile titles for every discovered leader name using existing `leader_name_matches_completed:<slug>` stats.

**Architecture:** Keep static title generation deterministic and add a dynamic leader-name generator that accepts leader names from the database. The sync command builds one combined catalog per run, queries English leader names, and syncs/deactivates all managed series from that combined catalog.

**Tech Stack:** TypeScript catalog generator in `optcg-db`, PostgreSQL through `query()`, Node-based catalog tests, npm build/typecheck/test scripts.

---

## File Map

- Modify `optcg-db/src/db/profile-title-catalog.ts`: add leader slug normalization, fixed palettes, leader-name series builder, static/dynamic catalog builders, and combined catalog helpers.
- Modify `optcg-db/src/db/sync-profile-title-catalog.ts`: build the catalog once from DB leader names; sync series/titles/requirements from that catalog; deactivate stale titles for all managed series.
- Modify `optcg-db/test/profile-title-catalog.test.mjs`: keep static catalog assertions and add dynamic leader-name generation tests.

---

### Task 1: Add Dynamic Leader-Name Catalog Generation

**Files:**
- Modify: `optcg-db/src/db/profile-title-catalog.ts`
- Modify: `optcg-db/test/profile-title-catalog.test.mjs`

- [ ] **Step 1: Add failing tests for dynamic leader titles**

In `optcg-db/test/profile-title-catalog.test.mjs`, change the import:

```js
import { buildProfileTitleCatalog } from "../dist/db/profile-title-catalog.js";
```

to:

```js
import {
  buildLeaderNameTitleCatalog,
  buildProfileTitleCatalog,
  leaderNameKey,
} from "../dist/db/profile-title-catalog.js";
```

After the existing bot-title assertions, add:

```js
assert.equal(leaderNameKey("Monkey.D.Luffy"), "monkey-d-luffy");
assert.equal(leaderNameKey("Roronoa Zoro"), "roronoa-zoro");
assert.equal(leaderNameKey("   Trafalgar   Law   "), "trafalgar-law");

const leaderCatalog = buildLeaderNameTitleCatalog([
  "Monkey.D.Luffy",
  "Monkey D Luffy",
  "Roronoa Zoro",
]);
assert.deepEqual(leaderCatalog.series, [
  {
    key: "leader_name_mastery",
    label: "Leader Name Mastery",
    description: "Titles earned by completing games with leaders that share a canonical name.",
    active: true,
    sort_order: 300,
  },
]);
assert.equal(leaderCatalog.titles.length, 10);
assert.equal(leaderCatalog.requirements.length, 10);
assert.deepEqual(
  leaderCatalog.titles
    .filter((title) => title.series_item_key === "monkey-d-luffy")
    .map((title) => [title.key, title.label, title.tier_key]),
  [
    ["leader_name_mastery_monkey-d-luffy_novice", "Monkey.D.Luffy Novice", "novice"],
    ["leader_name_mastery_monkey-d-luffy_adept", "Monkey.D.Luffy Adept", "adept"],
    ["leader_name_mastery_monkey-d-luffy_enjoyer", "Monkey.D.Luffy Enjoyer", "enjoyer"],
    ["leader_name_mastery_monkey-d-luffy_expert", "Monkey.D.Luffy Expert", "expert"],
    ["leader_name_mastery_monkey-d-luffy_master", "Monkey.D.Luffy Master", "master"],
  ],
);
assert.deepEqual(
  leaderCatalog.requirements
    .filter((requirement) => requirement.title_key.startsWith("leader_name_mastery_monkey-d-luffy_"))
    .map((requirement) => [requirement.stat_key, requirement.threshold.toString()]),
  [
    ["leader_name_matches_completed:monkey-d-luffy", "10"],
    ["leader_name_matches_completed:monkey-d-luffy", "25"],
    ["leader_name_matches_completed:monkey-d-luffy", "100"],
    ["leader_name_matches_completed:monkey-d-luffy", "500"],
    ["leader_name_matches_completed:monkey-d-luffy", "1000"],
  ],
);
assert.deepEqual(
  leaderCatalog.titles.find((title) => title.key === "leader_name_mastery_monkey-d-luffy_novice")?.style,
  {
    text_color: "#e8e9ed",
    font_family: "display",
    font_weight: 700,
    animation: "none",
  },
);
assert.deepEqual(
  leaderCatalog.titles.find((title) => title.key === "leader_name_mastery_monkey-d-luffy_master")?.style,
  {
    text_color: "#22d3ee",
    font_family: "display",
    font_weight: 900,
    gradient: { from: "#22d3ee", via: "#a78bfa", to: "#67e8f9", angle: 90 },
    glow_color: "#67e8f9",
    animation: "shine",
  },
);
```

- [ ] **Step 2: Run test to verify it fails**

Run in `optcg-db`:

```powershell
npm.cmd run test
```

Expected: build or test fails because `buildLeaderNameTitleCatalog` and `leaderNameKey` are not exported yet.

- [ ] **Step 3: Add leader-name types, series, tiers, and palettes**

In `optcg-db/src/db/profile-title-catalog.ts`, after `type ColorMasteryTier`, add:

```ts
type LeaderNameTier = {
  key: "novice" | "adept" | "enjoyer" | "expert" | "master";
  label: string;
  threshold: bigint;
};

type LeaderNamePalette = {
  key: string;
  primary: string;
  secondary: string;
  glow: string;
};
```

After `botWinsSeries`, add:

```ts
export const leaderNameMasterySeries: ProfileTitleCatalogSeries = {
  key: "leader_name_mastery",
  label: "Leader Name Mastery",
  description: "Titles earned by completing games with leaders that share a canonical name.",
  active: true,
  sort_order: 300,
};
```

After `botWinTiers`, add:

```ts
const leaderNameTiers: readonly LeaderNameTier[] = [
  { key: "novice", label: "Novice", threshold: 10n },
  { key: "adept", label: "Adept", threshold: 25n },
  { key: "enjoyer", label: "Enjoyer", threshold: 100n },
  { key: "expert", label: "Expert", threshold: 500n },
  { key: "master", label: "Master", threshold: 1000n },
];

const leaderNamePalettes: readonly LeaderNamePalette[] = [
  { key: "steel_gold", primary: "#e5e7eb", secondary: "#facc15", glow: "#fde68a" },
  { key: "cyan_violet", primary: "#22d3ee", secondary: "#a78bfa", glow: "#67e8f9" },
  { key: "rose_amber", primary: "#fb7185", secondary: "#f59e0b", glow: "#fda4af" },
  { key: "emerald_ice", primary: "#34d399", secondary: "#bfdbfe", glow: "#86efac" },
  { key: "white_blue", primary: "#f8fafc", secondary: "#60a5fa", glow: "#93c5fd" },
  { key: "crimson_silver", primary: "#dc2626", secondary: "#d1d5db", glow: "#fca5a5" },
  { key: "violet_gold", primary: "#8b5cf6", secondary: "#fbbf24", glow: "#c4b5fd" },
  { key: "teal_pearl", primary: "#14b8a6", secondary: "#f8fafc", glow: "#5eead4" },
  { key: "indigo_mint", primary: "#6366f1", secondary: "#6ee7b7", glow: "#a5b4fc" },
  { key: "magenta_cobalt", primary: "#d946ef", secondary: "#3b82f6", glow: "#f0abfc" },
  { key: "amber_slate", primary: "#f59e0b", secondary: "#94a3b8", glow: "#fcd34d" },
  { key: "lime_azure", primary: "#a3e635", secondary: "#38bdf8", glow: "#bef264" },
];
```

- [ ] **Step 4: Add slug, hash, palette, and style helpers**

In `profile-title-catalog.ts`, after `colorBuckets()`, add:

```ts
export function leaderNameKey(name: string): string {
  const normalized = name
    .trim()
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/gu, "")
    .replace(/[^a-z0-9]+/gu, "-")
    .replace(/^-+|-+$/gu, "");
  return normalized || "unknown";
}

function stableHash(input: string): number {
  let hash = 0;
  for (let index = 0; index < input.length; index += 1) {
    hash = (hash * 31 + input.charCodeAt(index)) >>> 0;
  }
  return hash;
}

function leaderNamePalette(slug: string): LeaderNamePalette {
  return leaderNamePalettes[stableHash(slug) % leaderNamePalettes.length];
}
```

After `botWinStyle`, add:

```ts
function leaderNameStyle(slug: string, tierIndex: number): Record<string, unknown> {
  const palette = leaderNamePalette(slug);
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
      text_color: palette.primary,
      font_family: "display",
      font_weight: 750,
      gradient: { from: palette.primary, to: palette.secondary, angle: 90 },
      animation: "none",
    };
  }
  if (tierIndex === 2) {
    return {
      text_color: palette.primary,
      font_family: "display",
      font_weight: 800,
      gradient: { from: palette.primary, to: palette.secondary, angle: 90 },
      glow_color: palette.glow,
      animation: "none",
    };
  }
  if (tierIndex === 3) {
    return {
      text_color: palette.primary,
      font_family: "display",
      font_weight: 900,
      gradient: { from: palette.primary, to: palette.secondary, angle: 90 },
      glow_color: palette.glow,
      animation: "shine",
    };
  }
  return {
    text_color: palette.primary,
    font_family: "display",
    font_weight: 900,
    gradient: { from: palette.primary, via: palette.secondary, to: palette.glow, angle: 90 },
    glow_color: palette.glow,
    animation: "shine",
  };
}
```

- [ ] **Step 5: Add dynamic leader catalog builder and static alias**

Rename the existing `buildProfileTitleCatalog()` function to `buildStaticProfileTitleCatalog()` and export it:

```ts
export function buildStaticProfileTitleCatalog(): ProfileTitleCatalog {
```

After it, add:

```ts
export function buildLeaderNameTitleCatalog(leaderNames: readonly string[]): ProfileTitleCatalog {
  const deduped = new Map<string, string>();
  for (const name of leaderNames) {
    const trimmed = name.trim();
    if (!trimmed) continue;
    const slug = leaderNameKey(trimmed);
    if (!deduped.has(slug)) deduped.set(slug, trimmed);
  }

  const leaders = [...deduped.entries()].sort(([leftSlug], [rightSlug]) => leftSlug.localeCompare(rightSlug));
  const titles: ProfileTitleCatalogTitle[] = [];
  const requirements: ProfileTitleCatalogRequirement[] = [];

  for (const [leaderIndex, [slug, label]] of leaders.entries()) {
    for (const [tierIndex, tier] of leaderNameTiers.entries()) {
      const titleKey = `${leaderNameMasterySeries.key}_${slug}_${tier.key}`;
      titles.push({
        key: titleKey,
        label: `${label} ${tier.label}`,
        unlock_mode: "automatic",
        style: leaderNameStyle(slug, tierIndex),
        active: true,
        sort_order: leaderNameMasterySeries.sort_order + leaderIndex * 10 + tierIndex,
        series_key: leaderNameMasterySeries.key,
        series_item_key: slug,
        series_item_label: label,
        tier_key: tier.key,
      });
      requirements.push({
        title_key: titleKey,
        stat_key: `leader_name_matches_completed:${slug}`,
        operator: "gte",
        threshold: tier.threshold,
      });
    }
  }

  return {
    series: [leaderNameMasterySeries],
    titles,
    requirements,
  };
}

export function mergeProfileTitleCatalogs(catalogs: readonly ProfileTitleCatalog[]): ProfileTitleCatalog {
  return {
    series: catalogs.flatMap((catalog) => catalog.series),
    titles: catalogs.flatMap((catalog) => catalog.titles),
    requirements: catalogs.flatMap((catalog) => catalog.requirements),
  };
}

export function buildProfileTitleCatalog(leaderNames: readonly string[] = []): ProfileTitleCatalog {
  const staticCatalog = buildStaticProfileTitleCatalog();
  if (leaderNames.length === 0) return staticCatalog;
  return mergeProfileTitleCatalogs([staticCatalog, buildLeaderNameTitleCatalog(leaderNames)]);
}
```

- [ ] **Step 6: Update static test import and run verification**

The existing static assertions can continue to call `buildProfileTitleCatalog()` with no arguments and expect two static series and 110 titles.

Run in `optcg-db`:

```powershell
npm.cmd run typecheck
npm.cmd run test
```

Expected: both commands exit `0`.

- [ ] **Step 7: Commit catalog generator changes**

Run in `optcg-db`:

```powershell
git add src/db/profile-title-catalog.ts test/profile-title-catalog.test.mjs
git commit -m "Add leader name title catalog generator"
```

---

### Task 2: Sync Dynamic Leader Titles From DB

**Files:**
- Modify: `optcg-db/src/db/sync-profile-title-catalog.ts`
- Modify: `optcg-db/test/profile-title-catalog.test.mjs`

- [ ] **Step 1: Add a sync helper export test**

In `optcg-db/test/profile-title-catalog.test.mjs`, update the import to include `managedProfileTitleSeriesKeys`:

```js
import {
  buildLeaderNameTitleCatalog,
  buildProfileTitleCatalog,
  leaderNameKey,
  managedProfileTitleSeriesKeys,
} from "../dist/db/profile-title-catalog.js";
```

After the existing static series assertions, add:

```js
assert.deepEqual(managedProfileTitleSeriesKeys, [
  "color_mastery",
  "bot_wins",
  "leader_name_mastery",
]);
```

Run:

```powershell
npm.cmd run test
```

Expected: test fails because `managedProfileTitleSeriesKeys` is not exported yet.

- [ ] **Step 2: Export managed series keys**

In `optcg-db/src/db/profile-title-catalog.ts`, after `leaderNameMasterySeries`, add:

```ts
export const managedProfileTitleSeriesKeys = [
  colorMasterySeries.key,
  botWinsSeries.key,
  leaderNameMasterySeries.key,
] as const;
```

- [ ] **Step 3: Refactor sync to build one DB-backed catalog**

In `optcg-db/src/db/sync-profile-title-catalog.ts`, replace the imports:

```ts
import { buildProfileTitleCatalog } from "./profile-title-catalog.js";
```

with:

```ts
import {
  buildProfileTitleCatalog,
  managedProfileTitleSeriesKeys,
  type ProfileTitleCatalog,
} from "./profile-title-catalog.js";
```

Add:

```ts
type LeaderNameRow = {
  name: string;
};

async function listLeaderNames(): Promise<string[]> {
  const result = await query<LeaderNameRow>(
    `
      SELECT DISTINCT name
      FROM cards
      WHERE language = 'en'
        AND card_type = 'Leader'
        AND name IS NOT NULL
      ORDER BY name ASC
    `,
  );
  return result.rows.map((row) => row.name);
}
```

Change the sync functions to accept a catalog:

```ts
async function syncSeries(catalog: ProfileTitleCatalog) {
```

```ts
async function syncTitles(catalog: ProfileTitleCatalog) {
```

```ts
async function syncRequirements(catalog: ProfileTitleCatalog) {
```

Remove all local `const catalog = buildProfileTitleCatalog();` lines inside those functions.

In `syncTitles`, replace the stale-title update:

```sql
WHERE series_key = 'color_mastery'
  AND NOT (key = ANY($1::text[]))
```

with:

```sql
WHERE series_key = ANY($2::text[])
  AND NOT (key = ANY($1::text[]))
```

and pass:

```ts
[titleKeys, [...managedProfileTitleSeriesKeys]]
```

Update `main()`:

```ts
const leaderNames = await listLeaderNames();
const catalog = buildProfileTitleCatalog(leaderNames);
await syncSeries(catalog);
await syncTitles(catalog);
await syncRequirements(catalog);
logger.info("Profile title catalog synced", {
  series: catalog.series.length,
  titles: catalog.titles.length,
});
```

- [ ] **Step 4: Verify DB package**

Run in `optcg-db`:

```powershell
npm.cmd run typecheck
npm.cmd run test
```

Expected: both commands exit `0`.

- [ ] **Step 5: Commit sync changes**

Run in `optcg-db`:

```powershell
git add src/db/profile-title-catalog.ts src/db/sync-profile-title-catalog.ts test/profile-title-catalog.test.mjs
git commit -m "Sync leader name title catalog from cards"
```

---

### Task 3: Final Verification

**Files:**
- No source files modified in this task.

- [ ] **Step 1: Run final checks**

Run in `optcg-db`:

```powershell
npm.cmd run typecheck
npm.cmd run test
npm.cmd run build
```

Expected: all commands exit `0`.

- [ ] **Step 2: Check status**

Run:

```powershell
git -C optcg-db status --short
```

Expected: clean.
