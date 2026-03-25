/**
 * Database connection pool using pg.
 * Shared by the scraper, price fetcher, and CLI.
 */

import "dotenv/config";
import pg from "pg";
import { logger } from "../shared/logger.js";

const { Pool } = pg;
const SLOW_QUERY_MS = 250;
const SQL_PREVIEW_LENGTH = 180;

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
      idleTimeoutMillis: 600000,
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
  const startedAt = process.hrtime.bigint();

  try {
    const result = await p.query<T>(text, params);
    logQueryTiming(text, params, result.rowCount, startedAt);
    return result;
  } catch (error) {
    logQueryTiming(text, params, null, startedAt, error);
    throw error;
  }
}

export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
    logger.info("Database pool closed");
  }
}

function logQueryTiming(
  text: string,
  params: unknown[] | undefined,
  rowCount: number | null,
  startedAt: bigint,
  error?: unknown,
) {
  const durationMs = Number(process.hrtime.bigint() - startedAt) / 1_000_000;
  const payload = {
    duration_ms: Number(durationMs.toFixed(1)),
    row_count: rowCount,
    param_count: params?.length ?? 0,
    sql: summarizeSql(text),
    ...(error instanceof Error ? { error: error.message } : {}),
  };

  if (error || durationMs >= SLOW_QUERY_MS) {
    logger.warn("Slow database query", payload);
    return;
  }

  logger.debug("Database query timing", payload);
}

function summarizeSql(text: string): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  if (normalized.length <= SQL_PREVIEW_LENGTH) return normalized;
  return normalized.slice(0, SQL_PREVIEW_LENGTH - 3) + "...";
}
