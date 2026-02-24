#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-local}"

case "$ENVIRONMENT" in
    local|test|staging|prod) ;;
    *)
        echo "Usage: $0 [local|test|staging|prod]"
        exit 64
        ;;
esac

restart_hostr() {
    (cd "$REPO_ROOT/dependencies/boltz-regtest" && ./stop.sh) || true
    (cd "$REPO_ROOT" && docker compose down --volumes) || true

    rm -rf \
        "$REPO_ROOT/docker/data/lightning_data" \
        "$REPO_ROOT/docker/data/bitcoin" \
        "$REPO_ROOT/docker/data/lnbits" \
        "$REPO_ROOT/docker/data/albyhub" \
        "$REPO_ROOT/docker/data/relay" \
        "$REPO_ROOT/docker/data/blossom" \
        "$REPO_ROOT/docker/data/escrow" \
        "$REPO_ROOT/docker/tls/ca/ca.crt" \
        "$REPO_ROOT/docker/tls/ca/ca.key" \
        "$REPO_ROOT/docker/tls/ca/ca.srl" \
        "$REPO_ROOT/docker/tls/ca/ca-bundle.crt" \
        "$REPO_ROOT/docker/certs"/*.crt \
        "$REPO_ROOT/docker/certs"/*.key \
        "$REPO_ROOT/escrow/contracts/ignition/deployments/chain-33" \
        "$REPO_ROOT/escrow/contracts/ignition/deployments/chain-31337" \
        "$REPO_ROOT/escrow/contracts/ignition/deployments"

    mkdir -p \
        "$REPO_ROOT/docker/data/lightning_data/1" \
        "$REPO_ROOT/docker/data/lightning_data/2" \
        "$REPO_ROOT/docker/data/bitcoin" \
        "$REPO_ROOT/docker/data/lnbits/1" \
        "$REPO_ROOT/docker/data/lnbits/2" \
        "$REPO_ROOT/docker/data/albyhub" \
        "$REPO_ROOT/docker/data/relay" \
        "$REPO_ROOT/docker/data/blossom" \
        "$REPO_ROOT/docker/data/escrow"

    # nostr-rs-relay runs as a non-root user in its container and needs write
    # access to the mounted sqlite path.
    chmod 0777 "$REPO_ROOT/docker/data/relay"

    (cd "$REPO_ROOT/dependencies/boltz-regtest" && git clean -fdx data/) || true

    "$SCRIPT_DIR/start.sh" "$ENVIRONMENT"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    restart_hostr "$@"
fi
