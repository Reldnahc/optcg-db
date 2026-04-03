/**
 * Seeds the card_dictionary table from the current web app's generated dictionary.
 * Run once after applying migration 018 to preserve existing deck hash indices.
 *
 * Usage: npx tsx src/db/seed-card-dictionary.ts
 */

import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { query, closePool, getPool } from "./client.js";
import { logger } from "../shared/logger.js";

const DICTIONARY_PATH = resolve(
  import.meta.dirname,
  "..",
  "..",
  "..",
  "optcg-web",
  "src",
  "decks",
  "cardDictionary.generated.ts",
);

function parseDictionary(filePath: string): string[] {
  const source = readFileSync(filePath, "utf8");
  const match = source.match(
    /export const CARD_DICTIONARY: string\[\] = (\[[\s\S]*?\]);/,
  );
  if (!match) {
    throw new Error("Could not parse CARD_DICTIONARY from source file");
  }
  const parsed: unknown = JSON.parse(match[1]);
  if (!Array.isArray(parsed)) {
    throw new Error("CARD_DICTIONARY is not an array");
  }
  return parsed.filter((value): value is string => typeof value === "string");
}

async function main() {
  const entries = parseDictionary(DICTIONARY_PATH);
  logger.info("Parsed card dictionary", { entries: entries.length, source: DICTIONARY_PATH });

  const existing = await query<{ count: string }>(
    "SELECT COUNT(*)::text AS count FROM card_dictionary",
  );
  const existingCount = parseInt(existing.rows[0]?.count ?? "0", 10);

  if (existingCount > 0) {
    logger.info("Card dictionary already seeded", { existing: existingCount });
    logger.info("To re-seed, TRUNCATE card_dictionary first");
    return;
  }

  const client = await getPool().connect();
  try {
    await client.query("BEGIN");

    // Batch insert in chunks of 500
    const CHUNK_SIZE = 500;
    for (let i = 0; i < entries.length; i += CHUNK_SIZE) {
      const chunk = entries.slice(i, i + CHUNK_SIZE);
      const values = chunk
        .map((cardNumber, j) => `($${j * 2 + 1}, $${j * 2 + 2})`)
        .join(", ");
      const params = chunk.flatMap((cardNumber, j) => [i + j, cardNumber]);

      await client.query(
        `INSERT INTO card_dictionary (index, card_number) VALUES ${values} ON CONFLICT DO NOTHING`,
        params,
      );
    }

    await client.query("COMMIT");
    logger.info("Seeded card dictionary", { entries: entries.length });
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

try {
  await main();
} catch (error) {
  logger.error("Seed failed", {
    error: error instanceof Error ? error.message : String(error),
  });
  process.exitCode = 1;
} finally {
  await closePool();
}
