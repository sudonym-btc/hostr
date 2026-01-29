#!/bin/bash
source ./wait_for_healthy.sh
source ./setup_evm.sh
source ./seed_relay.sh

# Create a shared network if it doesn't exist
docker network inspect shared_network >/dev/null 2>&1 || docker network create shared_network

# Ensure data directories exist
mkdir -p ./docker/data/lightning_data ./docker/data/lightning_shared/{1,2} ./docker/data/relay ./docker/data/bitcoin ./docker/data/blossom ./docker/data/lnbits/{1,2} ./docker/data/albyhub &&
    docker-compose up -d && 
    wait_for_healthy && 
    ./setup_local.sh && 
    CONTRACT_ADDR=$(setup_evm) &&
    seed_relay "$CONTRACT_ADDR" 
    
