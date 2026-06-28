# Profile Title Admin Override Design

## Goal

Let an admin mark a user account as able to view and select every active profile title without inserting physical unlock rows for each title. This is for admin/testing visibility of the title catalog while keeping normal users limited to their earned, default, or manually granted titles.

## Scope

This feature touches four repos:

- `optcg-db`: owns the override schema and shared row types.
- `optcg-api-admin`: exposes admin-only endpoints to view and toggle the override for an exact user identity.
- `optcg-admin`: adds the toggle to the existing Unlock Manager page.
- `optcg-auth`: treats the override as title access when listing and selecting profile titles.

The feature does not add a broad public admin role. It is scoped to profile-title access.

## Data Model

Add an account-level feature override table:

```sql
auth.user_feature_overrides (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  granted_by_admin_email TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, feature_key)
)
```

Use `feature_key = 'profile_titles_all'` for this feature.

The table is designed as a small reusable account override store, but the only supported feature key in this implementation is `profile_titles_all`. Admin routes should validate that key internally and not expose arbitrary feature creation.

## Admin API

Extend the existing profile title user response:

```ts
{
  user: {
    id: string;
    username: string;
    display_name: string;
    email: string | null;
    selected_title_key: string | null;
    profile_titles_all: boolean;
  };
  titles: AdminProfileTitle[];
}
```

Add one toggle endpoint under the existing admin profile title route family:

```http
PUT /admin/profile-titles/users/:identity/overrides/profile-titles-all
```

Request:

```ts
{
  enabled: boolean;
  note?: string | null;
}
```

Response:

```ts
{
  data: { ok: true; enabled: boolean }
}
```

Behavior:

- Resolve `:identity` the same way existing title routes do: user id, username, or email exact match.
- Require admin JWT auth and store `req.admin.email` as `granted_by_admin_email`.
- Upsert the row when enabled or disabled instead of deleting it, preserving audit context.
- Return `404` for unknown users.
- Return normal admin error envelopes.

The existing admin user-title listing should mark every active title as available when this override is enabled. It should still expose whether each title has a physical unlock row separately if needed by the UI. Existing manual grant/revoke behavior remains unchanged.

## Admin App

Update the existing Unlock Manager page, not a new page.

After loading a user, show an "All profile titles" control in the user summary area:

- Shows current override status.
- Has an enable/disable button.
- Supports an optional note when enabling or disabling.
- Invalidates the loaded user query after toggling.

The existing title table should show titles as available when the override is enabled. Manual revoke should remain available only for real manual unlock rows, not for override-provided access.

## Auth Service

The auth service must consult `auth.user_feature_overrides` in every place where title access is enforced:

- `listUnlockedProfileTitles`: include all active titles when `profile_titles_all` is enabled for the user.
- `updateProfileTitle`: allow selecting any active title when the override is enabled.
- session/user serialization: selected title joins should treat the override as valid selected-title access.

If the override is disabled later and the user's selected title is no longer unlocked, `/me` should fall back to the default `no_requirement` title rather than returning an invalid selected title. The existing selected key may remain stored in `auth.user_profiles`; the auth response determines what is actually usable.

## Tests

Add or update tests for:

- DB migration and schema type compile.
- Admin API user lookup includes `profile_titles_all`.
- Admin API toggle endpoint enables and disables the override.
- Admin API listing marks active titles available under the override while preserving manual unlock behavior.
- Auth title listing returns all active titles with the override.
- Auth title selection accepts active locked titles with the override and rejects them without it.
- Auth session serialization falls back to the default title when a selected title is no longer accessible.
- Admin app hooks and page behavior for loading, toggling, and invalidating user data.

## Out Of Scope

- Public API changes.
- A broad application admin role.
- Physical grant rows for every title.
- Unlock viewer for locked titles.
- Backfill for existing users.
