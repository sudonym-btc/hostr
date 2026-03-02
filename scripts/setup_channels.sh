#!/bin/bash
# setup_channels.sh — Opens ALL lightning channels (hostr LND ↔ LND + boltz)
# in two batched mine rounds.  Replaces the old setup_ln.sh + setup_boltz.sh.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Shared utilities ─────────────────────────────────────────────────────

ensure_bitcoind_blockheights_match() {
    local max_attempts=30
    local attempt=0

    echo "Ensuring bitcoind block heights match between hostr and boltz..."

    get_boltz_height() {
        docker exec boltz-scripts bash -lc "source /etc/profile.d/utils.sh && bitcoin-cli-sim-client getblockcount" 2>/dev/null | tr -d '[:space:]'
    }

    while [ $attempt -lt $max_attempts ]; do
        local hostr_height=$(BTC getblockcount 2>/dev/null | tr -d '[:space:]')
        local boltz_height=$(get_boltz_height)

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

    while [ $connect_attempt -lt $max_connect_attempts ]; do
        output=$($cmd_name connect ${pubkey}@${addr} 2>&1)
        if echo "$output" | grep -q "still in the process of starting"; then
            connect_attempt=$((connect_attempt + 1))
            echo "$cmd_name still starting (attempt $connect_attempt/$max_connect_attempts)..."
            sleep 1
            continue
        fi
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

# Wait for all PIDs; return 1 if any fail.
wait_all_pids() {
    local failed=0
    for pid in "$@"; do
        if ! wait "$pid"; then
            failed=1
        fi
    done
    return $failed
}

# Wait-for-sync on multiple nodes in parallel.
sync_nodes() {
    local pids=()
    for node in "$@"; do
        wait_for_sync "$node" & pids+=($!)
    done
    wait_all_pids "${pids[@]}"
}

# ── Main entry point ────────────────────────────────────────────────────

setup_channels() {
    source "$SCRIPT_DIR/aliases.sh"
    source "$SCRIPT_DIR/../dependencies/boltz-regtest/aliases.sh"

    # Override boltz-regtest helper commands for non-interactive execution.
    run_in_boltz_scripts() {
        docker exec boltz-scripts bash -lc "source /etc/profile.d/utils.sh && $(printf '%q ' "$@")"
    }
    lncli-sim() { run_in_boltz_scripts lncli-sim "$@"; }
    lightning-cli-sim() { run_in_boltz_scripts lightning-cli-sim "$@"; }

    # ── Phase 0: Pre-flight checks ────────────────────────────────────
    ensure_bitcoind_blockheights_match

    local pids=()
    ensure_node_online "LND1"            & pids+=($!)
    ensure_node_online "LND2"            & pids+=($!)
    ensure_node_online "lncli-sim 1"     & pids+=($!)
    ensure_node_online "lncli-sim 2"     & pids+=($!)
    ensure_node_online "lightning-cli-sim 1" & pids+=($!)
    ensure_node_online "lightning-cli-sim 2" & pids+=($!)
    wait_all_pids "${pids[@]}"

    # ── Phase 1: Fund hostr LND nodes if needed ───────────────────────
    local lnd1_balance=$(LND1 walletbalance 2>/dev/null | jq -r '.total_balance // "0"' 2>/dev/null || echo "0")
    local lnd2_balance=$(LND2 walletbalance 2>/dev/null | jq -r '.total_balance // "0"' 2>/dev/null || echo "0")
    echo "LND1 balance: $lnd1_balance sats"
    echo "LND2 balance: $lnd2_balance sats"

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

    # ── Phase 2: Early-out if channels already exist ──────────────────
    sync_nodes "LND1" "LND2"

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

    echo "No channels found. Creating all lightning channels..."

    # ── Phase 3: Collect pubkeys & connect every peer ─────────────────
    BOLTZ_LND1_PUB=$(lncli-sim 1 getinfo | jq -r .identity_pubkey)
    BOLTZ_LND2_PUB=$(lncli-sim 2 getinfo | jq -r .identity_pubkey)
    BOLTZ_CLN1_PUB=$(lightning-cli-sim 1 getinfo | jq -r .id)
    BOLTZ_CLN2_PUB=$(lightning-cli-sim 2 getinfo | jq -r .id)

    # Serialize connections to the same target node — CLN drops one of two
    # simultaneous inbound handshakes.  Different targets run in parallel.
    pids=()
    connect_peer "LND1" "$LND2_PUB" "lnd2" & pids+=($!)
    {
        connect_peer "LND1" "$BOLTZ_LND1_PUB" "${BOLTZ_LND1_HOST}"
        connect_peer "LND2" "$BOLTZ_LND1_PUB" "${BOLTZ_LND1_HOST}"
    } & pids+=($!)
    {
        connect_peer "LND1" "$BOLTZ_LND2_PUB" "${BOLTZ_LND2_HOST}"
        connect_peer "LND2" "$BOLTZ_LND2_PUB" "${BOLTZ_LND2_HOST}"
    } & pids+=($!)
    {
        connect_peer "LND1" "$BOLTZ_CLN1_PUB" "${BOLTZ_CLN1_HOST}"
        connect_peer "LND2" "$BOLTZ_CLN1_PUB" "${BOLTZ_CLN1_HOST}"
    } & pids+=($!)
    {
        connect_peer "LND1" "$BOLTZ_CLN2_PUB" "${BOLTZ_CLN2_HOST}"
        connect_peer "LND2" "$BOLTZ_CLN2_PUB" "${BOLTZ_CLN2_HOST}"
    } & pids+=($!)
    wait_all_pids "${pids[@]}"

    # ── Phase 4: Sync all nodes ───────────────────────────────────────
    sync_nodes "LND1" "LND2" "lncli-sim 1" "lncli-sim 2"

    # ── Phase 5: Batch 1 — all 10 outbound opens from hostr LND ──────
    # LND1↔LND2 (2) + LND1/2 → boltz LND1/LND2/CLN1/CLN2 (8) = 10.
    # maxpendingchannels=10 per node (docker-compose), peak per node = 5.
    echo "Opening 10 outbound channels (hostr LND → all peers)..."
    LND1 openchannel ${LND2_PUB}       ${CHANNEL_SIZE} >/dev/null
    LND2 openchannel ${LND1_PUB}       ${CHANNEL_SIZE} >/dev/null
    LND1 openchannel ${BOLTZ_LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    LND2 openchannel ${BOLTZ_LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    LND1 openchannel ${BOLTZ_LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    LND2 openchannel ${BOLTZ_LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    LND1 openchannel ${BOLTZ_CLN1_PUB} ${CHANNEL_SIZE} >/dev/null
    LND2 openchannel ${BOLTZ_CLN1_PUB} ${CHANNEL_SIZE} >/dev/null
    LND1 openchannel ${BOLTZ_CLN2_PUB} ${CHANNEL_SIZE} >/dev/null
    LND2 openchannel ${BOLTZ_CLN2_PUB} ${CHANNEL_SIZE} >/dev/null

    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null

    pids=()
    wait_for_channel "LND1" "$LND2_PUB"       & pids+=($!)
    wait_for_channel "LND2" "$LND1_PUB"       & pids+=($!)
    wait_for_channel "LND1" "${BOLTZ_LND1_PUB}" & pids+=($!)
    wait_for_channel "LND2" "${BOLTZ_LND1_PUB}" & pids+=($!)
    wait_for_channel "LND1" "${BOLTZ_LND2_PUB}" & pids+=($!)
    wait_for_channel "LND2" "${BOLTZ_LND2_PUB}" & pids+=($!)
    wait_for_channel "LND1" "${BOLTZ_CLN1_PUB}" & pids+=($!)
    wait_for_channel "LND2" "${BOLTZ_CLN1_PUB}" & pids+=($!)
    wait_for_channel "LND1" "${BOLTZ_CLN2_PUB}" & pids+=($!)
    wait_for_channel "LND2" "${BOLTZ_CLN2_PUB}" & pids+=($!)
    wait_all_pids "${pids[@]}"

    # ── Phase 6: Batch 2 — all 8 inbound opens from boltz → hostr ────
    sync_nodes "LND1" "LND2" "lncli-sim 1" "lncli-sim 2"

    echo "Opening 8 inbound channels (boltz → hostr LND)..."
    lncli-sim 1 openchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    lncli-sim 1 openchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    lncli-sim 2 openchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    lncli-sim 2 openchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    # CLN: sequential per node to avoid wallet UTXO lock conflicts.
    lightning-cli-sim 1 fundchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    lightning-cli-sim 1 fundchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null
    lightning-cli-sim 2 fundchannel ${LND1_PUB} ${CHANNEL_SIZE} >/dev/null
    lightning-cli-sim 2 fundchannel ${LND2_PUB} ${CHANNEL_SIZE} >/dev/null

    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND1_ADDR >/dev/null

    pids=()
    wait_for_channel "lncli-sim 1" "${LND1_PUB}"     & pids+=($!)
    wait_for_channel "lncli-sim 1" "${LND2_PUB}"     & pids+=($!)
    wait_for_channel "lncli-sim 2" "${LND1_PUB}"     & pids+=($!)
    wait_for_channel "lncli-sim 2" "${LND2_PUB}"     & pids+=($!)
    wait_for_channel "lightning-cli-sim 1" "${LND1_PUB}" & pids+=($!)
    wait_for_channel "lightning-cli-sim 1" "${LND2_PUB}" & pids+=($!)
    wait_for_channel "lightning-cli-sim 2" "${LND1_PUB}" & pids+=($!)
    wait_for_channel "lightning-cli-sim 2" "${LND2_PUB}" & pids+=($!)
    wait_all_pids "${pids[@]}"

    echo "All channels created successfully."
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_channels "$@"
fi
