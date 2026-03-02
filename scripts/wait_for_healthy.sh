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
        local start_max=120  # 120 × 5s = 600s = 10 minutes
        local start_attempt=0
        while true; do
            status=$(docker inspect -f '{{.State.Status}}' boltz-regtest-start 2>/dev/null || echo "unknown")
            exit_code=$(docker inspect -f '{{.State.ExitCode}}' boltz-regtest-start 2>/dev/null || echo "-1")

            # Success
            if [[ "$status" == "exited" && "$exit_code" == "0" ]]; then
                echo "boltz-regtest-start completed successfully"
                break
            fi

            # Fail fast: container ran and exited with an error
            if [[ "$status" == "exited" && "$exit_code" != "0" ]]; then
                echo "boltz-regtest-start FAILED (exit code $exit_code)"
                docker logs boltz-regtest-start 2>&1 | tail -100 || true
                return 1
            fi

            # Fail fast: if still in 'created' state after 2 minutes,
            # check whether a key dependency (boltz-bitcoind) is crash-looping.
            if [[ "$status" == "created" && $start_attempt -ge 24 ]]; then
                btc_status=$(docker inspect -f '{{.State.Status}}' boltz-bitcoind 2>/dev/null || echo "unknown")
                if [[ "$btc_status" == "restarting" || "$btc_status" == "exited" ]]; then
                    echo "boltz-regtest-start stuck in 'created' — boltz-bitcoind is $btc_status"
                    echo "--- boltz-bitcoind logs ---"
                    docker logs boltz-bitcoind 2>&1 | tail -80 || true
                    echo "--- boltz-scripts logs ---"
                    docker logs boltz-scripts 2>&1 | tail -40 || true
                    echo "--- boltz-bitcoind-init logs ---"
                    docker logs boltz-bitcoind-init 2>&1 | tail -40 || true
                    return 1
                fi
            fi

            start_attempt=$((start_attempt + 1))
            if [ $start_attempt -ge $start_max ]; then
                echo "Timed out waiting for boltz-regtest-start after $((start_max * 5))s (status=$status, exit_code=$exit_code)"
                docker logs boltz-regtest-start 2>&1 | tail -100 || true
                return 1
            fi
            echo "Waiting for boltz-regtest-start to complete (attempt $start_attempt/$start_max, status=$status)..."
            sleep 5
        done
    fi
    echo "Containers are healthy"
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    wait_for_healthy "$@"
fi
