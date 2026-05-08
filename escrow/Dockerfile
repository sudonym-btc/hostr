# ── Toolchain base ────────────────────────────────────────────────────
FROM dart:stable AS dart-sdk

FROM rust:1.95.0-bookworm AS toolchain

ENV PATH="/usr/local/bin:/usr/lib/dart/bin:/usr/local/cargo/bin:${PATH}" \
    RUSTUP_TOOLCHAIN="1.95.0"

COPY --from=dart-sdk /usr/lib/dart /usr/lib/dart

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates pkg-config libssl-dev libsecp256k1-dev \
    && printf '%s\n' \
      '#!/bin/sh' \
      'set -e' \
      '' \
      'if [ "$1" = "show" ] && [ "$2" = "active-toolchain" ]; then' \
      '  printf '\''%s (default)\n'\'' "${RUSTUP_TOOLCHAIN:-1.95.0}"' \
      '  exit 0' \
      'fi' \
      '' \
      'if [ "$1" = "run" ] && [ "$#" -ge 4 ]; then' \
      '  toolchain="$2"' \
      '  shift 2' \
      '  if [ "$1" = "cargo" ]; then' \
      '    export RUSTUP_HOME="${RUSTUP_HOME:-/usr/local/rustup}"' \
      '    toolchain_dir="$(find "$RUSTUP_HOME/toolchains" -maxdepth 1 -type d -name "${RUSTUP_TOOLCHAIN:-${toolchain}}-*" -print -quit 2>/dev/null || true)"' \
      '    if [ -n "$toolchain_dir" ]; then' \
      '      toolchain_bin="$toolchain_dir/bin"' \
      '    else' \
      '      toolchain_bin="$(dirname "$(/usr/local/cargo/bin/rustup which cargo --toolchain "${RUSTUP_TOOLCHAIN:-${toolchain}}")")"' \
      '    fi' \
      '    export PATH="${toolchain_bin}:$PATH"' \
      '    shift 1' \
      '    exec "${toolchain_bin}/cargo" "$@"' \
      '  fi' \
      '  exec "$@"' \
      'fi' \
      '' \
      'exec /usr/local/cargo/bin/rustup "$@"' \
      >/usr/local/bin/rustup \
    && chmod +x /usr/local/bin/rustup \
    && ln -sf "$(find /usr/lib -name 'libsecp256k1.so.*' -print -quit)" /usr/lib/libsecp256k1.so \
    && rm -rf /var/lib/apt/lists/*

# ── Build ─────────────────────────────────────────────────────────────
FROM toolchain AS build

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
    BUILD_DATE=$BUILD_DATE

RUN chmod +x docker/entrypoint.sh

ENTRYPOINT ["docker/entrypoint.sh"]

# ── AOT compile ──────────────────────────────────────────────────────
FROM build AS compile

RUN dart build cli --target bin/daemon.dart -o /out/daemon

# ── Production runtime ───────────────────────────────────────────────
FROM debian:13-slim AS production

ARG COMMIT_SHA=dev
ARG BUILD_DATE=
ENV COMMIT_SHA=$COMMIT_SHA \
    BUILD_DATE=$BUILD_DATE

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libsecp256k1-2 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf "$(find /usr/lib -name 'libsecp256k1.so.*' -print -quit)" /usr/lib/libsecp256k1.so

COPY --from=compile /out/daemon/bundle/bin/ /usr/local/bin/
COPY --from=compile /out/daemon/bundle/lib/ /usr/local/lib/

ENTRYPOINT ["daemon"]
