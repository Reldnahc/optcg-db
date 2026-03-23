/**
 * Database connection pool using pg.
 * Shared by the scraper, price fetcher, and CLI.
 */

import "dotenv/config";
import pg from "pg";
import { logger } from "../shared/logger.js";

const { Pool } = pg;

let pool: pg.Pool | null = null;

export interface DbConfig {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
  ssl: boolean;
}

/**
 * Build DB config from environment variables.
 * Only requires the DB_* vars — no S3/Discord/ECS needed.
 */
function dbConfigFromEnv(): DbConfig {
  const host = process.env.DB_HOST;
  const user = process.env.DB_USER;
  const password = process.env.DB_PASSWORD;
  if (!host || !user || !password) {
    throw new Error("Missing required DB env vars: DB_HOST, DB_USER, DB_PASSWORD");
  }
  return {
    host,
    port: parseInt(process.env.DB_PORT ?? "5432", 10),
    user,
    password,
    database: process.env.DB_NAME ?? "optcg",
    ssl: (process.env.DB_SSL ?? "true") === "true",
  };
}

export function getPool(config?: DbConfig): pg.Pool {
  if (!pool) {
    const c = config ?? dbConfigFromEnv();
    pool = new Pool({
      host: c.host,
      port: c.port,
      user: c.user,
      password: c.password,
      database: c.database,
      ssl: c.ssl ? { rejectUnauthorized: false } : false,
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });

    pool.on("error", (err) => {
      logger.error("Unexpected pool error", { error: err.message });
    });
  }
  return pool;
}

export async function query<T extends pg.QueryResultRow = pg.QueryResultRow>(
  text: string,
  params?: unknown[]
): Promise<pg.QueryResult<T>> {
  const p = getPool();
  return p.query<T>(text, params);
}

export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
    logger.info("Database pool closed");
  }
}
