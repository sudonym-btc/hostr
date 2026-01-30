#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

stop_hostr() {
    (cd "$SCRIPT_DIR/../dependencies/boltz-regtest" && ./stop.sh) && docker-compose down --volumes
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    stop_hostr "$@"
fi
