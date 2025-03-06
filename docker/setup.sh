BTC="docker exec bitcoind bitcoin-cli -regtest -rpcuser=bitcoin -rpcpassword=bitcoin -rpcport=18888"
LND1="docker exec hostr-lnd1-1 lncli --rpcserver=localhost:8080 --macaroonpath=/shared/1/admin.macaroon --tlscertpath=/shared/1/tls.cert"
LND2="docker exec hostr-lnd2-1 lncli --rpcserver=localhost:8080 --macaroonpath=/shared/2/admin.macaroon --tlscertpath=/shared/2/tls.cert"

LND1_PUB=$(eval "$LND1 getinfo" | jq -r .identity_pubkey)
LND2_PUB=$(eval "$LND2 getinfo" | jq -r .identity_pubkey)

LND1_ADDR=$(eval "$LND1 newaddress p2tr" | jq -r .address)
LND2_ADDR=$(eval "$LND2 newaddress p2tr" | jq -r .address)

eval "$BTC generatetoaddress 105 $LND1_ADDR"
eval "$BTC generatetoaddress 105 $LND2_ADDR"

sleep 5

# Connect nodes (from lnd1 perspective)
eval "$LND1 connect ${LND2_PUB}@lnd2"

# Allow time for the connection to be established
sleep 5

eval "$LND1 openchannel ${LND2_PUB} 10000000"
# Mine the open txns
eval "$BTC generatetoaddress 6 $LND1_ADDR"

sleep 5

eval "$LND2 openchannel ${LND1_PUB} 10000000"

# Mine the open txns
eval "$BTC generatetoaddress 6 $LND1_ADDR"
