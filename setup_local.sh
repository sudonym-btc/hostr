#!/bin/bash
source ./aliases.sh

eval "$BTC generatetoaddress 105 $LND1_ADDR"
eval "$BTC generatetoaddress 105 $LND2_ADDR"

# Wait for lightning nodes to be synched to chain
# Function to wait for LND to sync
wait_for_sync() {
    local lnd_command=$1
    while true; do
        synced=$($lnd_command getinfo | jq -r '.synced_to_chain')
        if [ "$synced" == "true" ]; then
            break
        fi
        echo "Waiting for $lnd_command to sync..."
        sleep 5
    done
}
# Wait for lightning nodes to be synced to chain
wait_for_sync "$LND1"
wait_for_sync "$LND2"

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

./setup_lnbits.sh 5055 jeremy
./setup_lnbits.sh 5056 jasmine
./setup_albyhub.sh https://alby1.hostr.development test Testing123!
./setup_albyhub.sh https://alby2.hostr.development test Testing123!
