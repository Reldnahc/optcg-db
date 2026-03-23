# optcg-db — Implementation Progress

Scoped progress tracker for the `optcg-db` package (published to npm).
Full project spec: `../optcg-scryfall-spec.md`

---

## What Exists (verified 2026-03-22)

### Infrastructure / Config
- [x] `package.json` — ESM, Node 20, deps: pg, dotenv. Published to npm as `optcg-db`. Exports `db/client.js` and `db/schema.js`.
- [x] `tsconfig.json` — strict, ES2022, Node16 module, declaration + declarationMap for consumers
- [x] `.gitignore`
- [x] TypeScript compiles cleanly (`tsc --noEmit` passes)

### Database Layer (`src/db/`)
- [x] `client.ts` — pg Pool with `DbConfig` interface, `dbConfigFromEnv()` loads only DB_* vars, exports `getPool()`, `query()`, `closePool()`
- [x] `schema.ts` — TypeScript interfaces for all 10 tables + enums (Language, CardType, Rarity, Color, Attribute, DonFinish, ProductType) + `TCGPLAYER_LABEL_MAP` (includes "Reprint" label)
- [x] `migrate.ts` — reads `migrations/` dir, tracks applied in `_migrations` table, runs each in a transaction using a dedicated PoolClient
- [x] `migrations/001_initial_schema.sql`:
  - 10 tables: products, cards, card_images, card_sources, don_cards, formats, format_legal_blocks, format_bans, tcgplayer_products, tcgplayer_prices, scrape_log
  - All indexes (B-tree + GIN for arrays)
  - Seed data: Standard + Extra Regulation formats

### Shared Utilities (`src/shared/`)
- [x] `logger.ts` — structured JSON to stdout/stderr, `{ timestamp, level, message, ...data }`

---

## What's Next (priority order)

1. Full-text search migration
2. Publish to npm (pending `npm adduser` login)
