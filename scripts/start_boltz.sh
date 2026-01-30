#!/bin/bash
source "$SCRIPT_DIR/wait_for_healthy.sh"

start_boltz() {

    (cd "$SCRIPT_DIR/../dependencies/boltz-regtest" && DOCKER_DEFAULT_PLATFORM=linux/amd64 COMPOSE_PROFILES=ci ./start.sh)
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_boltz "$@"
fi
