#!/bin/bash
(cd ./docker/boltz && DOCKER_DEFAULT_PLATFORM=linux/amd64 COMPOSE_PROFILES=ci ./start.sh) &&
    docker-compose up -d nginx-proxy hostrbitcoind relay lnd1 lnd2 lnbits1 lnbits2 albyhub1 albyhub2 &&
    # Wait for containers to be healthy
    while [[ $(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}healthy{{end}}' $(docker ps -q) | grep -v healthy) ]]; do
        echo "Waiting for containers to be healthy..."
        sleep 5
    done
