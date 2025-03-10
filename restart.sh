#!/bin/bash
./stop.sh &&
    rm -rf ./docker/data &&
    rm -rf ./docker/boltz/data &&
    rm -rf ../boltz &&
    git clone git@github.com:BoltzExchange/regtest.git ../boltz &&
    cp -r ../boltz/data ./docker/boltz/ &&
    chmod 777 ./docker/boltz/data &&
    ./start.sh &&
    ./setup_local.sh &&
    ./setup.sh
# Remove dirty boltz data
# If backend fails to start might have to run regtest-start script again to complete deploying contracts
