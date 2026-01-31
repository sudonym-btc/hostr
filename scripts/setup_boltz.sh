#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### Lightning liquidity with boltz
source "$SCRIPT_DIR/../dependencies/boltz-regtest/aliases.sh"
source "$SCRIPT_DIR/setup_ln.sh"

setup_boltz() {
    set -e
    # Source aliases here, after containers are running
    source "$SCRIPT_DIR/aliases.sh"

    ensure_node_online "lncli-sim 1" 
    ensure_node_online "lncli-sim 2" 
    ensure_node_online "lightning-cli-sim 1"
    ensure_node_online "lightning-cli-sim 2" 

    BOLTZ_LND1_PUB=$(lncli-sim 1 getinfo | jq -r .identity_pubkey)
    BOLTZ_LND2_PUB=$(lncli-sim 2 getinfo | jq -r .identity_pubkey)
    BOLTZ_CLN1_PUB=$(lightning-cli-sim 1 getinfo | jq -r .id)
    BOLTZ_CLN2_PUB=$(lightning-cli-sim 2 getinfo | jq -r .id)

    connect_peer "LND1" "$BOLTZ_CLN1_PUB" "${BOLTZ_CLN1_HOST}"
    connect_peer "LND2" "$BOLTZ_CLN1_PUB" "${BOLTZ_CLN1_HOST}"
    connect_peer "LND1" "$BOLTZ_CLN2_PUB" "${BOLTZ_CLN2_HOST}"
    connect_peer "LND2" "$BOLTZ_CLN2_PUB" "${BOLTZ_CLN2_HOST}"
    
    # Connect to boltz LND nodes
    connect_peer "LND1" "$BOLTZ_LND1_PUB" "${BOLTZ_LND1_HOST}"
    connect_peer "LND2" "$BOLTZ_LND1_PUB" "${BOLTZ_LND1_HOST}"
    connect_peer "LND1" "$BOLTZ_LND2_PUB" "${BOLTZ_LND2_HOST}"
    connect_peer "LND2" "$BOLTZ_LND2_PUB" "${BOLTZ_LND2_HOST}"

    # Wait for all nodes to sync before creating channels
    wait_for_sync "LND1"
    wait_for_sync "LND2"
    wait_for_sync "lncli-sim 1"
    wait_for_sync "lncli-sim 2"

    LND1 openchannel ${BOLTZ_LND1_PUB} ${CHANNEL_SIZE} >/dev/null 
    LND2 openchannel ${BOLTZ_LND1_PUB} ${CHANNEL_SIZE} >/dev/null 
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    wait_for_channel "LND1" "${BOLTZ_LND1_PUB}"
    wait_for_channel "LND2" "${BOLTZ_LND1_PUB}"

    wait_for_sync "LND1"
    wait_for_sync "LND2"
    wait_for_sync "lncli-sim 1"
    wait_for_sync "lncli-sim 2"

    LND1 openchannel ${BOLTZ_LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    LND2 openchannel ${BOLTZ_LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    wait_for_channel "LND1" "${BOLTZ_LND2_PUB}"
    wait_for_channel "LND2" "${BOLTZ_LND2_PUB}"

    wait_for_sync "LND1"
    wait_for_sync "LND2"
    wait_for_sync "lncli-sim 1"
    wait_for_sync "lncli-sim 2"

    lncli-sim 1 openchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    lncli-sim 1 openchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_NEW_ADDR >/dev/null
    wait_for_channel "lncli-sim 1" "${LND1_PUB}"
    wait_for_channel "lncli-sim 1" "${LND2_PUB}"
    
    lncli-sim 2 openchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    lncli-sim 2 openchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    wait_for_channel "lncli-sim 2" "${LND1_PUB}"
    wait_for_channel "lncli-sim 2" "${LND2_PUB}"

    wait_for_sync "LND1"
    wait_for_sync "LND2"
    LND1 openchannel ${BOLTZ_CLN1_PUB} ${CHANNEL_SIZE} >/dev/null
    LND2 openchannel ${BOLTZ_CLN1_PUB} ${CHANNEL_SIZE} >/dev/null
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    wait_for_channel "LND1" "${BOLTZ_CLN1_PUB}"
    wait_for_channel "LND2" "${BOLTZ_CLN1_PUB}"
    
    wait_for_sync "LND1"
    wait_for_sync "LND2"
    LND1 openchannel ${BOLTZ_CLN2_PUB} ${CHANNEL_SIZE} >/dev/null
    LND2 openchannel ${BOLTZ_CLN2_PUB} ${CHANNEL_SIZE} >/dev/null
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    wait_for_channel "LND1" "${BOLTZ_CLN2_PUB}"
    wait_for_channel "LND2" "${BOLTZ_CLN2_PUB}"

    lightning-cli-sim 1 fundchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    lightning-cli-sim 1 fundchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    wait_for_channel "lightning-cli-sim 1" "${LND1_PUB}"
    wait_for_channel "lightning-cli-sim 1" "${LND2_PUB}"

    
    lightning-cli-sim 2 fundchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    lightning-cli-sim 2 fundchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null
    wait_for_channel "lightning-cli-sim 2" "${LND1_PUB}"
    wait_for_channel "lightning-cli-sim 2" "${LND2_PUB}"
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_boltz "$@"
fi
