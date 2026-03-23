/**
 * Simple migration runner.
 * Migrations are numbered SQL files in src/db/migrations/.
 * Tracks applied migrations in a `_migrations` table.
 */

import fs from "node:fs";
import path from "node:path";
import type pg from "pg";
import { query, closePool, getPool } from "./client.js";
import { logger } from "../shared/logger.js";

const MIGRATIONS_DIR = path.join(import.meta.dirname, "migrations");

async function ensureMigrationsTable(): Promise<void> {
  await query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      id SERIAL PRIMARY KEY,
      name TEXT UNIQUE NOT NULL,
      applied_at TIMESTAMPTZ DEFAULT now()
    )
  `);
}

async function getAppliedMigrations(): Promise<Set<string>> {
  const result = await query<{ name: string }>("SELECT name FROM _migrations ORDER BY id");
  return new Set(result.rows.map((r) => r.name));
}

async function getMigrationFiles(): Promise<string[]> {
  const files = fs.readdirSync(MIGRATIONS_DIR).filter((f) => f.endsWith(".sql"));
  files.sort();
  return files;
}

async function runMigration(client: pg.PoolClient, name: string, sql: string): Promise<void> {
  logger.info("Running migration", { name });
  await client.query("BEGIN");
  try {
    await client.query(sql);
    await client.query("INSERT INTO _migrations (name) VALUES ($1)", [name]);
    await client.query("COMMIT");
    logger.info("Migration applied", { name });
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  }
}

async function main(): Promise<void> {
  try {
    await ensureMigrationsTable();
    const applied = await getAppliedMigrations();
    const files = await getMigrationFiles();

    const pending = files.filter((f) => !applied.has(f));

    if (pending.length === 0) {
      logger.info("No pending migrations");
      return;
    }

    logger.info("Pending migrations", { count: pending.length, files: pending });

    const client = await getPool().connect();
    try {
      for (const file of pending) {
        const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), "utf-8");
        await runMigration(client, file, sql);
      }
    } finally {
      client.release();
    }

    logger.info("All migrations applied");
  } catch (err) {
    logger.error("Migration failed", {
      error: err instanceof Error ? err.message : String(err),
    });
    process.exit(1);
  } finally {
    await closePool();
  }
}

main();
