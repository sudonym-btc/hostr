#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

reset_relay() {
    echo "Resetting relay container and state..."

    # Stop and remove only the relay container.
    (cd "$REPO_ROOT" && docker-compose stop relay >/dev/null 2>&1 || true)
    (cd "$REPO_ROOT" && docker-compose rm -f relay >/dev/null 2>&1 || true)

    # Remove relay DB state.
    rm -rf "$REPO_ROOT/docker/data/relay"
    mkdir -p "$REPO_ROOT/docker/data/relay"

    # Start a fresh relay container.
    (cd "$REPO_ROOT" && docker-compose up -d relay)

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
    
    reset_relay

    (
        set -o pipefail
        cd "$REPO_ROOT/hostr_sdk" && \
        dart run bin/seed.dart "${extra_args[@]}" 2>&1 | tee "$log_file"
    )
}

# If script is run directly (not sourced), execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    seed_relay "$@"
fi
