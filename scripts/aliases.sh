#!/bin/bash

# Load environment variables from .env
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../.env" ]; then
    export $(cat "$(dirname "${BASH_SOURCE[0]}")/../.env" | grep -v '^#' | xargs)
fi

# Define command functions for commonly used commands
BTC() {
    docker exec ${BITCOIN_HOST} bitcoin-cli -regtest -rpcuser=${BITCOIN_RPC_USER} -rpcpassword=${BITCOIN_RPC_PASSWORD} -rpcport=${BITCOIN_RPC_PORT} "$@"
}

LND1() {
    docker exec ${LND1_CONTAINER} lncli --rpcserver=localhost:${LIGHTNING_RPC_PORT} --macaroonpath=${LND1_MACAROON} --tlscertpath=${LND1_TLS} "$@"
}

LND2() {
    docker exec ${LND2_CONTAINER} lncli --rpcserver=localhost:${LIGHTNING_RPC_PORT} --macaroonpath=${LND2_MACAROON} --tlscertpath=${LND2_TLS} "$@"
}

LND1_PUB=$(LND1 getinfo | jq -r .identity_pubkey)
LND2_PUB=$(LND2 getinfo | jq -r .identity_pubkey)

LND1_ADDR=$(LND1 newaddress p2tr | jq -r .address)
LND2_ADDR=$(LND2 newaddress p2tr | jq -r .address)
