#!/bin/bash

# Load environment variables from .env
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../.env" ]; then
    export $(cat "$(dirname "${BASH_SOURCE[0]}")/../.env" | grep -v '^#' | xargs)
fi

# Define command functions for commonly used commands
resolve_compose_container() {
    local service_name="$1"
    local project_name="${COMPOSE_PROJECT_NAME:-hostr}"

    docker ps \
        --filter "label=com.docker.compose.project=${project_name}" \
        --filter "label=com.docker.compose.service=${service_name}" \
        --format '{{.Names}}' | head -n 1
}

BTC() {
    local bitcoin_container="${BITCOIN_CONTAINER:-$(resolve_compose_container hostrbitcoind)}"

    if [ -z "$bitcoin_container" ]; then
        echo "Unable to resolve the hostr bitcoind container name." >&2
        return 1
    fi

    docker exec "$bitcoin_container" bitcoin-cli -regtest -rpcuser=${BITCOIN_RPC_USER} -rpcpassword=${BITCOIN_RPC_PASSWORD} -rpcport=${BITCOIN_RPC_PORT} "$@"
}

LND1() {
    local lnd_container="${LND1_CONTAINER:-$(resolve_compose_container lnd1)}"

    if [ -z "$lnd_container" ]; then
        echo "Unable to resolve the LND1 container name." >&2
        return 1
    fi

    docker exec "$lnd_container" lncli --rpcserver=localhost:${LIGHTNING_RPC_PORT} --macaroonpath=${LND1_MACAROON} --tlscertpath=${LND1_TLS} "$@"
}

LND2() {
    local lnd_container="${LND2_CONTAINER:-$(resolve_compose_container lnd2)}"

    if [ -z "$lnd_container" ]; then
        echo "Unable to resolve the LND2 container name." >&2
        return 1
    fi

    docker exec "$lnd_container" lncli --rpcserver=localhost:${LIGHTNING_RPC_PORT} --macaroonpath=${LND2_MACAROON} --tlscertpath=${LND2_TLS} "$@"
}

LND1_PUB=$(LND1 getinfo | jq -r .identity_pubkey)
LND2_PUB=$(LND2 getinfo | jq -r .identity_pubkey)

LND1_ADDR=$(LND1 newaddress p2tr | jq -r .address)
LND2_ADDR=$(LND2 newaddress p2tr | jq -r .address)
