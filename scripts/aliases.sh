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

LND() {
    local lnd_container="${LND_CONTAINER:-$(resolve_compose_container lnd)}"

    if [ -z "$lnd_container" ]; then
        echo "Unable to resolve the LND container name." >&2
        return 1
    fi

    docker exec "$lnd_container" lncli --rpcserver=localhost:${LIGHTNING_RPC_PORT} --macaroonpath=${LND_MACAROON} --tlscertpath=${LND_TLS} "$@"
}

LND_PUB=$(LND getinfo | jq -r .identity_pubkey)

LND_ADDR=$(LND newaddress p2tr | jq -r .address)
