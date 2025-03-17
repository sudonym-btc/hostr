#!/bin/bash
source ./wait_for_healthy.sh

# Create a shared network if it doesn't exist
docker network inspect shared_network >/dev/null 2>&1 || docker network create shared_network

(cd ./docker/boltz && DOCKER_DEFAULT_PLATFORM=linux/amd64 COMPOSE_PROFILES=ci ./start.sh) &&
    docker-compose up -d && wait_for_healthy
