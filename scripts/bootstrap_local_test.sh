#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/setup_channels.sh"

bootstrap_local_test() {
    # All container health checks and regtest-start completion are
    # enforced by depends_on conditions in docker-compose.yml, so
    # bootstrap only needs to open the lightning channels.
    setup_channels
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bootstrap_local_test "$@"
fi
