#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/hostr-common.sh"
ENVIRONMENT="${HOSTR_ENVIRONMENT:-local}"
ENV_FILE="$REPO_ROOT/.env.$ENVIRONMENT"

# Helper: run docker compose with the correct -f flags for the environment.
_compose() {
    (cd "$REPO_ROOT" && hostr_compose_cmd "$ENVIRONMENT" "$@")
}

wait_for_oneshot_service() {
    local service_name="$1"
    local cid

    cid="$(_compose ps -aq "$service_name" 2>/dev/null | head -n 1 || true)"
    if [ -z "$cid" ]; then
        return 0
    fi

    docker wait "$cid" >/dev/null 2>&1 || true
    local exit_code
    exit_code="$(docker inspect "$cid" --format '{{.State.ExitCode}}')"
    if [ "$exit_code" -ne 0 ]; then
        echo "$service_name failed with exit code: $exit_code"
        return "$exit_code"
    fi
}

wait_for_arbitrum_tokens() {
    if [ "$ENVIRONMENT" != "local" ] && [ "$ENVIRONMENT" != "test" ]; then
        return 0
    fi

    wait_for_oneshot_service arbitrum-init

    local rpc_url="${ARBITRUM_RPC:-http://127.0.0.1:8546}"
    local tbtc="${EVM_CHAIN_ARBITRUM_REGTEST_TBTC_ADDRESS:-}"
    local usdt="${EVM_CHAIN_ARBITRUM_REGTEST_USDT_ADDRESS:-}"
    local attempts=0
    local max_attempts=120

    if [ -z "$tbtc" ] || [ -z "$usdt" ]; then
        return 0
    fi

    echo "Waiting for Arbitrum token contracts to exist on-chain..."
    while true; do
        local tbtc_code=""
        local usdt_code=""
        tbtc_code="$(cast code "$tbtc" --rpc-url "$rpc_url" 2>/dev/null || true)"
        usdt_code="$(cast code "$usdt" --rpc-url "$rpc_url" 2>/dev/null || true)"
        if [ -n "$tbtc_code" ] && [ "$tbtc_code" != "0x" ] && \
           [ -n "$usdt_code" ] && [ "$usdt_code" != "0x" ]; then
            echo "Arbitrum token contracts ready (${attempts}s)."
            return 0
        fi

        attempts=$((attempts + 1))
        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "Timed out waiting for token contracts at $tbtc / $usdt"
            return 1
        fi
        sleep 1
    done
}

wait_for_signet_bunker() {
    local bunker_url="${SEED_SIGNET_BUNKER_URL:-}"
    if [ -z "$bunker_url" ]; then
        return 0
    fi

    echo "Waiting for Signet bunker to become ready..."
    local attempts=0
    local max_attempts=60
    while ! curl -sf -o /dev/null --max-time 2 "$bunker_url/health" --insecure 2>/dev/null; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "Timed out waiting for Signet bunker at $bunker_url"
            return 1
        fi
        sleep 1
    done
    echo "Signet bunker ready (${attempts}s)."
}

stop_relay_authz_for_seed() {
    echo "Temporarily stopping relay-authz so seed writes use relay fail-open admission..."
    _compose stop relay-authz >/dev/null 2>&1 || true
}

restore_relay_authz_after_seed() {
    local status=$?
    echo "Restoring relay-authz..."
    if ! _compose up -d relay-authz >/dev/null 2>&1; then
        echo "Warning: failed to restart relay-authz. Restart it manually before accepting untrusted writes." >&2
    fi
    return "$status"
}

reset_relay() {
    echo "Resetting relay container and state..."

    # Stop and remove only the relay container.
    _compose stop relay >/dev/null 2>&1 || true
    _compose rm -f relay >/dev/null 2>&1 || true

    # Remove relay DB state.
    rm -rf "$REPO_ROOT/docker/data/relay"
    mkdir -p "$REPO_ROOT/docker/data/relay"

    # Start a fresh relay container without starting relay-authz. The seed
    # script deliberately relies on nostr-rs-relay's fail-open behavior when
    # the configured gRPC admission service is unavailable.
    _compose up -d --no-deps relay

    # Wait until the relay is actually accepting connections.
    echo "Waiting for relay to become ready..."
    local attempts=0
    local max_attempts=30
    while ! curl -sf -o /dev/null --max-time 2 https://relay.hostr.development --insecure 2>/dev/null; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "Warning: relay did not become ready after ${max_attempts}s, proceeding anyway."
            break
        fi
        sleep 1
    done
    echo "Relay ready (${attempts}s)."
}

# Seed the relay with mock data
seed_relay() {
    for arg in "$@"; do
        if [[ "$arg" != --* ]]; then
            echo "Error: positional args are not supported. Put relayUrl in --config-json/--config-file."
            return 64
        fi
    done

    local extra_args=("$@")
    local log_dir="$REPO_ROOT/logs"
    local log_file="$log_dir/seed_relay_$(date +%Y%m%d_%H%M%S).log"

    mkdir -p "$log_dir"
    echo "Writing seed logs to: $log_file"

    if [ ! -f "$ENV_FILE" ]; then
        echo "Missing env file: $ENV_FILE"
        return 66
    fi

    "$SCRIPT_DIR/sync-contract-env.sh" "$ENVIRONMENT" >/dev/null 2>&1 || true
    set -a
    if { [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; } && [ -f "$REPO_ROOT/dependencies/boltz-regtest/.env" ]; then
        source "$REPO_ROOT/dependencies/boltz-regtest/.env"
    fi
    source "$REPO_ROOT/.env"
    source "$ENV_FILE"
    set +a

    if { [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; } && [ -z "${SEED_TRADE_SPONSOR_PRIVATE_KEY:-}" ]; then
        # Anvil account #4: reserved for seeding trade transactions so generated
        # users do not need native ETH just to pay gas.
        export SEED_TRADE_SPONSOR_PRIVATE_KEY="0x47e179ec197488bf6f2a5af2f4f01a49510f4f62b6bdcb2e9495d5c83e8d4d3d"
    fi

    if { [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; } && [ -z "${SEED_SIGNET_BUNKER_URL:-}" ]; then
        export SEED_SIGNET_BUNKER_URL="https://bunker-nostr.hostr.development"
    fi
    
    (
        trap restore_relay_authz_after_seed EXIT
        stop_relay_authz_for_seed
        reset_relay
        wait_for_arbitrum_tokens
        wait_for_signet_bunker

        set -o pipefail
        cd "$REPO_ROOT/hostr_sdk"
        if [ "${#extra_args[@]}" -gt 0 ]; then
            dart run bin/seed.dart "${extra_args[@]}" 2>&1 | tee "$log_file"
        else
            dart run bin/seed.dart 2>&1 | tee "$log_file"
        fi
    )
    # NIP-05 domain IDs are fixed by the lnbits-init Docker service at startup.
    # No post-seed fixup needed.
}

# If script is run directly (not sourced), execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    seed_relay "$@"
fi
