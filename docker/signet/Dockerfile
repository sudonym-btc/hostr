# syntax=docker/dockerfile:1.20
ARG NODE_IMAGE=node:24.21.0-bookworm-slim@sha256:2fe369e969550cde8e867afc3fe370b260140cab4a23d467074295b42163d553
FROM ${NODE_IMAGE} AS build
WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && npm install --global pnpm@12.4.2

# Signet source and lockfile come from the one revision pinned by Compose.
# Hostr owns the current package-manager configuration for these two images.
COPY --from=signet-source /package.json /pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./
RUN node --input-type=module -e 'import fs from "node:fs"; const p = JSON.parse(fs.readFileSync("package.json", "utf8")); delete p.packageManager; delete p.pnpm; fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");'
COPY --from=signet-source /packages/signet-types ./packages/signet-types
COPY --from=signet-source /apps/signet/package.json ./apps/signet/
COPY --from=signet-source /apps/signet-ui/package.json ./apps/signet-ui/
ENV CI=true
RUN --mount=type=cache,id=hostr-signet-pnpm12,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile
COPY --from=signet-source /apps/signet ./apps/signet
COPY --from=signet-source /apps/signet-ui ./apps/signet-ui
ENV DATABASE_URL=file:/app/config/signet.db
RUN pnpm --filter signet build && pnpm --filter signet-ui build

FROM ${NODE_IMAGE} AS runtime
WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=build /app/packages/signet-types ./packages/signet-types

FROM runtime AS signet
COPY --from=build /app/apps/signet/node_modules ./apps/signet/node_modules
COPY --from=build /app/apps/signet/package.json ./apps/signet/
COPY --from=build /app/apps/signet/dist ./apps/signet/dist
COPY --from=build /app/apps/signet/prisma ./apps/signet/prisma
COPY --from=build /app/apps/signet/prisma.config.ts ./apps/signet/prisma.config.ts
COPY --from=build /app/apps/signet/entrypoint.sh ./apps/signet/entrypoint.sh
WORKDIR /app/apps/signet
RUN chmod +x entrypoint.sh
ENV DATABASE_URL=file:/app/config/signet.db SIGNET_PORT=3000 SIGNET_HOST=0.0.0.0
EXPOSE 3000
ENTRYPOINT ["./entrypoint.sh"]
CMD ["start", "--config", "/app/config/signet.json"]

FROM runtime AS signet-ui
COPY --from=build /app/apps/signet-ui/node_modules ./apps/signet-ui/node_modules
COPY --from=build /app/apps/signet-ui/package.json ./apps/signet-ui/
COPY --from=build /app/apps/signet-ui/dist ./apps/signet-ui/dist
COPY --from=build /app/apps/signet-ui/server.mjs ./apps/signet-ui/server.mjs
WORKDIR /app/apps/signet-ui
ENV UI_PORT=4174 UI_HOST=0.0.0.0 DAEMON_URL=http://signet:3000
EXPOSE 4174
CMD ["node", "server.mjs"]
