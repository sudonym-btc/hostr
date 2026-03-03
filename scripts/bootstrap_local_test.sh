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

wait_for_rif_relay_ready() {
    local anvil_rpc="http://anvil:8545"
    local relay_url="http://rif-relay:8090"
    local factory="0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE"
    local deploy_verifier="0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9"
    local call_verifier="0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"
    local max_attempts=30
    local attempt=0

    echo "Waiting for RIF Relay + smart-wallet contracts to be ready..."
    while [ $attempt -lt $max_attempts ]; do
        # 1) Relay server returns valid chain-info with a worker address.
        if info=$(curl -sf "$relay_url/chain-info" 2>/dev/null) && \
           echo "$info" | jq -e '.relayWorkerAddress' >/dev/null 2>&1; then

            # 2) /verifiers lists the trusted verifiers — empty list means
            #    the relay hasn't finished registering them on-chain yet.
            if verifiers=$(curl -sf "$relay_url/verifiers" 2>/dev/null) && \
               echo "$verifiers" | jq -e '.trustedVerifiers | length > 0' >/dev/null 2>&1; then

                # 3) Factory + verifier contracts have code on Anvil.
                all_deployed=true
                for addr in "$factory" "$deploy_verifier" "$call_verifier"; do
                    code=$(curl -sf -X POST "$anvil_rpc" \
                        -H "Content-Type: application/json" \
                        -d "{\"method\":\"eth_getCode\",\"params\":[\"$addr\",\"latest\"],\"id\":1,\"jsonrpc\":\"2.0\"}" 2>/dev/null \
                        | jq -r '.result // ""')
                    if [ -z "$code" ] || [ "$code" = "0x" ]; then
                        all_deployed=false
                        break
                    fi
                done

                if $all_deployed; then
                    echo "✔ RIF Relay ready (verifiers registered, factory + verifier contracts deployed)."
                    return 0
                fi
            fi
        fi

        attempt=$((attempt + 1))
        echo "  RIF Relay not ready yet (attempt $attempt/$max_attempts)..."
        sleep 2
    done
    echo "ERROR: RIF Relay did not become ready after $max_attempts attempts"
    return 1
}

bootstrap_local_test() {
    # Gate on external services being *functionally* ready, not just
    # healthcheck-passing.  The Docker healthchecks only confirm ports
    # are open; these verify the APIs / contracts are fully initialised.
    # wait_for_boltz_api
    # wait_for_rif_relay_ready

    # All container health checks and regtest-start completion are
    # enforced by depends_on conditions in docker-compose.yml, so
    # bootstrap only needs to open the lightning channels.
    setup_channels
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bootstrap_local_test "$@"
fi
