#!/bin/bash

wait_for_healthy() {
    local max_attempts=60   # 60 × 5s = 300s = 5 minutes
    local attempt=0

    while [[ $(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}healthy{{end}}' $(docker ps -q) | grep -v healthy) ]]; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            echo "Timed out waiting for containers to be healthy after $((max_attempts * 5))s"
            docker ps --format 'table {{.Names}}\t{{.Status}}' || true
            return 1
        fi
        echo "Waiting for containers to be healthy (attempt $attempt/$max_attempts)..."
        sleep 5
    done
    if docker ps -a --format '{{.Names}}' | grep -q '^boltz-regtest-start$'; then
        local start_max=60   # 60 × 5s = 300s = 5 minutes
        local start_attempt=0
        while true; do
            status=$(docker inspect -f '{{.State.Status}}' boltz-regtest-start 2>/dev/null)
            exit_code=$(docker inspect -f '{{.State.ExitCode}}' boltz-regtest-start 2>/dev/null)
            if [[ "$status" == "exited" && "$exit_code" == "0" ]]; then
                echo "boltz-regtest-start completed successfully"
                break
            fi
            start_attempt=$((start_attempt + 1))
            if [ $start_attempt -ge $start_max ]; then
                echo "Timed out waiting for boltz-regtest-start after $((start_max * 5))s (status=$status, exit_code=$exit_code)"
                return 1
            fi
            echo "Waiting for boltz-regtest-start to complete (attempt $start_attempt/$start_max)..."
            sleep 5
        done
    fi
    echo "Containers are healthy"
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    wait_for_healthy "$@"
fi
