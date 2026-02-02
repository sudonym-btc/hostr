#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/stop.sh"
source "$SCRIPT_DIR/start.sh"

restart_hostr() {
    stop_hostr &&
        rm -rf docker/data &&
        rm -rf escrow/contracts/ignition/deployments &&
        (cd "$SCRIPT_DIR/../dependencies/boltz-regtest" && git clean -fdx data/) &&
        start
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    restart_hostr "$@"
fi
