#!/bin/bash

wait_for_healthy() {
    while [[ $(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}healthy{{end}}' $(docker ps -q) | grep -v healthy) ]]; do
        echo "Waiting for containers to be healthy..."
        sleep 5
    done
    if docker ps -a --format '{{.Names}}' | grep -q '^boltz-regtest-start$'; then
        while true; do
            status=$(docker inspect -f '{{.State.Status}}' boltz-regtest-start 2>/dev/null)
            exit_code=$(docker inspect -f '{{.State.ExitCode}}' boltz-regtest-start 2>/dev/null)
            if [[ "$status" == "exited" && "$exit_code" == "0" ]]; then
                echo "boltz-regtest-start completed successfully"
                break
            fi
            echo "Waiting for boltz-regtest-start to complete..."
            sleep 5
        done
    fi
    echo "Containers are healthy"
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    wait_for_healthy "$@"
fi
