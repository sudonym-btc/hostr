#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ensure_bitcoind_blockheights_match() {
    local max_attempts=30
    local attempt=0

    echo "Ensuring bitcoind block heights match between hostr and boltz..."

    get_boltz_height() {
        docker exec boltz-scripts bash -lc "source /etc/profile.d/utils.sh && bitcoin-cli-sim-client getblockcount" 2>/dev/null | tr -d '[:space:]'
    }

    while [ $attempt -lt $max_attempts ]; do
        # Hostr bitcoind height

        local hostr_height=$(BTC getblockcount 2>/dev/null | tr -d '[:space:]')
        local boltz_height=$(get_boltz_height)

        # Only proceed if both heights are integers
        if [[ "$hostr_height" =~ ^[0-9]+$ ]] && [[ "$boltz_height" =~ ^[0-9]+$ ]] && [ "$hostr_height" -eq "$boltz_height" ] && [ "$hostr_height" -ne 0 ]; then
            echo "Both bitcoind nodes have matching block heights: $hostr_height"
            return 0
        fi

        attempt=$((attempt + 1))
        echo "Block heights do not match yet (attempt $attempt/$max_attempts). Hostr: $hostr_height, Boltz: $boltz_height"
        sleep 2
    done

    echo "Failed: Bitcoind block heights did not match after $max_attempts attempts"
    return 1
}

# Function to wait for a lightning node to come online
ensure_node_online() {
    local cmd_name=$1
    local max_attempts=60
    local attempt=0

    echo "Ensuring $cmd_name is online..."

    while [ $attempt -lt $max_attempts ]; do
        if output=$($cmd_name getinfo 2>&1); then
            status=0
        else
            status=$?
        fi
        # echo "$output"
        if [ $status -eq 0 ]; then
            echo "$cmd_name is online"
            return 0
        fi
        attempt=$((attempt + 1))
        echo "Waiting for $cmd_name to come online (attempt $attempt/$max_attempts)..."
        sleep 1
    done

    echo "Failed: $cmd_name did not come online after $max_attempts attempts"
    return 1
}

# Function to wait for LND to sync
wait_for_sync() {
    local cmd_name=$1
    echo "Waiting for $cmd_name to sync..."
    while true; do
        synced=$($cmd_name getinfo 2>/dev/null | jq -r '.synced_to_chain' 2>/dev/null || echo "false")
        echo "$cmd_name is synched $synced"
        if [ "$synced" == "true" ]; then
            break
        fi
        echo "Waiting for $cmd_name to sync..."
        sleep 5
    done
}

connect_peer() {
    local cmd_name=$1
    local pubkey=$2
    local addr=$3
    local max_connect_attempts=30
    local connect_attempt=0

    if $cmd_name listpeers 2>/dev/null | jq -e --arg pk "$pubkey" 'any(.peers[]?; .pub_key == $pk)' >/dev/null 2>&1; then
        echo "Already connected to $pubkey"
        return 0
    fi

    echo "Attempting to connect to $pubkey@$addr..."
    
    # Retry connect command in case server is still starting
    while [ $connect_attempt -lt $max_connect_attempts ]; do
        output=$($cmd_name connect ${pubkey}@${addr} 2>&1)
        if echo "$output" | grep -q "still in the process of starting"; then
            connect_attempt=$((connect_attempt + 1))
            echo "$cmd_name still starting (attempt $connect_attempt/$max_connect_attempts)..."
            sleep 1
            continue
        fi
        
        # Connection initiated or already exists
        break
    done

    if wait_for_peer_online "$cmd_name" "$pubkey"; then
        return 0
    fi

    echo "Peer $pubkey did not come online after attempts."
    exit 1
}

wait_for_peer_online() {
    local cmd_name=$1
    local pubkey=$2
    local max_attempts=10
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if $cmd_name listpeers 2>/dev/null | jq -e --arg pk "$pubkey" 'any(.peers[]?; .pub_key == $pk)' >/dev/null 2>&1; then
            echo "Peer $pubkey is now online"
            return 0
        fi
        attempt=$((attempt + 1))
        echo "Waiting for peer $pubkey to be online (attempt $attempt/$max_attempts)..."
        sleep 1
    done
    
    return 1
}

wait_for_channel() {
    local cmd_name=$1
    local pubkey=$2
    local max_attempts=120
    local attempt=0

    echo "Waiting for $cmd_name channel with $pubkey to become active..."

    while [ $attempt -lt $max_attempts ]; do
        # Check for active channel with the pubkey
        # LND uses .remote_pubkey and .active == true
        # CLN uses .destination and .active == true
        if $cmd_name listchannels 2>/dev/null | jq -e --arg pk "$pubkey" \
            'any(.channels[]?; 
                (.remote_pubkey == $pk or .destination == $pk) and .active == true
            )' >/dev/null 2>&1; then
            echo "$cmd_name channel with $pubkey is now active"
            return 0
        fi
        attempt=$((attempt + 1))
        if [ $((attempt % 10)) -eq 0 ]; then
            echo "Still waiting for $cmd_name channel (attempt $attempt/$max_attempts)..."
        fi
        sleep 1
    done
    
    echo "Warning: $cmd_name channel with $pubkey did not become active after $max_attempts seconds"
    return 1
}

# Function to check if channels already exist between two nodes
ensure_channels() {
    # Source aliases here, after containers are running
    source "$SCRIPT_DIR/aliases.sh"

    ensure_bitcoind_blockheights_match

    ensure_node_online "LND1"
    ensure_node_online "LND2"
    
    # Check if LND nodes have onchain funds
    local lnd1_balance=$(LND1 walletbalance 2>/dev/null | jq -r '.total_balance // "0"' 2>/dev/null || echo "0")
    local lnd2_balance=$(LND2 walletbalance 2>/dev/null | jq -r '.total_balance // "0"' 2>/dev/null || echo "0")

    echo "LND1 balance: $lnd1_balance sats"
    echo "LND2 balance: $lnd2_balance sats"
    
    # Fund nodes if they have less than LND_MIN_BALANCE (default 0.5 BTC)
    if [ "$lnd1_balance" -lt ${LND_MIN_BALANCE} ]; then
        echo "LND1 needs funding. Generating address and mining blocks..."
        LND1_NEW_ADDR=$(LND1 newaddress p2wkh 2>/dev/null | jq -r '.address' 2>/dev/null)
        if [ -n "$LND1_NEW_ADDR" ]; then
            BTC generatetoaddress ${INITIAL_MINING_BLOCKS} $LND1_NEW_ADDR >/dev/null
        fi
    fi
    
    if [ "$lnd2_balance" -lt ${LND_MIN_BALANCE} ]; then
        echo "LND2 needs funding. Generating address and mining blocks..."
        LND2_NEW_ADDR=$(LND2 newaddress p2wkh 2>/dev/null | jq -r '.address' 2>/dev/null)
        if [ -n "$LND2_NEW_ADDR" ]; then
            BTC generatetoaddress ${INITIAL_MINING_BLOCKS} $LND2_NEW_ADDR >/dev/null
        fi
    fi
    
    # Wait for nodes to sync first
    wait_for_sync "LND1"
    wait_for_sync "LND2"
    
    # Check if channels already exist
    local lnd1_channels
    local lnd2_channels
    while true; do
        lnd1_channels=$(LND1 listchannels 2>/dev/null | jq '.channels | length' 2>/dev/null || echo "0")
        lnd2_channels=$(LND2 listchannels 2>/dev/null | jq '.channels | length' 2>/dev/null || echo "0")
        if [[ "$lnd1_channels" =~ ^[0-9]+$ ]] && [[ "$lnd2_channels" =~ ^[0-9]+$ ]]; then
            break
        fi
        echo "Waiting for LND listchannels to be ready..."
        sleep 5
    done
    
    if [ "$lnd1_channels" -gt 0 ] && [ "$lnd2_channels" -gt 0 ]; then
        echo "Channels already exist. Skipping channel creation."
        return 0
    fi

    echo "Channels not found. Creating channels between lnd1 and lnd2..."

    # Wait for nodes to sync after generating blocks
    wait_for_sync "LND1"
    wait_for_sync "LND2"

    echo "Connecting lnd1 and lnd2 peers..."
    
    # Connect nodes (from lnd1 perspective)
    connect_peer "LND1" "$LND2_PUB" "lnd2"

    LND1 openchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    # Mine the open txns
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    
    # Wait for the channel to become active before opening another one
    wait_for_channel "LND1" "$LND2_PUB" 

    LND2 openchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null 

    # Mine the open txns
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    
    # Wait for the second channel to become active
    wait_for_channel "LND2" "$LND1_PUB"
    
    echo "Channels created successfully."
}

setup_ln() {
    # Ensure channels between lnd1 and lnd2
    ensure_channels
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ln "$@"
fi
