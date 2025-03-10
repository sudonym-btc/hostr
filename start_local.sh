#!/bin/bash
source ./wait_for_healthy.sh

rm -rf ./docker/data &&
    docker-compose up -d && wait_for_healthy && ./setup_local.sh && (cd models && dart run lib/stubs/seed.dart ws://relay.hostr.development)
