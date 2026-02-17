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

    # Small startup buffer before broadcast calls.
    sleep 2
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
    
    reset_relay

    (cd "$REPO_ROOT/hostr_sdk" && dart run bin/seed.dart "${extra_args[@]}")
}

# If script is run directly (not sourced), execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    seed_relay "$@"
fi
