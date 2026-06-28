import { closePool, query } from "./client.js";
import {
  buildProfileTitleCatalog,
  managedProfileTitleSeriesKeys,
  type ProfileTitleCatalog,
} from "./profile-title-catalog.js";
import { logger } from "../shared/logger.js";

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

async function syncSeries(catalog: ProfileTitleCatalog) {
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

async function syncTitles(catalog: ProfileTitleCatalog) {
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
      WHERE series_key = ANY($2::text[])
        AND NOT (key = ANY($1::text[]))
    `,
    [titleKeys, [...managedProfileTitleSeriesKeys]],
  );
}

async function syncRequirements(catalog: ProfileTitleCatalog) {
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
    const leaderNames = await listLeaderNames();
    const catalog = buildProfileTitleCatalog(leaderNames);
    await syncSeries(catalog);
    await syncTitles(catalog);
    await syncRequirements(catalog);
    logger.info("Profile title catalog synced", {
      series: catalog.series.length,
      titles: catalog.titles.length,
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
