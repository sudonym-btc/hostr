#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/hostr-common.sh"
ENVIRONMENT="${1:-local}"
RIF_RELAY_MODE="${2:-regtest-fast}"

hostr_validate_environment "$ENVIRONMENT" "$0"
hostr_validate_rif_relay_mode "$RIF_RELAY_MODE" "$0"
hostr_require_env_file "$REPO_ROOT" "$ENVIRONMENT"

restart_hostr() {
    (hostr_load_env "$REPO_ROOT" "$ENVIRONMENT"; cd "$REPO_ROOT" && hostr_compose_cmd "$ENVIRONMENT" down --volumes --remove-orphans) || true

    rm -rf \
        "$REPO_ROOT/docker/data/lightning_data" \
        "$REPO_ROOT/docker/data/bitcoin" \
        "$REPO_ROOT/docker/data/lnbits" \
        "$REPO_ROOT/docker/data/albyhub" \
        "$REPO_ROOT/docker/data/relay" \
        "$REPO_ROOT/docker/data/blossom" \
        "$REPO_ROOT/docker/data/escrow" \
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


    # Rebuild local-source images so restarts always pick up workspace
    # changes. Only local needs the web app image.
    if [ "$ENVIRONMENT" = "local" ]; then
        (hostr_load_env "$REPO_ROOT" "$ENVIRONMENT"; cd "$REPO_ROOT" && \
            hostr_compose_cmd "$ENVIRONMENT" build app escrow-contract-deploy rif-relay)
    elif [ "$ENVIRONMENT" = "test" ]; then
        (hostr_load_env "$REPO_ROOT" "$ENVIRONMENT"; cd "$REPO_ROOT" && \
            hostr_compose_cmd "$ENVIRONMENT" build escrow-contract-deploy rif-relay)
    fi
    
    "$SCRIPT_DIR/start.sh" "$ENVIRONMENT" "$RIF_RELAY_MODE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    restart_hostr "$@"
fi
