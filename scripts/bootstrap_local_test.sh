#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/wait_for_healthy.sh"
source "$SCRIPT_DIR/setup_ln.sh"
source "$SCRIPT_DIR/setup_boltz.sh"

wait_for_boltz_regtest_start() {
    local max_attempts=180
    local attempt=0

    echo "Waiting for boltz-regtest-start to complete successfully..."
    while [ $attempt -lt $max_attempts ]; do
        status=$(docker inspect -f '{{.State.Status}}' boltz-regtest-start 2>/dev/null || true)
        exit_code=$(docker inspect -f '{{.State.ExitCode}}' boltz-regtest-start 2>/dev/null || true)

        if [ "$status" = "exited" ] && [ "$exit_code" = "0" ]; then
            echo "boltz-regtest-start completed successfully"
            return 0
        fi

        attempt=$((attempt + 1))
        sleep 2
    done

    echo "Timed out waiting for boltz-regtest-start to complete"
    return 1
}

bootstrap_local_test() {
    wait_for_healthy
    wait_for_boltz_regtest_start

    setup_ln
    setup_boltz
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bootstrap_local_test "$@"
fi
