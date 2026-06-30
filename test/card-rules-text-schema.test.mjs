import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  CARD_RULES_TEXT_INGEST_STATUSES,
  CARD_RULES_TEXT_SOURCES,
} from "../dist/db/schema.js";

assert.deepEqual(CARD_RULES_TEXT_SOURCES, [
  "bandai",
  "manual",
  "spoiler_raw",
  "spoiler_llm",
]);

assert.deepEqual(CARD_RULES_TEXT_INGEST_STATUSES, [
  "raw_supported",
  "llm_supported",
  "unsupported",
]);

const migration = readFileSync(
  new URL("../src/db/migrations/056_spoiler_rules_text_sources.sql", import.meta.url),
  "utf8",
);

for (const source of CARD_RULES_TEXT_SOURCES) {
  assert.match(migration, new RegExp(`'${source}'`, "u"));
}

for (const status of CARD_RULES_TEXT_INGEST_STATUSES) {
  assert.match(migration, new RegExp(`'${status}'`, "u"));
}

assert.match(migration, /CREATE TABLE IF NOT EXISTS card_rules_text_ingest_attempts/u);
