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
    mkdir -p ./docker/data/lightning_data ./docker/data/relay ./docker/data/bitcoin ./docker/data/blossom ./docker/data/lnbits/{1,2} ./docker/data/albyhub &&
        docker-compose up -d && 
        wait_for_healthy && 
        start_boltz &&
        wait_for_healthy &&
        setup_ln &&
        setup_boltz &&
        setup_lnbits "$LNBITS_1_PORT" jeremy &&
        setup_lnbits "$LNBITS_2_PORT" jasmine &&
        setup_albyhub https://alby1.hostr.development test "$ALBYHUB_PASSWORD" &&
        setup_albyhub https://alby2.hostr.development test "$ALBYHUB_PASSWORD" &&
        CONTRACT_ADDR=$(setup_evm) &&
        seed_relay
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start "$@"
fi
