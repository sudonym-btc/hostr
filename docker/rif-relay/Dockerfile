# ── Build stage ───────────────────────────────────────────────────────
FROM node:22 AS builder

WORKDIR /

COPY dependencies/rif-relay-contracts /rif-relay-contracts
COPY dependencies/rif-relay-server /rif-relay-server
COPY docker/rif-relay/contracts.patch /tmp/contracts.patch
COPY docker/rif-relay/server.patch /tmp/server.patch

RUN apt-get update \
    && apt-get install -y --no-install-recommends git patch \
    && rm -rf /var/lib/apt/lists/*

RUN cd /rif-relay-contracts \
    && (patch -p1 --forward < /tmp/contracts.patch || true) \
    && npm install --no-audit \
    && npm cache clean --force \
    && rm -rf .git

RUN cd /rif-relay-server \
    && (patch -p1 --forward < /tmp/server.patch || true) \
    && npm ci \
    && npm cache clean --force \
    && rm -rf .git

# ── Runtime stage ─────────────────────────────────────────────────────
FROM node:22-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /rif-relay-contracts /rif-relay-contracts
COPY --from=builder /rif-relay-server /rif-relay-server
COPY docker/rif-relay/start.sh /start.sh
COPY docker/rif-relay/register.sh /register.sh
COPY docker/rif-relay/write_local_config.sh /write_local_config.sh

RUN chmod +x /start.sh /register.sh /write_local_config.sh

ENTRYPOINT ["/bin/bash", "/start.sh"]
