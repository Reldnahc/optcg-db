# Profile Title Admin Override Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an admin-controlled live override that lets selected accounts view and equip every active profile title.

**Architecture:** Store the override in a reusable auth-side feature override table keyed by `user_id` and `feature_key`. Admin API owns mutation and admin visibility; auth owns enforcement when listing and selecting titles. The admin app extends the existing Unlock Manager rather than adding a new page.

**Tech Stack:** PostgreSQL migrations in `optcg-db`, Fastify v5 admin/auth APIs, raw parameterized SQL through `optcg-db`, React 19 admin app with TanStack Query, TypeScript.

---

## File Map

- Create `optcg-db/src/db/migrations/054_user_feature_overrides.sql`: adds `auth.user_feature_overrides`.
- Modify `optcg-db/src/db/schema.ts`: adds `AuthUserFeatureOverride`.
- Modify `optcg-api-admin/src/admin/profileTitles.ts`: includes override state in user lookup, adds toggle endpoint, marks availability from override.
- Modify `optcg-api-admin/src/admin/profileTitles.test.ts`: route tests for lookup, toggle, and override availability.
- Modify `optcg-api-admin/src/schemas/admin.ts`: response/request schemas for the new field and endpoint.
- Modify `optcg-admin/src/api/types.ts`: admin client types for `profile_titles_all`.
- Modify `optcg-admin/src/api/hooks.ts`: toggle mutation hook.
- Modify `optcg-admin/src/pages/UnlockManager.tsx`: UI control for enabling/disabling all profile titles.
- Modify `optcg-auth/src/repos/profiles.ts`: title list and selection consult live override.
- Modify `optcg-auth/src/repos/sessions.ts`: selected title access consults live override.
- Modify `optcg-auth/test/repos.test.mjs`: repository tests for list and selection SQL.
- Modify `optcg-auth/test/auth-routes.test.mjs`: route tests for `/v1/me` and `/v1/me/profile/title`.

---

### Task 1: Add DB Feature Override Schema

**Files:**
- Create: `optcg-db/src/db/migrations/054_user_feature_overrides.sql`
- Modify: `optcg-db/src/db/schema.ts`
- Test: `optcg-db` typecheck and tests

- [ ] **Step 1: Add the migration**

Create `optcg-db/src/db/migrations/054_user_feature_overrides.sql`:

```sql
CREATE TABLE IF NOT EXISTS auth.user_feature_overrides (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  granted_by_admin_email TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, feature_key),
  CONSTRAINT user_feature_overrides_feature_key_check
    CHECK (feature_key ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
  CONSTRAINT user_feature_overrides_note_length_check
    CHECK (note IS NULL OR char_length(note) <= 500)
);

CREATE INDEX IF NOT EXISTS user_feature_overrides_enabled_idx
  ON auth.user_feature_overrides(user_id, feature_key)
  WHERE enabled IS TRUE;
```

- [ ] **Step 2: Add the shared schema type**

In `optcg-db/src/db/schema.ts`, near the other auth interfaces, add:

```ts
export interface AuthUserFeatureOverride {
  user_id: string;
  feature_key: string;
  enabled: boolean;
  granted_by_admin_email: string;
  note: string | null;
  created_at: string;
  updated_at: string;
}
```

- [ ] **Step 3: Verify DB package**

Run:

```powershell
npm.cmd run typecheck
npm.cmd run test
```

Expected: both commands exit `0`.

- [ ] **Step 4: Commit DB schema**

Run in `optcg-db`:

```powershell
git add src/db/migrations/054_user_feature_overrides.sql src/db/schema.ts
git commit -m "Add user feature override schema"
```

---

### Task 2: Add Admin API Override Endpoint

**Files:**
- Modify: `optcg-api-admin/src/admin/profileTitles.ts`
- Modify: `optcg-api-admin/src/admin/profileTitles.test.ts`
- Modify: `optcg-api-admin/src/schemas/admin.ts`

- [ ] **Step 1: Add failing tests for lookup and toggle**

In `optcg-api-admin/src/admin/profileTitles.test.ts`, add tests matching the existing `buildApp` and query-stub style:

```ts
test("admin profile title routes include profile title override state", async () => {
  const stub = createQueryStub([
    {
      match: "FROM auth.users u",
      result: {
        rows: [{
          ...userRow,
          profile_titles_all: true,
        }],
      },
    },
    {
      match: /FROM auth\.profile_titles pt/,
      result: { rows: [{ ...titleRow, unlocked: false, available: true }] },
    },
  ]);
  const app = buildApp(stub.queryExecutor);

  const response = await app.inject({ method: "GET", url: "/profile-titles/users/tester@example.com" });

  assert.equal(response.statusCode, 200);
  assert.equal(response.json().data.user.profile_titles_all, true);
  assert.equal(response.json().data.titles[0].available, true);
});

test("admin profile title routes toggle all-title override", async () => {
  const stub = createQueryStub([
    { match: "FROM auth.users u", result: { rows: [userRow] } },
    {
      match: "INSERT INTO auth.user_feature_overrides",
      assert: (_sql, params) => {
        assert.deepEqual(params, ["user-1", "profile_titles_all", true, "admin@example.com", "Catalog review."]);
      },
      result: { rows: [{ enabled: true }] },
    },
  ]);
  const app = buildApp(stub.queryExecutor);

  const response = await app.inject({
    method: "PUT",
    url: "/profile-titles/users/tester/overrides/profile-titles-all",
    payload: { enabled: true, note: "Catalog review." },
  });

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), { data: { ok: true, enabled: true } });
});
```

Run:

```powershell
npm.cmd run test -- profileTitles
```

Expected: tests fail because `profile_titles_all`, `available`, and the PUT route do not exist yet.

- [ ] **Step 2: Update admin schemas**

In `optcg-api-admin/src/schemas/admin.ts`:

Add `available` to `adminProfileTitleSchema.properties`:

```ts
available: { type: "boolean" },
```

Add `profile_titles_all` to `adminProfileTitleUserSchema.required` and properties:

```ts
required: ["id", "username", "display_name", "email", "selected_title_key", "profile_titles_all"],
properties: {
  id: { type: "string" },
  username: { type: "string" },
  display_name: { type: "string" },
  email: nullable({ type: "string" }),
  selected_title_key: nullable({ type: "string" }),
  profile_titles_all: { type: "boolean" },
},
```

Add:

```ts
export const adminToggleProfileTitleOverrideRouteSchema = {
  tags: ["Admin Profile Titles"],
  summary: "Toggle all profile title access for a user",
  security: adminSecurity,
  params: profileTitleIdentityParamSchema,
  body: {
    type: "object",
    additionalProperties: false,
    required: ["enabled"],
    properties: {
      enabled: { type: "boolean" },
      note: nullable({ type: "string", maxLength: 500 }),
    },
  },
  response: {
    200: okEnvelopeSchema({
      type: "object",
      additionalProperties: false,
      required: ["ok", "enabled"],
      properties: {
        ok: { type: "boolean" },
        enabled: { type: "boolean" },
      },
    }),
    400: errorEnvelopeSchema,
    401: errorEnvelopeSchema,
    404: errorEnvelopeSchema,
    500: errorEnvelopeSchema,
  },
};
```

- [ ] **Step 3: Implement admin route behavior**

In `optcg-api-admin/src/admin/profileTitles.ts`, import the new schema:

```ts
import {
  adminGrantProfileTitleRouteSchema,
  adminProfileTitleCatalogRouteSchema,
  adminProfileTitleUserRouteSchema,
  adminRevokeProfileTitleRouteSchema,
  adminToggleProfileTitleOverrideRouteSchema,
} from "../schemas/admin.js";
```

Add the feature key:

```ts
const PROFILE_TITLES_ALL_FEATURE_KEY = "profile_titles_all";
```

Update `AdminProfileTitleUser`:

```ts
type AdminProfileTitleUser = {
  id: string;
  username: string;
  display_name: string;
  email: string | null;
  selected_title_key: string | null;
  profile_titles_all: boolean;
};
```

Update `findUser` select:

```sql
COALESCE(override.enabled, false) AS profile_titles_all
```

and add:

```sql
LEFT JOIN auth.user_feature_overrides override
  ON override.user_id = u.id
 AND override.feature_key = 'profile_titles_all'
```

Change `listTitlesForUser` signature and SELECT:

```ts
async function listTitlesForUser(runQuery: QueryExecutor, userId: string, profileTitlesAll: boolean) {
```

```sql
$2::boolean AS available
```

or, if preserving physical availability separately:

```sql
(
  pt.unlock_mode = 'no_requirement'
  OR $2::boolean
  OR EXISTS (
    SELECT 1
    FROM auth.user_title_unlocks utu
    WHERE utu.user_id = $1
      AND utu.title_key = pt.key
      AND utu.revoked_at IS NULL
  )
) AS available
```

Keep `unlocked` as the physical unlock row boolean:

```sql
EXISTS (
  SELECT 1
  FROM auth.user_title_unlocks utu
  WHERE utu.user_id = $1
    AND utu.title_key = pt.key
    AND utu.revoked_at IS NULL
) AS unlocked
```

Call it as:

```ts
const titles = await listTitlesForUser(runQuery, user.id, user.profile_titles_all);
```

Add the PUT route:

```ts
app.put(
  "/profile-titles/users/:identity/overrides/profile-titles-all",
  { schema: adminToggleProfileTitleOverrideRouteSchema },
  async (req, reply) => {
    const { identity } = req.params as { identity: string };
    const body = (req.body ?? {}) as { enabled?: unknown; note?: unknown };

    if (!req.admin?.email) {
      reply.code(401);
      return adminError(401, "Admin authentication required.");
    }
    if (typeof body.enabled !== "boolean") {
      reply.code(400);
      return adminError(400, "enabled is required.");
    }

    const note = body.note == null ? null : String(body.note);

    try {
      const user = await findUser(runQuery, identity);
      if (!user) {
        reply.code(404);
        return adminError(404, "User not found.");
      }

      const result = await runQuery<{ enabled: boolean }>(
        `INSERT INTO auth.user_feature_overrides (
           user_id,
           feature_key,
           enabled,
           granted_by_admin_email,
           note
         )
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (user_id, feature_key)
         DO UPDATE SET
           enabled = EXCLUDED.enabled,
           granted_by_admin_email = EXCLUDED.granted_by_admin_email,
           note = EXCLUDED.note,
           updated_at = now()
         RETURNING enabled`,
        [user.id, PROFILE_TITLES_ALL_FEATURE_KEY, body.enabled, req.admin.email, note],
      );

      return { data: { ok: true, enabled: result.rows[0]?.enabled ?? body.enabled } };
    } catch (error) {
      app.log.error({ err: error }, "Failed to toggle profile title override");
      return replyWithError(reply, 500, getErrorMessage(error));
    }
  },
);
```

- [ ] **Step 4: Verify admin API**

Run in `optcg-api-admin`:

```powershell
npm.cmd run test -- profileTitles
npm.cmd run typecheck
npm.cmd run build
```

Expected: all commands exit `0`.

- [ ] **Step 5: Commit admin API**

Run in `optcg-api-admin`:

```powershell
git add src/admin/profileTitles.ts src/admin/profileTitles.test.ts src/schemas/admin.ts
git commit -m "Add profile title override admin API"
```

---

### Task 3: Make Auth Respect the Override

**Files:**
- Modify: `optcg-auth/src/repos/profiles.ts`
- Modify: `optcg-auth/src/repos/sessions.ts`
- Modify: `optcg-auth/test/repos.test.mjs`
- Modify: `optcg-auth/test/auth-routes.test.mjs`

- [ ] **Step 1: Add failing repo tests**

In `optcg-auth/test/repos.test.mjs`, add:

```js
await runTest("listUnlockedProfileTitles allows active titles with admin override", async () => {
  const calls = [];
  const runQuery = async (sql, params = []) => {
    calls.push({ sql, params });
    assert.match(sql, /auth\.user_feature_overrides/);
    assert.deepEqual(params, ["user-1", "profile_titles_all"]);
    return {
      rows: [
        {
          key: "pirate_rookie",
          label: "Pirate Rookie",
          unlock_mode: "no_requirement",
          style: {},
          series_key: null,
          series_label: null,
          series_item_key: null,
          series_item_label: null,
          tier_key: null,
        },
        {
          key: "color_mastery_red_master",
          label: "Red Master",
          unlock_mode: "automatic",
          style: {},
          series_key: "color_mastery",
          series_label: "Color Mastery",
          series_item_key: "red",
          series_item_label: "Red",
          tier_key: "master",
        },
      ],
    };
  };

  const result = await listUnlockedProfileTitles(runQuery, "user-1");

  assert.deepEqual(result.map((title) => title.key), ["pirate_rookie", "color_mastery_red_master"]);
  assert.equal(calls.length, 1);
});

await runTest("updateProfileTitle allows active title with admin override", async () => {
  const calls = [];
  const runQuery = async (sql, params = []) => {
    calls.push({ sql, params });
    if (/SELECT pt\.key/i.test(sql)) {
      assert.match(sql, /auth\.user_feature_overrides/);
      assert.deepEqual(params, ["user-1", "color_mastery_red_master", "profile_titles_all"]);
      return { rows: [{ key: "color_mastery_red_master" }] };
    }
    if (/INSERT INTO auth\.user_profiles/i.test(sql)) {
      return { rows: [{ selected_title_key: params[1] }] };
    }
    throw new Error(`Unexpected SQL: ${sql}`);
  };

  const result = await updateProfileTitle(runQuery, "user-1", "color_mastery_red_master");

  assert.deepEqual(result, { selected_title_key: "color_mastery_red_master" });
  assert.equal(calls.length, 2);
});
```

Run:

```powershell
npm.cmd run build
node test/repos.test.mjs
```

Expected: tests fail because override access is not part of the SQL.

- [ ] **Step 2: Add a route-level regression test**

In `optcg-auth/test/auth-routes.test.mjs`, add a test beside the existing profile title route tests:

```js
await runTest("profile title update selects override-unlocked title", async () => {
  const db = createAuthDb();
  db.users.set("user-override-title", buildUser({
    id: "user-override-title",
    username: "override_title",
    display_name: "Override Title",
  }));
  db.sessions.set("token-override-title", {
    user_id: "user-override-title",
    expires_at: new Date(Date.now() + 60_000).toISOString(),
  });
  db.profileTitles.set("color_mastery_red_master", {
    key: "color_mastery_red_master",
    label: "Red Master",
    unlock_mode: "automatic",
    style: { text_color: "#f87171" },
    active: true,
    sort_order: 500,
    series_key: "color_mastery",
    series_label: "Color Mastery",
    series_item_key: "red",
    series_item_label: "Red",
    tier_key: "master",
  });
  db.featureOverrides.set("user-override-title:profile_titles_all", {
    enabled: true,
  });

  const app = await buildAuthRoutesApp(db);
  try {
    const response = await app.inject({
      method: "PUT",
      url: "/v1/me/profile/title",
      headers: { authorization: "Bearer token-override-title" },
      payload: { title_key: "color_mastery_red_master" },
    });

    assert.equal(response.statusCode, 200);
    assert.equal(response.json().data.user.profile.title.key, "color_mastery_red_master");
    assert.equal(db.profiles.get("user-override-title").selected_title_key, "color_mastery_red_master");
  } finally {
    await app.close();
  }
});
```

If `createAuthDb` does not already have `featureOverrides`, extend that in-memory test helper with:

```js
featureOverrides: new Map(),
```

and make its query stub return override rows when SQL contains `auth.user_feature_overrides`.

Run:

```powershell
npm.cmd run build
node test/auth-routes.test.mjs
```

Expected: the new route test fails before the auth SQL changes.

- [ ] **Step 3: Add a helper SQL predicate in `profiles.ts`**

In `optcg-auth/src/repos/profiles.ts`, add:

```ts
const PROFILE_TITLES_ALL_FEATURE_KEY = "profile_titles_all";
```

Update `listUnlockedProfileTitles` WHERE condition:

```sql
AND (
  pt.unlock_mode = 'no_requirement'
  OR EXISTS (
    SELECT 1
    FROM auth.user_feature_overrides ufo
    WHERE ufo.user_id = $1
      AND ufo.feature_key = 'profile_titles_all'
      AND ufo.enabled IS TRUE
  )
  OR EXISTS (
    SELECT 1
    FROM auth.user_title_unlocks utu
    WHERE utu.user_id = $1
      AND utu.title_key = pt.key
      AND utu.revoked_at IS NULL
  )
)
```

Use the constant as the second query parameter:

```ts
[userId, PROFILE_TITLES_ALL_FEATURE_KEY]
```

- [ ] **Step 4: Update title selection validation**

In `updateProfileTitle`, allow the same override:

```sql
AND (
  pt.unlock_mode = 'no_requirement'
  OR EXISTS (
    SELECT 1
    FROM auth.user_feature_overrides ufo
    WHERE ufo.user_id = $1
      AND ufo.feature_key = 'profile_titles_all'
      AND ufo.enabled IS TRUE
  )
  OR EXISTS (
    SELECT 1
    FROM auth.user_title_unlocks utu
    WHERE utu.user_id = $1
      AND utu.title_key = pt.key
      AND utu.revoked_at IS NULL
  )
)
```

- [ ] **Step 5: Update session selected-title join**

In `optcg-auth/src/repos/sessions.ts`, add the same override predicate to the `LEFT JOIN auth.profile_titles selected_title` access block:

```sql
OR EXISTS (
  SELECT 1
  FROM auth.user_feature_overrides selected_override
  WHERE selected_override.user_id = u.id
    AND selected_override.feature_key = 'profile_titles_all'
    AND selected_override.enabled IS TRUE
)
```

Keep default-title fallback unchanged so disabled override accounts do not serialize inaccessible selected titles.

- [ ] **Step 6: Verify auth**

Run in `optcg-auth`:

```powershell
npm.cmd run typecheck
npm.cmd run test
npm.cmd run build
```

Expected: all commands exit `0`.

- [ ] **Step 7: Commit auth**

Run in `optcg-auth`:

```powershell
git add src/repos/profiles.ts src/repos/sessions.ts test/repos.test.mjs test/auth-routes.test.mjs
git commit -m "Respect profile title admin override"
```

---

### Task 4: Add Admin App Toggle

**Files:**
- Modify: `optcg-admin/src/api/types.ts`
- Modify: `optcg-admin/src/api/hooks.ts`
- Modify: `optcg-admin/src/pages/UnlockManager.tsx`

- [ ] **Step 1: Update admin client types**

In `optcg-admin/src/api/types.ts`, update `AdminProfileTitle`:

```ts
export interface AdminProfileTitle {
  key: string;
  label: string;
  unlock_mode: "no_requirement" | "manual" | "automatic";
  style: Record<string, unknown>;
  active: boolean;
  sort_order: number;
  unlocked?: boolean;
  available?: boolean;
}
```

Update `AdminProfileTitleUser`:

```ts
export interface AdminProfileTitleUser {
  id: string;
  username: string;
  display_name: string;
  email: string | null;
  selected_title_key: string | null;
  profile_titles_all: boolean;
}
```

Add:

```ts
export interface ToggleProfileTitleOverrideResponse {
  data: {
    ok: true;
    enabled: boolean;
  };
}
```

- [ ] **Step 2: Add the mutation hook**

In `optcg-admin/src/api/hooks.ts`, import `ToggleProfileTitleOverrideResponse` if types are named imports in this file, then add:

```ts
export function useToggleProfileTitleOverrideMutation(identity: string) {
  const queryClient = useQueryClient();
  const normalized = identity.trim();
  return useMutation({
    mutationFn: (input: { enabled: boolean; note?: string | null }) =>
      adminFetch<ToggleProfileTitleOverrideResponse>(
        `/profile-titles/users/${encodeURIComponent(normalized)}/overrides/profile-titles-all`,
        {
          method: "PUT",
          body: input,
        },
      ),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.profileTitleUser(normalized) });
    },
  });
}
```

- [ ] **Step 3: Update availability helper**

In `optcg-admin/src/pages/UnlockManager.tsx`, replace:

```ts
function titleAvailability(title: AdminProfileTitle) {
  return title.unlocked || title.unlock_mode === "no_requirement";
}
```

with:

```ts
function titleAvailability(title: AdminProfileTitle) {
  return title.available ?? title.unlocked ?? title.unlock_mode === "no_requirement";
}
```

- [ ] **Step 4: Add the UI control**

In `UnlockManagerPage`, import the new hook:

```ts
useToggleProfileTitleOverrideMutation,
```

Add state and mutation:

```ts
const [overrideNote, setOverrideNote] = useState("");
const overrideMutation = useToggleProfileTitleOverrideMutation(activeIdentity);
```

Reset it in `handleLoad`:

```ts
overrideMutation.reset();
setOverrideNote("");
```

Add handler:

```ts
async function handleToggleOverride(enabled: boolean) {
  const note = overrideNote.trim();
  try {
    await overrideMutation.mutateAsync({
      enabled,
      note: note || undefined,
    });
    setOverrideNote("");
  } catch {
    // React Query keeps the error for the in-page state.
  }
}
```

In the loaded user summary `Panel`, add a compact control beside the existing selected-title status:

```tsx
<div className="mt-5 rounded-2xl border border-border bg-bg-card p-4">
  <div className="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
    <div className="min-w-0">
      <p className="font-semibold text-text-primary">All profile titles</p>
      <p className="mt-1 text-sm text-text-secondary">
        {loadedUser.profile_titles_all
          ? "This account can view and equip every active title."
          : "This account only sees earned, default, and manual titles."}
      </p>
    </div>
    <StatusBadge tone={loadedUser.profile_titles_all ? "success" : "neutral"}>
      {loadedUser.profile_titles_all ? "Enabled" : "Disabled"}
    </StatusBadge>
  </div>
  <div className="mt-4 flex flex-col gap-3 lg:flex-row lg:items-end">
    <div className="min-w-0 flex-1">
      <TextField
        label="Override note"
        onChange={(event) => setOverrideNote(event.target.value)}
        placeholder="Optional"
        value={overrideNote}
      />
    </div>
    {overrideMutation.isError ? <ErrorState message={getErrorMessage(overrideMutation.error)} /> : null}
    <Button
      className="whitespace-nowrap"
      disabled={overrideMutation.isPending}
      onClick={() => void handleToggleOverride(!loadedUser.profile_titles_all)}
      tone={loadedUser.profile_titles_all ? "danger" : "primary"}
      type="button"
    >
      {loadedUser.profile_titles_all ? "Disable All Titles" : "Enable All Titles"}
    </Button>
  </div>
</div>
```

If `Button` does not support `tone="primary"`, omit the `tone` prop for the enable state and keep `tone="danger"` for disable.

- [ ] **Step 5: Verify admin app**

Run in `optcg-admin`:

```powershell
npm.cmd run typecheck
npm.cmd run build
```

Expected: both commands exit `0`.

- [ ] **Step 6: Commit admin app**

Run in `optcg-admin`:

```powershell
git status --short
git add src/api/types.ts src/api/hooks.ts src/pages/UnlockManager.tsx
git commit -m "Add profile title override admin control"
```

Do not add `public/crop-canon-review.html`; it was already dirty before this work.

---

### Task 5: Final Cross-Repo Verification

**Files:**
- No source files created in this task.
- Verify all modified repos from Tasks 1-4.

- [ ] **Step 1: Check repo statuses**

Run:

```powershell
git -C optcg-db status --short
git -C optcg-api-admin status --short
git -C optcg-admin status --short
git -C optcg-auth -c safe.directory=C:/Users/cwmle/Documents/poneglyph.one/optcg-auth status --short
```

Expected:

- `optcg-db`: clean.
- `optcg-api-admin`: clean.
- `optcg-auth`: clean.
- `optcg-admin`: only the pre-existing `public/crop-canon-review.html` is dirty.

- [ ] **Step 2: Run final verification**

Run:

```powershell
cd optcg-db
npm.cmd run typecheck
npm.cmd run test
cd ..\optcg-api-admin
npm.cmd run test
npm.cmd run typecheck
npm.cmd run build
cd ..\optcg-auth
npm.cmd run typecheck
npm.cmd run test
npm.cmd run build
cd ..\optcg-admin
npm.cmd run typecheck
npm.cmd run build
```

Expected: every command exits `0`.

- [ ] **Step 3: Prepare deployment notes**

Report:

```text
Implemented live profile title override.

Commits:
- optcg-db: <commit>
- optcg-api-admin: <commit>
- optcg-auth: <commit>
- optcg-admin: <commit>

Verification:
- optcg-db typecheck/test passed
- optcg-api-admin test/typecheck/build passed
- optcg-auth typecheck/test/build passed
- optcg-admin typecheck/build passed

Deploy order:
1. Publish/deploy optcg-db migration package.
2. Run DB migration.
3. Deploy optcg-api-admin and optcg-auth.
4. Deploy optcg-admin.
```
