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

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libsecp256k1-1 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf "$(find /usr/lib -name 'libsecp256k1.so.1' -print -quit)" /usr/lib/libsecp256k1.so

COPY --from=compile /out/daemon/bundle/bin/ /usr/local/bin/
COPY --from=compile /out/daemon/bundle/lib/ /usr/local/lib/
COPY --from=compile /out/cli/bundle/bin/cli /usr/local/bin/escrow-cli
COPY --from=compile /out/cli/bundle/lib/ /usr/local/lib/

ENTRYPOINT ["daemon"]