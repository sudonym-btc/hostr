#!/bin/bash
BTC="docker exec hostrbitcoind bitcoin-cli -regtest -rpcuser=bitcoin -rpcpassword=bitcoin -rpcport=18888"
LND1="docker exec hostr-lnd1-1 lncli --rpcserver=localhost:8080 --macaroonpath=/shared/1/admin.macaroon --tlscertpath=/shared/1/tls.cert"
LND2="docker exec hostr-lnd2-1 lncli --rpcserver=localhost:8080 --macaroonpath=/shared/2/admin.macaroon --tlscertpath=/shared/2/tls.cert"

LND1_PUB=$(eval "$LND1 getinfo" | jq -r .identity_pubkey)
LND2_PUB=$(eval "$LND2 getinfo" | jq -r .identity_pubkey)

LND1_ADDR=$(eval "$LND1 newaddress p2tr" | jq -r .address)
LND2_ADDR=$(eval "$LND2 newaddress p2tr" | jq -r .address)
