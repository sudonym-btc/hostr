FROM node:22-bookworm-slim AS deps

WORKDIR /app
COPY ai/mcp-server/package*.json ./
RUN npm ci

FROM deps AS build

COPY ai/mcp-server/tsconfig.json ./
COPY ai/mcp-server/src ./src
RUN npm run build
RUN npm prune --omit=dev

FROM dart:stable AS daemon-build

ENV PUB_CACHE=/workspace/.pub-cache
ENV PATH=/root/.cargo/bin:/usr/lib/dart/bin:$PATH
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential ca-certificates clang cmake curl git pkg-config \
  && rm -rf /var/lib/apt/lists/* \
  && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain 1.90.0
WORKDIR /workspace
COPY models ./models
COPY hostr_sdk ./hostr_sdk
COPY hostr_cli ./hostr_cli
WORKDIR /workspace/hostr_cli
RUN dart pub get
RUN dart build cli -t bin/hostr_daemon.dart -o /out

FROM node:22-bookworm-slim AS runtime

ARG VCS_REF=unknown
ARG BUILD_DATE=unknown
ARG IMAGE_SOURCE=https://github.com/hostr-network/hostr

LABEL org.opencontainers.image.title="Hostr MCP Server" \
      org.opencontainers.image.description="Hostr Model Context Protocol server" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates libsqlite3-0 \
  && mkdir -p /data/mcp \
  && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production \
    PORT=8787 \
    HOSTR_DAEMON_COMMAND=/opt/hostr-daemon/bin/hostr_daemon \
    HOSTR_DAEMON_CWD=/opt/hostr-daemon \
    HOSTR_DAEMON_STATE_DIR=/data/mcp \
    HOSTR_IMAGE_REVISION=${VCS_REF} \
    HOSTR_IMAGE_CREATED=${BUILD_DATE} \
    HOSTR_IMAGE_SOURCE=${IMAGE_SOURCE}

WORKDIR /app
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=daemon-build /out/bundle /opt/hostr-daemon
COPY --from=daemon-build /workspace/models/native /opt/hostr-daemon/native

EXPOSE 8787
CMD ["node", "dist/index.js"]
