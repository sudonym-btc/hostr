#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wait_for_healthy.sh"
source "$SCRIPT_DIR/setup_evm.sh"
source "$SCRIPT_DIR/seed_relay.sh"
source "$SCRIPT_DIR/setup_ln.sh"
source "$SCRIPT_DIR/start_boltz.sh"
source "$SCRIPT_DIR/setup_boltz.sh"

start() {
    # Create a shared network if it doesn't exist
    docker network inspect shared_network >/dev/null 2>&1 || docker network create shared_network

    # Ensure data directories exist
    mkdir -p ./docker/data/lightning_data ./docker/data/lightning_shared/{1,2} ./docker/data/relay ./docker/data/bitcoin ./docker/data/blossom ./docker/data/lnbits/{1,2} ./docker/data/albyhub &&
        docker-compose up -d && 
        wait_for_healthy && 
        start_boltz &&
        setup_ln && 
        setup_boltz &&
        CONTRACT_ADDR=$(setup_evm) &&
        seed_relay "$CONTRACT_ADDR"
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start "$@"
fi
