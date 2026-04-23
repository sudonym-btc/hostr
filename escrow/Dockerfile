# ── Build ─────────────────────────────────────────────────────────────
FROM dart:stable AS build

WORKDIR /workspace

COPY escrow /workspace/escrow
COPY hostr_sdk /workspace/hostr_sdk
COPY models /workspace/models

WORKDIR /workspace/escrow

RUN dart pub get

# ── Development target (local docker compose) ────────────────────────
FROM build AS dev

ARG COMMIT_SHA=dev
ARG BUILD_DATE=
ENV COMMIT_SHA=$COMMIT_SHA \
    BUILD_DATE=$BUILD_DATE \
    PATH="/root/.cargo/bin:${PATH}" \
    RUSTUP_TOOLCHAIN="1.90.0-aarch64-unknown-linux-gnu"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl build-essential pkg-config libssl-dev libsecp256k1-2 \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal \
    && rustup toolchain install 1.90.0-aarch64-unknown-linux-gnu \
    && rustup default 1.90.0-aarch64-unknown-linux-gnu \
    && ln -sf "$(find /usr/lib -name 'libsecp256k1.so.2' -print -quit)" /usr/lib/libsecp256k1.so \
    && rm -rf /var/lib/apt/lists/*

RUN dart build cli --target bin/daemon.dart -o /out/daemon \
    && cp /out/daemon/bundle/bin/daemon /usr/local/bin/daemon \
    && cp -r /out/daemon/bundle/lib/* /usr/local/lib/

RUN chmod +x docker/entrypoint.sh docker/escrow-cli.sh \
    && install -m 0755 docker/escrow-cli.sh /usr/local/bin/escrow-cli \
    && printf '%s\n' "alias escrow-cli='dart run /workspace/escrow/bin/cli.dart'" > /etc/profile.d/escrow-cli.sh

ENTRYPOINT ["docker/entrypoint.sh"]

# ── AOT compile ──────────────────────────────────────────────────────
FROM build AS compile

RUN dart build cli --target bin/daemon.dart -o /out/daemon \
    && dart build cli --target bin/cli.dart -o /out/cli

# ── Production runtime ───────────────────────────────────────────────
FROM debian:12-slim AS production

ARG COMMIT_SHA=dev
ARG BUILD_DATE=
ENV COMMIT_SHA=$COMMIT_SHA \
    BUILD_DATE=$BUILD_DATE

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libsecp256k1-1 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf "$(find /usr/lib -name 'libsecp256k1.so.1' -print -quit)" /usr/lib/libsecp256k1.so

COPY --from=compile /out/daemon/bundle/bin/ /usr/local/bin/
COPY --from=compile /out/daemon/bundle/lib/ /usr/local/lib/
COPY --from=compile /out/cli/bundle/bin/cli /usr/local/bin/escrow-cli
COPY --from=compile /out/cli/bundle/lib/ /usr/local/lib/

ENTRYPOINT ["daemon"]

# ── VHS terminal recording ───────────────────────────────────────────
# Combines the AOT-compiled CLI with Charm's VHS image for generating
# terminal GIFs and screenshots.
#
#   docker build --target vhs -f escrow/Dockerfile -t escrow-vhs .
#   docker run --rm \
#     -v $PWD/escrow:/vhs \
#     -v $TMPDIR/escrow_daemon.sock:/tmp/escrow_daemon.sock \
#     -e ESCROW_SOCKET=/tmp/escrow_daemon.sock \
#     escrow-vhs demo.tape
#
FROM ghcr.io/charmbracelet/vhs AS vhs

RUN apt-get update \
    && apt-get install -y --no-install-recommends libsecp256k1-2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=compile /out/cli/bundle/bin/cli /usr/local/bin/escrow-cli
COPY --from=compile /out/cli/bundle/lib/ /usr/local/lib/
