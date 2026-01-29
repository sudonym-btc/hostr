#!/bin/bash
source ./aliases.sh

# Wait for lightning nodes to be synched to chain
# Function to wait for LND to sync
wait_for_sync() {
    local lnd_command=$1
    while true; do
        synced=$($lnd_command getinfo | jq -r '.synced_to_chain')
        echo $synced
        if [ "$synced" == "true" ]; then
            break
        fi
        echo "Waiting for $lnd_command to sync..."
        sleep 5
    done
}

# Function to check if channels already exist between two nodes
ensure_channels() {
    # Check if blockchain has blocks, if not mine some first
    local block_count=$($BTC getblockcount 2>/dev/null || echo "0")
    if [ "$block_count" -eq 0 ]; then
        echo "No blocks mined yet. Generating initial blocks..."
        eval "$BTC generatetoaddress 105 $LND1_ADDR"
        eval "$BTC generatetoaddress 105 $LND2_ADDR"
    fi
    
    # Wait for nodes to sync first
    wait_for_sync "$LND1"
    wait_for_sync "$LND2"
    
    # Check if channels already exist
    local lnd1_channels=$($LND1 listchannels 2>/dev/null | jq '.channels | length' 2>/dev/null || echo "0")
    local lnd2_channels=$($LND2 listchannels 2>/dev/null | jq '.channels | length' 2>/dev/null || echo "0")
    
    if [ "$lnd1_channels" -gt 0 ] && [ "$lnd2_channels" -gt 0 ]; then
        echo "Channels already exist. Skipping channel creation."
        return 0
    fi

    echo "Channels not found. Creating channels between lnd1 and lnd2..."

    # Wait for nodes to sync after generating blocks
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
    
    echo "Channels created successfully."
}

# Ensure channels between lnd1 and lnd2
ensure_channels

./setup_lnbits.sh 5055 jeremy
./setup_lnbits.sh 5056 jasmine
./setup_albyhub.sh https://alby1.hostr.development test Testing123!
./setup_albyhub.sh https://alby2.hostr.development test Testing123!
