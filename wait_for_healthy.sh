#!/bin/bash
wait_for_healthy() {
    while [[ $(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}healthy{{end}}' $(docker ps -q) | grep -v healthy) ]]; do
        echo "Waiting for containers to be healthy..."
        sleep 5
    done
    echo "Containers are healthy"
}
