# Color Mastery Title Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Color Mastery unlockable title catalog, sync it into the database, and expose optional unlocked-title grouping metadata to clients.

**Architecture:** `optcg-db` owns the schema and generated title catalog. `optcg-auth` reads title metadata from the database and serializes it as optional fields on selected/unlocked title objects. `optcg-auth-client` and `optcg-web` update their public TypeScript types; the current web selector remains unlocked-only.

**Tech Stack:** PostgreSQL migrations, Node 20, TypeScript ESM, Fastify JSON schemas, plain Node test scripts.

---

## File Structure

- Create `optcg-db/src/db/migrations/052_profile_title_series.sql`: add title series table and metadata columns.
- Modify `optcg-db/src/db/schema.ts`: add `AuthProfileTitleSeries` and metadata fields on `AuthProfileTitle`.
- Create `optcg-db/src/db/profile-title-catalog.ts`: generate Color Mastery titles and requirements.
- Create `optcg-db/src/db/sync-profile-title-catalog.ts`: idempotently sync generated title catalog to Postgres.
- Create `optcg-db/test/profile-title-catalog.test.mjs`: verify generated catalog shape after build.
- Modify `optcg-db/package.json`: add catalog sync/test scripts.
- Modify `optcg-auth/src/auth/serializeUser.ts`: include optional catalog metadata on serialized profile titles.
- Modify `optcg-auth/src/repos/profiles.ts`: select unlocked title metadata and series label.
- Modify `optcg-auth/src/repos/sessions.ts`: select selected-title metadata and default-title metadata.
- Modify `optcg-auth/src/routes/me.ts`: preserve metadata when mapping unlocked titles.
- Modify `optcg-auth/src/schemas/auth.ts`: allow optional/null metadata fields on profile title objects.
- Modify `optcg-auth/test/repos.test.mjs`: assert unlocked title query includes metadata.
- Modify `optcg-auth/test/auth-routes.test.mjs`: assert profile title metadata serializes and legacy titles still work.
- Modify `optcg-auth-client/src/index.ts`: add optional profile title metadata fields.
- Modify `optcg-web/src/api/client.ts`: add optional metadata fields to `AuthProfileTitle`.
- Do not modify `optcg-sim-dev` in this plan. Extra title fields are ignored by its existing title projection.

---

### Task 1: Add DB Series Schema

**Files:**
- Create: `optcg-db/src/db/migrations/052_profile_title_series.sql`
- Modify: `optcg-db/src/db/schema.ts`
- Verify: `optcg-db`

- [ ] **Step 1: Write the migration**

Create `optcg-db/src/db/migrations/052_profile_title_series.sql`:

```sql
CREATE TABLE IF NOT EXISTS auth.profile_title_series (
  key TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT profile_title_series_key_format_check
    CHECK (key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  CONSTRAINT profile_title_series_label_length_check
    CHECK (char_length(label) BETWEEN 1 AND 64),
  CONSTRAINT profile_title_series_description_length_check
    CHECK (description IS NULL OR char_length(description) <= 500)
);

CREATE INDEX IF NOT EXISTS profile_title_series_active_sort_idx
  ON auth.profile_title_series(active, sort_order, key);

ALTER TABLE auth.profile_titles
  ADD COLUMN IF NOT EXISTS series_key TEXT
    REFERENCES auth.profile_title_series(key) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS series_item_key TEXT,
  ADD COLUMN IF NOT EXISTS series_item_label TEXT,
  ADD COLUMN IF NOT EXISTS tier_key TEXT;

ALTER TABLE auth.profile_titles
  DROP CONSTRAINT IF EXISTS profile_titles_series_item_key_format_check,
  DROP CONSTRAINT IF EXISTS profile_titles_tier_key_format_check,
  DROP CONSTRAINT IF EXISTS profile_titles_series_item_label_length_check;

ALTER TABLE auth.profile_titles
  ADD CONSTRAINT profile_titles_series_item_key_format_check
    CHECK (series_item_key IS NULL OR series_item_key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  ADD CONSTRAINT profile_titles_tier_key_format_check
    CHECK (tier_key IS NULL OR tier_key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  ADD CONSTRAINT profile_titles_series_item_label_length_check
    CHECK (series_item_label IS NULL OR char_length(series_item_label) BETWEEN 1 AND 64);

CREATE INDEX IF NOT EXISTS profile_titles_series_idx
  ON auth.profile_titles(series_key, series_item_key, tier_key)
  WHERE series_key IS NOT NULL;
```

- [ ] **Step 2: Update DB TypeScript schema types**

In `optcg-db/src/db/schema.ts`, add:

```ts
export interface AuthProfileTitleSeries {
  key: string;
  label: string;
  description: string | null;
  active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}
```

Update `AuthProfileTitle`:

```ts
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
```

- [ ] **Step 3: Run DB typecheck**

Run:

```powershell
npm.cmd run typecheck
```

Expected: `tsc --noEmit` exits 0.

- [ ] **Step 4: Commit**

```powershell
git add src/db/migrations/052_profile_title_series.sql src/db/schema.ts
git commit -m "Add profile title series schema"
```

---

### Task 2: Add Color Mastery Catalog Generator

**Files:**
- Create: `optcg-db/src/db/profile-title-catalog.ts`
- Create: `optcg-db/test/profile-title-catalog.test.mjs`
- Modify: `optcg-db/package.json`

- [ ] **Step 1: Add catalog generator**

Create `optcg-db/src/db/profile-title-catalog.ts`:

```ts
import type { AuthProfileTitleUnlockMode } from "./schema.js";

export type ProfileTitleCatalogSeries = {
  key: string;
  label: string;
  description: string | null;
  active: boolean;
  sort_order: number;
};

export type ProfileTitleCatalogTitle = {
  key: string;
  label: string;
  unlock_mode: AuthProfileTitleUnlockMode;
  style: Record<string, unknown>;
  active: boolean;
  sort_order: number;
  series_key: string;
  series_item_key: string;
  series_item_label: string;
  tier_key: string;
};

export type ProfileTitleCatalogRequirement = {
  title_key: string;
  stat_key: string;
  operator: "gte";
  threshold: bigint;
};

export type ProfileTitleCatalog = {
  series: ProfileTitleCatalogSeries[];
  titles: ProfileTitleCatalogTitle[];
  requirements: ProfileTitleCatalogRequirement[];
};

type ColorKey = "red" | "green" | "blue" | "purple" | "black" | "yellow";

type ColorConfig = {
  key: ColorKey;
  label: string;
  color: string;
  glow: string;
};

type ColorBucketConfig = {
  key: string;
  label: string;
  colors: readonly ColorConfig[];
};

type ColorMasteryTier = {
  key: "novice" | "adept" | "enjoyer" | "expert" | "master";
  label: string;
  threshold: bigint;
};

export const colorMasterySeries: ProfileTitleCatalogSeries = {
  key: "color_mastery",
  label: "Color Mastery",
  description: "Titles earned by completing games with specific leader color identities.",
  active: true,
  sort_order: 100,
};

const colorConfigs: readonly ColorConfig[] = [
  { key: "red", label: "Red", color: "#ef4444", glow: "#f87171" },
  { key: "green", label: "Green", color: "#22c55e", glow: "#4ade80" },
  { key: "blue", label: "Blue", color: "#38bdf8", glow: "#7dd3fc" },
  { key: "purple", label: "Purple", color: "#a855f7", glow: "#c084fc" },
  { key: "black", label: "Black", color: "#d1d5db", glow: "#9ca3af" },
  { key: "yellow", label: "Yellow", color: "#facc15", glow: "#fde047" },
];

const colorMasteryTiers: readonly ColorMasteryTier[] = [
  { key: "novice", label: "Novice", threshold: 10n },
  { key: "adept", label: "Adept", threshold: 25n },
  { key: "enjoyer", label: "Enjoyer", threshold: 100n },
  { key: "expert", label: "Expert", threshold: 500n },
  { key: "master", label: "Master", threshold: 1000n },
];

function colorBuckets(): ColorBucketConfig[] {
  const buckets: ColorBucketConfig[] = colorConfigs.map((color) => ({
    key: `mono-${color.key}`,
    label: color.label,
    colors: [color],
  }));
  for (let leftIndex = 0; leftIndex < colorConfigs.length; leftIndex += 1) {
    for (let rightIndex = leftIndex + 1; rightIndex < colorConfigs.length; rightIndex += 1) {
      const left = colorConfigs[leftIndex];
      const right = colorConfigs[rightIndex];
      buckets.push({
        key: `${left.key}-${right.key}`,
        label: `${left.label}-${right.label}`,
        colors: [left, right],
      });
    }
  }
  return buckets;
}

function colorMasteryStyle(bucket: ColorBucketConfig, tierIndex: number): Record<string, unknown> {
  const [primary, secondary] = bucket.colors;
  if (tierIndex === 0) {
    return { text_color: "#e8e9ed", font_family: "display", font_weight: 700, animation: "none" };
  }
  const gradient = secondary === undefined
    ? { from: primary.color, to: primary.glow, angle: 90 }
    : { from: primary.color, to: secondary.color, angle: 90 };
  if (tierIndex === 1) {
    return { text_color: primary.color, font_family: "display", font_weight: 750, gradient, animation: "none" };
  }
  if (tierIndex === 2) {
    return { text_color: primary.color, font_family: "display", font_weight: 800, gradient, glow_color: primary.glow, animation: "none" };
  }
  return { text_color: primary.color, font_family: "display", font_weight: 900, gradient, glow_color: primary.glow, animation: "shine" };
}

export function buildProfileTitleCatalog(): ProfileTitleCatalog {
  const titles: ProfileTitleCatalogTitle[] = [];
  const requirements: ProfileTitleCatalogRequirement[] = [];
  const buckets = colorBuckets();
  for (const [bucketIndex, bucket] of buckets.entries()) {
    for (const [tierIndex, tier] of colorMasteryTiers.entries()) {
      const titleKey = `color_mastery_${bucket.key}_${tier.key}`;
      titles.push({
        key: titleKey,
        label: `${bucket.label} ${tier.label}`,
        unlock_mode: "automatic",
        style: colorMasteryStyle(bucket, tierIndex),
        active: true,
        sort_order: colorMasterySeries.sort_order + bucketIndex * 10 + tierIndex,
        series_key: colorMasterySeries.key,
        series_item_key: bucket.key,
        series_item_label: bucket.label,
        tier_key: tier.key,
      });
      requirements.push({
        title_key: titleKey,
        stat_key: `leader_color_matches_completed:${bucket.key}`,
        operator: "gte",
        threshold: tier.threshold,
      });
    }
  }
  return {
    series: [colorMasterySeries],
    titles,
    requirements,
  };
}
```

- [ ] **Step 2: Add catalog tests**

Create `optcg-db/test/profile-title-catalog.test.mjs`:

```js
import assert from "node:assert/strict";
import { buildProfileTitleCatalog } from "../dist/db/profile-title-catalog.js";

const catalog = buildProfileTitleCatalog();
const titles = catalog.titles;
const requirements = catalog.requirements;

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

const keyPattern = /^[a-z0-9][a-z0-9_-]{1,63}$/u;
for (const title of titles) {
  assert.match(title.key, keyPattern);
  assert.equal(title.series_key, "color_mastery");
  assert.equal(title.unlock_mode, "automatic");
  assert.equal(title.active, true);
  assert.equal(typeof title.series_item_label, "string");
}

const buckets = new Set(titles.map((title) => title.series_item_key));
assert.equal(buckets.size, 21);
assert.deepEqual([...buckets], [
  "mono-red",
  "mono-green",
  "mono-blue",
  "mono-purple",
  "mono-black",
  "mono-yellow",
  "red-green",
  "red-blue",
  "red-purple",
  "red-black",
  "red-yellow",
  "green-blue",
  "green-purple",
  "green-black",
  "green-yellow",
  "blue-purple",
  "blue-black",
  "blue-yellow",
  "purple-black",
  "purple-yellow",
  "black-yellow",
]);

for (const bucket of buckets) {
  const bucketTitles = titles.filter((title) => title.series_item_key === bucket);
  assert.deepEqual(bucketTitles.map((title) => title.tier_key), [
    "novice",
    "adept",
    "enjoyer",
    "expert",
    "master",
  ]);
  assert.deepEqual(
    requirements
      .filter((requirement) => requirement.title_key.startsWith(`color_mastery_${bucket}_`))
      .map((requirement) => requirement.threshold.toString()),
    ["10", "25", "100", "500", "1000"],
  );
}

assert.equal(
  titles.find((title) => title.key === "color_mastery_mono-red_master")?.label,
  "Red Master",
);
assert.equal(
  titles.find((title) => title.key === "color_mastery_red-blue_enjoyer")?.label,
  "Red-Blue Enjoyer",
);
assert.equal(
  requirements.find((requirement) => requirement.title_key === "color_mastery_red-blue_master")?.stat_key,
  "leader_color_matches_completed:red-blue",
);
```

- [ ] **Step 3: Add DB package test script**

In `optcg-db/package.json`, add:

```json
"test": "npm run build && node test/profile-title-catalog.test.mjs",
```

Keep the existing scripts unchanged.

- [ ] **Step 4: Run catalog test**

Run:

```powershell
npm.cmd run test
```

Expected: build succeeds and the Node assertions exit 0.

- [ ] **Step 5: Commit**

```powershell
git add package.json src/db/profile-title-catalog.ts test/profile-title-catalog.test.mjs
git commit -m "Add color mastery title catalog"
```

---

### Task 3: Add DB Catalog Sync Command

**Files:**
- Create: `optcg-db/src/db/sync-profile-title-catalog.ts`
- Modify: `optcg-db/package.json`

- [ ] **Step 1: Add sync command**

Create `optcg-db/src/db/sync-profile-title-catalog.ts`:

```ts
import { closePool, query } from "./client.js";
import { buildProfileTitleCatalog } from "./profile-title-catalog.js";
import { logger } from "../shared/logger.js";

async function syncSeries() {
  const catalog = buildProfileTitleCatalog();
  for (const series of catalog.series) {
    await query(
      `
        INSERT INTO auth.profile_title_series (key, label, description, active, sort_order)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (key) DO UPDATE SET
          label = EXCLUDED.label,
          description = EXCLUDED.description,
          active = EXCLUDED.active,
          sort_order = EXCLUDED.sort_order,
          updated_at = now()
      `,
      [series.key, series.label, series.description, series.active, series.sort_order],
    );
  }
}

async function syncTitles() {
  const catalog = buildProfileTitleCatalog();
  const titleKeys = catalog.titles.map((title) => title.key);
  for (const title of catalog.titles) {
    await query(
      `
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
        VALUES ($1, $2, $3, $4::jsonb, $5, $6, $7, $8, $9, $10)
        ON CONFLICT (key) DO UPDATE SET
          label = EXCLUDED.label,
          unlock_mode = EXCLUDED.unlock_mode,
          style = EXCLUDED.style,
          active = EXCLUDED.active,
          sort_order = EXCLUDED.sort_order,
          series_key = EXCLUDED.series_key,
          series_item_key = EXCLUDED.series_item_key,
          series_item_label = EXCLUDED.series_item_label,
          tier_key = EXCLUDED.tier_key,
          updated_at = now()
      `,
      [
        title.key,
        title.label,
        title.unlock_mode,
        JSON.stringify(title.style),
        title.active,
        title.sort_order,
        title.series_key,
        title.series_item_key,
        title.series_item_label,
        title.tier_key,
      ],
    );
  }
  await query(
    `
      UPDATE auth.profile_titles
      SET active = false, updated_at = now()
      WHERE series_key = 'color_mastery'
        AND NOT (key = ANY($1::text[]))
    `,
    [titleKeys],
  );
}

async function syncRequirements() {
  const catalog = buildProfileTitleCatalog();
  const titleKeys = catalog.titles.map((title) => title.key);
  await query(
    `
      DELETE FROM auth.profile_title_requirements
      WHERE title_key = ANY($1::text[])
    `,
    [titleKeys],
  );
  for (const requirement of catalog.requirements) {
    await query(
      `
        INSERT INTO auth.profile_title_requirements (title_key, stat_key, operator, threshold)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT DO NOTHING
      `,
      [
        requirement.title_key,
        requirement.stat_key,
        requirement.operator,
        requirement.threshold.toString(),
      ],
    );
  }
}

async function main() {
  try {
    await syncSeries();
    await syncTitles();
    await syncRequirements();
    logger.info("Profile title catalog synced", {
      series: 1,
      titles: buildProfileTitleCatalog().titles.length,
    });
  } catch (error) {
    logger.error("Profile title catalog sync failed", {
      error: error instanceof Error ? error.message : String(error),
    });
    process.exitCode = 1;
  } finally {
    await closePool();
  }
}

main();
```

- [ ] **Step 2: Add package script**

In `optcg-db/package.json`, add:

```json
"sync:title-catalog": "tsx src/db/sync-profile-title-catalog.ts",
```

- [ ] **Step 3: Run build and test**

Run:

```powershell
npm.cmd run build
npm.cmd run test
```

Expected: both exit 0.

- [ ] **Step 4: Commit**

```powershell
git add package.json src/db/sync-profile-title-catalog.ts
git commit -m "Add profile title catalog sync command"
```

---

### Task 4: Expose Title Metadata From Auth

**Files:**
- Modify: `optcg-auth/src/auth/serializeUser.ts`
- Modify: `optcg-auth/src/repos/profiles.ts`
- Modify: `optcg-auth/src/repos/sessions.ts`
- Modify: `optcg-auth/src/routes/me.ts`
- Modify: `optcg-auth/src/schemas/auth.ts`
- Modify: `optcg-auth/test/repos.test.mjs`
- Modify: `optcg-auth/test/auth-routes.test.mjs`

- [ ] **Step 1: Update serialized title type**

In `optcg-auth/src/auth/serializeUser.ts`, change `SerializedProfileTitle` to:

```ts
export type SerializedProfileTitle = {
  key: string;
  label: string;
  style: ProfileTitleStyle;
  series_key?: string | null;
  series_label?: string | null;
  series_item_key?: string | null;
  series_item_label?: string | null;
  tier_key?: string | null;
};
```

Add a helper:

```ts
function titleMetadata(user: AuthUserWithProfile) {
  return {
    ...(user.selected_title_series_key === undefined ? {} : { series_key: user.selected_title_series_key }),
    ...(user.selected_title_series_label === undefined ? {} : { series_label: user.selected_title_series_label }),
    ...(user.selected_title_series_item_key === undefined ? {} : { series_item_key: user.selected_title_series_item_key }),
    ...(user.selected_title_series_item_label === undefined ? {} : { series_item_label: user.selected_title_series_item_label }),
    ...(user.selected_title_tier_key === undefined ? {} : { tier_key: user.selected_title_tier_key }),
  };
}
```

Extend `AuthUserWithProfile` with selected metadata:

```ts
  selected_title_series_key?: string | null;
  selected_title_series_label?: string | null;
  selected_title_series_item_key?: string | null;
  selected_title_series_item_label?: string | null;
  selected_title_tier_key?: string | null;
```

Use the metadata helper in selected title serialization:

```ts
  const title = user.selected_title_key && user.selected_title_label
    ? {
        key: user.selected_title_key,
        label: user.selected_title_label,
        style: serializeTitleStyle(user.selected_title_style),
        ...titleMetadata(user),
      }
    : null;
```

- [ ] **Step 2: Select unlocked title metadata**

In `optcg-auth/src/repos/profiles.ts`, update `SerializedTitleRow`:

```ts
export type SerializedTitleRow = {
  key: string;
  label: string;
  unlock_mode: "no_requirement" | "manual" | "automatic";
  style: unknown;
  series_key: string | null;
  series_label: string | null;
  series_item_key: string | null;
  series_item_label: string | null;
  tier_key: string | null;
};
```

Update the unlocked-title query `SELECT`:

```sql
SELECT
  pt.key,
  pt.label,
  pt.unlock_mode,
  pt.style,
  pt.series_key,
  pts.label AS series_label,
  pt.series_item_key,
  pt.series_item_label,
  pt.tier_key
FROM auth.profile_titles pt
LEFT JOIN auth.profile_title_series pts ON pts.key = pt.series_key
```

Keep the current `WHERE` and `ORDER BY`, but use:

```sql
ORDER BY
  COALESCE(pts.sort_order, 0) ASC,
  pt.sort_order ASC,
  pt.key ASC
```

- [ ] **Step 3: Select session selected-title metadata**

In `optcg-auth/src/repos/sessions.ts`, add row fields:

```ts
selected_title_series_key?: string | null;
selected_title_series_label?: string | null;
selected_title_series_item_key?: string | null;
selected_title_series_item_label?: string | null;
selected_title_tier_key?: string | null;
```

Add to the main `SELECT`:

```sql
COALESCE(selected_title.series_key, default_title.series_key) AS selected_title_series_key,
COALESCE(selected_title_series.label, default_title.series_label) AS selected_title_series_label,
COALESCE(selected_title.series_item_key, default_title.series_item_key) AS selected_title_series_item_key,
COALESCE(selected_title.series_item_label, default_title.series_item_label) AS selected_title_series_item_label,
COALESCE(selected_title.tier_key, default_title.tier_key) AS selected_title_tier_key,
```

Add this join after `selected_title`:

```sql
LEFT JOIN auth.profile_title_series selected_title_series ON selected_title_series.key = selected_title.series_key
```

Change the default title lateral select to:

```sql
SELECT
  pt.key,
  pt.label,
  pt.style,
  pt.series_key,
  pts.label AS series_label,
  pt.series_item_key,
  pt.series_item_label,
  pt.tier_key
FROM auth.profile_titles pt
LEFT JOIN auth.profile_title_series pts ON pts.key = pt.series_key
```

Add the selected metadata fields to the returned `user` object the same way existing selected title fields are conditionally included.

- [ ] **Step 4: Preserve metadata in `/me` routes**

In `optcg-auth/src/routes/me.ts`, replace both unlocked-title mapping blocks with:

```ts
const serializeUnlockedTitle = (title: Awaited<ReturnType<typeof listUnlockedProfileTitles>>[number]) => ({
  key: title.key,
  label: title.label,
  style: serializeTitleStyle(title.style),
  series_key: title.series_key,
  series_label: title.series_label,
  series_item_key: title.series_item_key,
  series_item_label: title.series_item_label,
  tier_key: title.tier_key,
});
```

Use:

```ts
unlocked_titles: unlockedTitles.map(serializeUnlockedTitle),
```

and:

```ts
unlocked_titles: unlockedRows.map(serializeUnlockedTitle),
```

When building the selected title in the title update route, include:

```ts
selected_title_series_key: selected?.series_key ?? null,
selected_title_series_label: selected?.series_label ?? null,
selected_title_series_item_key: selected?.series_item_key ?? null,
selected_title_series_item_label: selected?.series_item_label ?? null,
selected_title_tier_key: selected?.tier_key ?? null,
```

- [ ] **Step 5: Update auth schema**

In `optcg-auth/src/schemas/auth.ts`, add these optional properties to `profileTitleSchema.properties`:

```ts
series_key: { anyOf: [{ type: "string" }, { type: "null" }] },
series_label: { anyOf: [{ type: "string" }, { type: "null" }] },
series_item_key: { anyOf: [{ type: "string" }, { type: "null" }] },
series_item_label: { anyOf: [{ type: "string" }, { type: "null" }] },
tier_key: { anyOf: [{ type: "string" }, { type: "null" }] },
```

Do not add these fields to `required`.

- [ ] **Step 6: Update route test fixtures**

In `optcg-auth/test/auth-routes.test.mjs`, update `QueryStub` title rows returned from `FROM auth.profile_titles pt` to include metadata:

```js
series_key: title.series_key ?? null,
series_label: title.series_label ?? null,
series_item_key: title.series_item_key ?? null,
series_item_label: title.series_item_label ?? null,
tier_key: title.tier_key ?? null,
```

Add one Color Mastery title fixture in `profile serialization includes selected title and unlocked titles`:

```js
{
  key: "color_mastery_red-blue_adept",
  label: "Red-Blue Adept",
  unlock_mode: "automatic",
  style: {
    text_color: "#ef4444",
    gradient: { from: "#ef4444", to: "#38bdf8", angle: 90 },
    animation: "none",
  },
  active: true,
  sort_order: 110,
  series_key: "color_mastery",
  series_label: "Color Mastery",
  series_item_key: "red-blue",
  series_item_label: "Red-Blue",
  tier_key: "adept",
}
```

Assert the serialized unlocked title contains:

```js
assert.deepEqual(
  response.json().data.profile.unlocked_titles.find((title) => title.key === "color_mastery_red-blue_adept"),
  {
    key: "color_mastery_red-blue_adept",
    label: "Red-Blue Adept",
    style: {
      text_color: "#ef4444",
      animation: "none",
      gradient: { from: "#ef4444", to: "#38bdf8", angle: 90 },
    },
    series_key: "color_mastery",
    series_label: "Color Mastery",
    series_item_key: "red-blue",
    series_item_label: "Red-Blue",
    tier_key: "adept",
  },
);
```

- [ ] **Step 7: Update repo SQL tests**

In `optcg-auth/test/repos.test.mjs`, add assertions to the existing title-listing or profile-title test:

```js
assert.match(calls[0].sql, /LEFT JOIN auth\.profile_title_series pts/i);
assert.match(calls[0].sql, /pt\.series_item_key/i);
assert.match(calls[0].sql, /pt\.tier_key/i);
```

- [ ] **Step 8: Run auth tests**

Run:

```powershell
npm.cmd run test
```

Expected: build exits 0 and all auth test scripts print PASS without setting a failure exit code.

- [ ] **Step 9: Commit**

```powershell
git add src/auth/serializeUser.ts src/repos/profiles.ts src/repos/sessions.ts src/routes/me.ts src/schemas/auth.ts test/repos.test.mjs test/auth-routes.test.mjs
git commit -m "Expose profile title catalog metadata"
```

---

### Task 5: Update Public Client Types

**Files:**
- Modify: `optcg-auth-client/src/index.ts`
- Modify: `optcg-web/src/api/client.ts`

- [ ] **Step 1: Update auth client title type**

In `optcg-auth-client/src/index.ts`, update `ProfileTitle`:

```ts
export type ProfileTitle = {
  key: string;
  label: string;
  style: ProfileTitleStyle;
  series_key?: string | null;
  series_label?: string | null;
  series_item_key?: string | null;
  series_item_label?: string | null;
  tier_key?: string | null;
};
```

- [ ] **Step 2: Run auth client tests**

Run:

```powershell
npm.cmd run test
```

Expected: build exits 0 and `node test/client.test.mjs` exits 0.

- [ ] **Step 3: Commit auth client type update**

```powershell
git add src/index.ts test/client.test.mjs
git commit -m "Add profile title metadata client types"
```

- [ ] **Step 4: Update web local auth type**

In `optcg-web/src/api/client.ts`, update `AuthProfileTitle`:

```ts
export type AuthProfileTitle = {
  key: string;
  label: string;
  style: AuthProfileTitleStyle;
  series_key?: string | null;
  series_label?: string | null;
  series_item_key?: string | null;
  series_item_label?: string | null;
  tier_key?: string | null;
};
```

- [ ] **Step 5: Run web checks**

Run:

```powershell
npm.cmd run test
npm.cmd run build
```

Expected: tests exit 0 and Vite build exits 0.

- [ ] **Step 6: Commit web type update**

```powershell
git add src/api/client.ts
git commit -m "Add title catalog metadata web types"
```

---

### Task 6: Final Verification And Deployment Notes

**Files:**
- Verify: `optcg-db`
- Verify: `optcg-auth`
- Verify: `optcg-auth-client`
- Verify: `optcg-web`

- [ ] **Step 1: Verify DB package**

Run in `optcg-db`:

```powershell
npm.cmd run typecheck
npm.cmd run test
```

Expected: both exit 0.

- [ ] **Step 2: Verify auth service**

Run in `optcg-auth`:

```powershell
npm.cmd run typecheck
npm.cmd run test
```

Expected: both exit 0.

- [ ] **Step 3: Verify auth client**

Run in `optcg-auth-client`:

```powershell
npm.cmd run test
```

Expected: exits 0.

- [ ] **Step 4: Verify web**

Run in `optcg-web`:

```powershell
npm.cmd run test
npm.cmd run build
```

Expected: both exit 0.

- [ ] **Step 5: Deployment order**

Use this deployment order when the user explicitly asks to deploy or push:

1. Apply DB migration `052_profile_title_series.sql`.
2. Publish or otherwise make the updated `optcg-db` package available to consumers.
3. Deploy `optcg-auth` with the metadata serialization changes.
4. Run `npm.cmd run sync:title-catalog` from `optcg-db` against the target database.
5. Publish/update `optcg-auth-client` if web consumes the package version.
6. Deploy `optcg-web` after the local type update.

Do not push repositories until the user explicitly asks.
