FROM node:20-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src/ src/
RUN npm run build

FROM node:20-bookworm-slim AS runtime
WORKDIR /app
COPY package.json package-lock.json ./
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl postgresql-client \
 && rm -rf /var/lib/apt/lists/* \
 && npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY src/db/migrations ./dist/db/migrations

ENTRYPOINT ["node"]
CMD ["dist/db/migrate.js"]
