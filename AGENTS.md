# optcg-db — Shared Database Layer

Shared npm package (`optcg-db`) consumed by both `optcg-api` and `optcg-data`. Owns the schema, migrations, connection pool, and TypeScript type definitions.

## Tech Stack
- **Runtime:** Node 20, TypeScript 5, ESM
- **Database:** PostgreSQL via `pg` (no ORM)
- **Published as:** `optcg-db` on npm (v0.4.0)
- **Exports:** `optcg-db/db/client.js` (pool + query), `optcg-db/db/schema.js` (types + constants)

## Project Structure
```
src/
├── db/
│   ├── client.ts          # pg Pool singleton, query(), closePool()
│   ├── schema.ts          # TypeScript interfaces for all tables + constants
│   ├── migrate.ts         # Migration runner
│   └── migrations/
│       └── 001_initial_schema.sql
└── shared/
    └── logger.ts
```

## Environment Variables
```
DB_HOST=       # required
DB_USER=       # required
DB_PASSWORD=   # required
DB_PORT=5432   # optional, defaults to 5432
DB_NAME=optcg  # optional, defaults to "optcg"
DB_SSL=true    # optional, defaults to true
```

## Key Patterns

### Database Client
- `query<T>(sql, params?)` — parameterized queries, returns `pg.QueryResult<T>`
- `getPool()` — lazy singleton, created on first call
- `closePool()` — graceful shutdown
- Pool: max 10 connections, 30s idle timeout, 5s connect timeout

### Schema Types
Pure TypeScript interfaces matching Postgres tables. No runtime validation — these are row shapes for `query<T>()` generics.

Key types: `Product`, `Card`, `CardImage`, `CardSource`, `DonCard`, `Format`, `FormatLegalBlock`, `FormatBan`, `TcgplayerProduct`, `TcgplayerPrice`, `ScrapeLog`

Union types: `Language` (`en|ja|fr|zh`), `CardType`, `Rarity`, `Color`, `Attribute`, `DonFinish`, `ProductType`

### Constants
- `TCGPLAYER_LABEL_MAP` — maps TCGPlayer name suffixes (e.g. `"(Pirate Foil)"`) to our `card_images.label` values (e.g. `"Jolly Roger Foil"`)
- `TCGPLAYER_GOLD_SP_SUFFIXES` — suffixes that indicate gold SP variant

## Database Schema (key tables)

### cards
Primary card data. One row per `(card_number, language)`. Fields: card_number, language, product_id, true_set_code, name, card_type, rarity, color[], cost, power, counter, life, attribute[], types[], effect, trigger, block.

### card_images
Card art variants. One row per `(card_id, variant_index)`. Fields: image_url, scan_url, source_url, label (e.g. "Alternate Art", "Manga Art"), artist, artist_ocr, classified, product_id.

### card_sources
Junction table tracking which products a card appeared in. One row per `(card_id, product_id)`.

### products
Scraped products (Bandai dropdown values). Unique on `(name, language)`. Fields: language, name, source, set_codes[], tcgplayer_group_id, released_at.

### formats / format_legal_blocks / format_bans
- `formats`: Standard, Extra Regulation. Has `has_rotation` flag.
- `format_legal_blocks`: Which blocks are legal in each format. `(format_id, block)` unique.
- `format_bans`: Card bans. `ban_type` is `'banned'`, `'restricted'`, or `'pair'`. Restricted cards have `max_copies`. Pair bans have `paired_card_number` (stored bidirectionally — two rows per pair). Unique index on `(format_id, card_number, COALESCE(paired_card_number, ''))`.

### tcgplayer_products / tcgplayer_prices
Price data from TCGPlayer. `tcgplayer_products.card_image_id` links to our card_images. Prices stored in `tcgplayer_prices` with low/mid/high/market/direct_low.

### watched_topics
Event-driven scraping tracker. Stores Bandai topics page articles we've seen. Unique on `(language, url)`.

## Build & Publish
```bash
npm run build    # tsc → dist/
npm publish      # publishes to npm as optcg-db
```

After publishing, consumers (`optcg-api`, `optcg-data`) need `npm update optcg-db`.
