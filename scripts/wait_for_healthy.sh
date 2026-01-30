#!/bin/bash

wait_for_healthy() {
    while [[ $(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}healthy{{end}}' $(docker ps -q) | grep -v healthy) ]]; do
        echo "Waiting for containers to be healthy..."
        sleep 5
    done
    echo "Containers are healthy"
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    wait_for_healthy "$@"
fi
