#!/bin/bash
BTC="docker exec hostrbitcoind bitcoin-cli -regtest -rpcuser=bitcoin -rpcpassword=bitcoin -rpcport=18888"
LND1="docker exec hostr-lnd1-1 lncli --rpcserver=localhost:8080 --macaroonpath=/shared/1/admin.macaroon --tlscertpath=/shared/1/tls.cert"
LND2="docker exec hostr-lnd2-1 lncli --rpcserver=localhost:8080 --macaroonpath=/shared/2/admin.macaroon --tlscertpath=/shared/2/tls.cert"

LND1_PUB=$(eval "$LND1 getinfo" | jq -r .identity_pubkey)
LND2_PUB=$(eval "$LND2 getinfo" | jq -r .identity_pubkey)

LND1_ADDR=$(eval "$LND1 newaddress p2tr" | jq -r .address)
LND2_ADDR=$(eval "$LND2 newaddress p2tr" | jq -r .address)

### Connect bitcoin node with boltz
# Add the boltz bitcoind node as a peer
eval "$BTC addnode bitcoind add"
# Add the boltz bitcoind node as a peer to the hostr bitcoind node
# eval "$BTC addnode <boltz_bitcoind_container_name> add"

###

sleep 5

eval "$BTC generatetoaddress 105 $LND1_ADDR"
eval "$BTC generatetoaddress 105 $LND2_ADDR"

sleep 5

# Connect nodes (from lnd1 perspective)
eval "$LND1 connect ${LND2_PUB}@lnd2"

# Allow time for the connection to be established
sleep 5

eval "$LND1 openchannel ${LND2_PUB} 10000000"
# Mine the open txns
eval "$BTC generatetoaddress 10 $LND1_ADDR"

sleep 5

eval "$LND2 openchannel ${LND1_PUB} 10000000"

# Mine the open txns
eval "$BTC generatetoaddress 10 $LND1_ADDR"

### Lightning liquidity with boltz
source ./docker/boltz/aliases.sh

BOLTZ_LND1_PUB=$(lncli-sim 1 getinfo | jq -r .identity_pubkey)
BOLTZ_LND2_PUB=$(lncli-sim 2 getinfo | jq -r .identity_pubkey)
BOLTZ_CLN1_PUB=$(lightning-cli-sim 1 getinfo | jq -r .id)
BOLTZ_CLN2_PUB=$(lightning-cli-sim 2 getinfo | jq -r .id)

# Connect to boltz LND nodes
eval "$LND1 connect ${BOLTZ_LND1_PUB}@lnd-1"
eval "$LND2 connect ${BOLTZ_LND1_PUB}@lnd-1"
eval "$LND1 connect ${BOLTZ_LND2_PUB}@lnd-2"
eval "$LND2 connect ${BOLTZ_LND2_PUB}@lnd-2"

eval "$LND1 connect ${BOLTZ_CLN1_PUB}@cln-1"
eval "$LND2 connect ${BOLTZ_CLN1_PUB}@cln-1"
eval "$LND1 connect ${BOLTZ_CLN2_PUB}@cln-2"
eval "$LND2 connect ${BOLTZ_CLN2_PUB}@cln-2"

eval "$LND1 openchannel ${BOLTZ_LND1_PUB} 10000000"
eval "$LND2 openchannel ${BOLTZ_LND1_PUB} 10000000"
eval "$BTC generatetoaddress 10 $LND1_ADDR"
eval "$LND1 openchannel ${BOLTZ_LND2_PUB} 10000000"
eval "$LND2 openchannel ${BOLTZ_LND2_PUB} 10000000"
eval "$BTC generatetoaddress 10 $LND1_ADDR"

lncli-sim 1 openchannel ${LND1_PUB} 10000000
lncli-sim 1 openchannel ${LND2_PUB} 10000000
eval "$BTC generatetoaddress 10 $LND1_ADDR"
lncli-sim 2 openchannel ${LND1_PUB} 10000000
lncli-sim 2 openchannel ${LND2_PUB} 10000000
eval "$BTC generatetoaddress 10 $LND1_ADDR"

eval "$LND1 openchannel ${BOLTZ_CLN1_PUB} 10000000"
eval "$LND2 openchannel ${BOLTZ_CLN1_PUB} 10000000"
eval "$BTC generatetoaddress 10 $LND1_ADDR"
eval "$LND1 openchannel ${BOLTZ_CLN2_PUB} 10000000"
eval "$LND2 openchannel ${BOLTZ_CLN2_PUB} 10000000"
eval "$BTC generatetoaddress 10 $LND1_ADDR"

sleep 5

lightning-cli-sim 1 fundchannel ${LND1_PUB} 10000000
lightning-cli-sim 1 fundchannel ${LND2_PUB} 10000000
eval "$BTC generatetoaddress 20 $LND1_ADDR"
lightning-cli-sim 2 fundchannel ${LND1_PUB} 10000000
lightning-cli-sim 2 fundchannel ${LND2_PUB} 10000000
eval "$BTC generatetoaddress 20 $LND1_ADDR"
