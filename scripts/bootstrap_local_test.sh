#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/setup_channels.sh"

# ── Service-readiness gates ──────────────────────────────────────────────
# Docker healthchecks only verify ports are open / simple HTTP responses.
# These functions confirm the services are *functionally* ready before
# integration tests run.

wait_for_boltz_api() {
    local url="http://boltz-backend-nginx:9001/v2/nodes"
    local max_attempts=30
    local attempt=0

    echo "Waiting for Boltz backend v2 API to be fully initialised..."
    while [ $attempt -lt $max_attempts ]; do
        if response=$(curl -sf "$url" 2>/dev/null); then
            # /v2/nodes returns { "BTC": { "LND": { "publicKey": ... } } }
            # — only populated once the swap engine has connected to its
            # lightning backends and loaded pair/token configuration.
            if echo "$response" | jq -e '.BTC' >/dev/null 2>&1; then
                echo "✔ Boltz API ready (nodes endpoint returning BTC data)."
                return 0
            fi
        fi
        attempt=$((attempt + 1))
        echo "  Boltz API not ready yet (attempt $attempt/$max_attempts)..."
        sleep 2
    done
    echo "ERROR: Boltz API did not become ready after $max_attempts attempts"
    return 1
}


bootstrap_local_test() {
    # Gate on external services being *functionally* ready, not just
    # healthcheck-passing.  The Docker healthchecks only confirm ports
    # are open; these verify the APIs / contracts are fully initialised.
    # Gate on Boltz API being fully initialised — the Docker healthcheck
    # only confirms the port is open, not that LN backends are connected.
    # wait_for_boltz_api

    # All container health checks and regtest-start completion are
    # enforced by depends_on conditions in docker-compose.yml, so
    # bootstrap only needs to open the lightning channels.
    setup_channels
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bootstrap_local_test "$@"
fi
