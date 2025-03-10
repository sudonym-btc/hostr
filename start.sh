#!/bin/bash
source ./wait_for_healthy.sh

(cd ./docker/boltz && DOCKER_DEFAULT_PLATFORM=linux/amd64 COMPOSE_PROFILES=ci ./start.sh) &&
    docker-compose up -d && wait_for_healthy
