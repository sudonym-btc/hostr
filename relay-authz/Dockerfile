FROM node:22-bookworm-slim

WORKDIR /app

COPY relay-authz/package*.json ./
RUN npm ci --omit=dev

COPY relay-authz/proto ./proto
COPY relay-authz/src ./src

ENV NODE_ENV=production \
    RELAY_AUTHZ_HOST=0.0.0.0 \
    RELAY_AUTHZ_PORT=50051 \
    RELAY_AUTHZ_REQUIRE_AUTHOR_MATCH=true \
    RELAY_AUTHZ_AUTHOR_MISMATCH_KINDS=1059,32122,1326 \
    RELAY_AUTHZ_PUBLIC_WRITE_KINDS=24133,13194,23194,23195,23196,23197

EXPOSE 50051
CMD ["node", "src/server.js"]
