FROM node:22

WORKDIR /

COPY dependencies/rif-relay-contracts /rif-relay-contracts
COPY dependencies/rif-relay-server /rif-relay-server
COPY docker/rif-relay/contracts.patch /tmp/contracts.patch
COPY docker/rif-relay/server.patch /tmp/server.patch
COPY docker/rif-relay/start.sh /start.sh

RUN apt-get update \
    && apt-get install -y --no-install-recommends git patch \
    && rm -rf /var/lib/apt/lists/*

RUN cd /rif-relay-contracts \
    && patch -p1 < /tmp/contracts.patch \
    && npm ci

RUN cd /rif-relay-server \
    && patch -p1 < /tmp/server.patch \
    && npm ci

ENTRYPOINT ["/bin/bash", "/start.sh"]
