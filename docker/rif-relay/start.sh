#!/usr/bin/env bash

cleanup() {
    echo 'SIGINT or SIGTERM received, exiting'
    exit 0
}

trap cleanup SIGINT SIGTERM

register_relay() {
    sleep 15
    cd /rif-relay-server
    npm run register
}

cd /rif-relay-contracts
npx hardhat deploy --network regtest

cd /rif-relay-server

register_relay &
npm run start &

wait
