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
    local max_attempts=36  # 36 × 5s = 180s = 3 minutes
    local attempt=0
    echo "Waiting for $cmd_name to sync..."
    while true; do
        local info
        info=$($cmd_name getinfo 2>/dev/null || echo "{}")

        # LND: check .synced_to_chain == true
        local lnd_synced
        lnd_synced=$(echo "$info" | jq -r '.synced_to_chain // empty' 2>/dev/null)
        if [ "$lnd_synced" == "true" ]; then
            echo "$cmd_name synced (LND)"
            break
        fi
        local lnd_blockheight
        lnd_blockheight=$(echo "$info" | jq -r '.block_height // empty' 2>/dev/null)
        if [[ "$lnd_blockheight" =~ ^[0-9]+$ ]]; then
            local chain_height
            if [ "$cmd_name" == "LND" ]; then
                chain_height=$(BTC getblockcount 2>/dev/null | tr -d '[:space:]' || echo "")
            else
                chain_height=$(docker exec boltz-scripts bash -lc "source /etc/profile.d/utils.sh && bitcoin-cli-sim-client getblockcount" 2>/dev/null | tr -d '[:space:]' || echo "")
            fi
            if [[ "$chain_height" =~ ^[0-9]+$ ]] && [ "$chain_height" -ne 0 ] && [ "$lnd_blockheight" -eq "$chain_height" ]; then
                echo "$cmd_name synced (LND block height=$lnd_blockheight)"
                break
            fi
        fi

        # CLN: synced when warning_lightningd_sync is absent/null
        local cln_warning
        cln_warning=$(echo "$info" | jq -r '.warning_lightningd_sync // empty' 2>/dev/null)
        local cln_blockheight
        cln_blockheight=$(echo "$info" | jq -r '.blockheight // empty' 2>/dev/null)
        if [ -n "$cln_blockheight" ] && [ -z "$cln_warning" ]; then
            echo "$cmd_name synced (CLN, blockheight=$cln_blockheight)"
            break
        fi

        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            echo "Timed out waiting for $cmd_name to sync after $((max_attempts * 5))s"
            return 1
        fi
        echo "Waiting for $cmd_name to sync (attempt $attempt/$max_attempts)..."
        sleep 5
    done
}

connect_peer() {
    local cmd_name=$1
    local pubkey=$2
    local addr=$3
    local max_outer_attempts=5
    local outer_attempt=0

    while [ $outer_attempt -lt $max_outer_attempts ]; do
        if $cmd_name listpeers 2>/dev/null | jq -e --arg pk "$pubkey" 'any(.peers[]?; .pub_key == $pk)' >/dev/null 2>&1; then
            echo "Already connected to $pubkey"
            return 0
        fi

        outer_attempt=$((outer_attempt + 1))
        echo "Attempting to connect to $pubkey@$addr (cycle $outer_attempt/$max_outer_attempts)..."

        local max_connect_attempts=10
        local connect_attempt=0
        while [ $connect_attempt -lt $max_connect_attempts ]; do
            output=$($cmd_name connect ${pubkey}@${addr} 2>&1)
            if echo "$output" | grep -q "still in the process of starting"; then
                connect_attempt=$((connect_attempt + 1))
                echo "$cmd_name still starting (attempt $connect_attempt/$max_connect_attempts)..."
                sleep 1
                continue
            fi
            # Check if already connected (race with parallel connects).
            if echo "$output" | grep -qi "already connected"; then
                break
            fi
            # If connect returned an error, retry after a short pause.
            if echo "$output" | grep -qi "error\|failed\|refused\|unavailable"; then
                connect_attempt=$((connect_attempt + 1))
                echo "Connect to $pubkey failed (attempt $connect_attempt/$max_connect_attempts): $output"
                sleep 2
                continue
            fi
            break
        done

        if wait_for_peer_online "$cmd_name" "$pubkey"; then
            return 0
        fi

        # Peer didn't appear — CLN may have dropped the handshake while still
        # processing blocks.  Pause and retry the full connect cycle.
        echo "Peer $pubkey not online yet, retrying connect cycle ($outer_attempt/$max_outer_attempts)..."
        sleep 5
    done

    echo "Peer $pubkey did not come online after $max_outer_attempts connect cycles."
    exit 1
}

wait_for_peer_online() {
    local cmd_name=$1
    local pubkey=$2
    local max_attempts=5
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

wait_for_lnd_synced_to_chain() {
    local max_attempts=36
    local attempt=0
    local synced

    while [ $attempt -lt $max_attempts ]; do
        synced=$(LND getinfo 2>/dev/null | jq -r '.synced_to_chain // false' 2>/dev/null || echo "false")
        if [ "$synced" == "true" ]; then
            echo "LND wallet reports synced_to_chain=true"
            return 0
        fi
        attempt=$((attempt + 1))
        if [ $((attempt % 5)) -eq 0 ]; then
            echo "Waiting for LND wallet strict sync before opening channels (attempt $attempt/$max_attempts)..."
        fi
        sleep 1
    done

    echo "Failed: LND wallet did not report synced_to_chain=true"
    return 1
}

ensure_lnd_wallet_synced_for_channel_open() {
    local synced

    synced=$(LND getinfo 2>/dev/null | jq -r '.synced_to_chain // false' 2>/dev/null || echo "false")
    if [ "$synced" == "true" ]; then
        echo "LND wallet is strictly synced for channel opens."
        return 0
    fi

    echo "LND wallet strict sync is false. Mining one fresh regtest block before channel opens..."
    BTC generatetoaddress 1 $LND_ADDR >/dev/null
    ensure_bitcoind_blockheights_match
    wait_for_lnd_synced_to_chain
}

reconnect_expected_peers() {
    local pids=()

    # Use explicit Lightning peer ports for hostr LND nodes. Their RPC port is
    # different and persisted channels may survive container restarts with no
    # active peer sessions until we reconnect on the P2P port.
    {
        connect_peer "LND" "$BOLTZ_LND1_PUB" "${BOLTZ_LND1_HOST}"
    } & pids+=($!)
    {
        connect_peer "LND" "$BOLTZ_LND2_PUB" "${BOLTZ_LND2_HOST}"
    } & pids+=($!)
    connect_peer "LND" "$BOLTZ_LND3_PUB" "${BOLTZ_LND3_HOST}" & pids+=($!)
    {
        connect_peer "LND" "$BOLTZ_CLN1_PUB" "${BOLTZ_CLN1_HOST}"
    } & pids+=($!)
    {
        connect_peer "LND" "$BOLTZ_CLN2_PUB" "${BOLTZ_CLN2_HOST}"
    } & pids+=($!)
    wait_all_pids "${pids[@]}"

    # Re-run the full reconnection pass after sync to recover peers that may
    # briefly drop during catch-up.
    sync_nodes "LND" "lncli-sim 1" "lncli-sim 2" "lncli-sim 3" \
               "lightning-cli-sim 1" "lightning-cli-sim 2"

    pids=()
    {
        connect_peer "LND" "$BOLTZ_LND1_PUB" "${BOLTZ_LND1_HOST}"
        connect_peer "LND" "$BOLTZ_LND2_PUB" "${BOLTZ_LND2_HOST}"
        connect_peer "LND" "$BOLTZ_LND3_PUB" "${BOLTZ_LND3_HOST}"
        connect_peer "LND" "$BOLTZ_CLN1_PUB" "${BOLTZ_CLN1_HOST}"
        connect_peer "LND" "$BOLTZ_CLN2_PUB" "${BOLTZ_CLN2_HOST}"
    } & pids+=($!)
    wait_all_pids "${pids[@]}"
}

wait_for_expected_hostr_channels() {
    local pids=()

    wait_for_channel "LND" "$BOLTZ_LND1_PUB" & pids+=($!)
    wait_for_channel "LND" "$BOLTZ_LND2_PUB" & pids+=($!)
    wait_for_channel "LND" "$BOLTZ_LND3_PUB" & pids+=($!)
    wait_for_channel "LND" "$BOLTZ_CLN1_PUB" & pids+=($!)
    wait_for_channel "LND" "$BOLTZ_CLN2_PUB" & pids+=($!)

    wait_all_pids "${pids[@]}"
}

hostr_lnd_local_channel_balance() {
    LND channelbalance 2>/dev/null | jq -r '.local_balance.sat // .balance // "0"' 2>/dev/null || echo "0"
}

lnd_wallet_confirmed_balance() {
    LND walletbalance 2>/dev/null | jq -r '.confirmed_balance // "0"' 2>/dev/null || echo "0"
}

lnd_pending_open_channel_count() {
    LND pendingchannels 2>/dev/null | jq -r '(.pending_open_channels // []) | length' 2>/dev/null || echo "0"
}

ensure_lnd_confirmed_balance() {
    local required_balance=$1
    local max_rounds=8
    local round=0
    local confirmed_balance

    while [ $round -lt $max_rounds ]; do
        confirmed_balance=$(lnd_wallet_confirmed_balance)
        if [[ "$confirmed_balance" =~ ^[0-9]+$ ]] && [ "$confirmed_balance" -ge "$required_balance" ]; then
            echo "LND confirmed wallet balance ready: $confirmed_balance sats"
            return 0
        fi

        round=$((round + 1))
        echo "LND confirmed wallet balance below $required_balance sats (current=$confirmed_balance). Mining mature funding round $round/$max_rounds..."
        LND_NEW_ADDR=$(LND newaddress p2wkh 2>/dev/null | jq -r '.address' 2>/dev/null)
        if [ -z "$LND_NEW_ADDR" ] || [ "$LND_NEW_ADDR" == "null" ]; then
            echo "Failed: could not get a fresh LND funding address."
            return 1
        fi

        # Channel opens spend confirmed, mature witness outputs. Mining only
        # funding blocks leaves most coinbase outputs immature on regtest, so
        # we mine a maturity tail before trying to open the next channel.
        BTC generatetoaddress "${HOSTR_LND_FUNDING_BLOCKS:-160}" "$LND_NEW_ADDR" >/dev/null
        BTC generatetoaddress "${HOSTR_LND_MATURITY_BLOCKS:-101}" "$LND_NEW_ADDR" >/dev/null
        sync_nodes "LND"
    done

    confirmed_balance=$(lnd_wallet_confirmed_balance)
    echo "Failed: LND confirmed wallet balance stayed below $required_balance sats (current=$confirmed_balance)."
    return 1
}

wait_for_pending_hostr_open_channels() {
    local pending_count
    pending_count=$(lnd_pending_open_channel_count)
    if [[ ! "$pending_count" =~ ^[0-9]+$ ]] || [ "$pending_count" -eq 0 ]; then
        return 0
    fi

    echo "Found $pending_count pending hostr LND channel open(s). Mining confirmations before opening more."
    BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND_ADDR >/dev/null
    sync_nodes "LND" "lncli-sim 1" "lncli-sim 2" "lncli-sim 3" \
               "lightning-cli-sim 1" "lightning-cli-sim 2"
}

lnd_has_channel_with_peer() {
    local pubkey=$1

    if LND listchannels 2>/dev/null | jq -e --arg pk "$pubkey" \
        'any(.channels[]?; .remote_pubkey == $pk)' >/dev/null 2>&1; then
        return 0
    fi

    LND pendingchannels 2>/dev/null | jq -e --arg pk "$pubkey" \
        'any(.pending_open_channels[]?; .channel.remote_node_pub == $pk)' >/dev/null 2>&1
}

open_hostr_outbound_channel_if_missing() {
    local pubkey=$1
    local label=$2

    if lnd_has_channel_with_peer "$pubkey"; then
        echo "Hostr outbound channel to $label already exists or is pending."
        return 1
    fi

    # Check per-channel spendable balance immediately before each open because
    # earlier opens lock UTXOs and LND will otherwise fail partway through.
    ensure_lnd_confirmed_balance "$((HOSTR_OUTBOUND_CHANNEL_SIZE + 1000000))"
    echo "Opening hostr outbound channel to $label (${HOSTR_OUTBOUND_CHANNEL_SIZE} sats)..."
    LND openchannel "$pubkey" "$HOSTR_OUTBOUND_CHANNEL_SIZE" >/dev/null
    return 0
}

open_missing_hostr_outbound_channels() {
    local opened=0

    open_hostr_outbound_channel_if_missing "$BOLTZ_LND1_PUB" "boltz lnd-1" && opened=1
    open_hostr_outbound_channel_if_missing "$BOLTZ_LND2_PUB" "boltz lnd-2" && opened=1
    open_hostr_outbound_channel_if_missing "$BOLTZ_LND3_PUB" "boltz lnd-3" && opened=1
    open_hostr_outbound_channel_if_missing "$BOLTZ_CLN1_PUB" "boltz cln-1" && opened=1
    open_hostr_outbound_channel_if_missing "$BOLTZ_CLN2_PUB" "boltz cln-2" && opened=1

    if [ "$opened" -eq 1 ]; then
        BTC generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND_ADDR >/dev/null
        sync_nodes "LND" "lncli-sim 1" "lncli-sim 2" "lncli-sim 3" \
                   "lightning-cli-sim 1" "lightning-cli-sim 2"
    fi
}

wait_for_hostr_lnd_local_liquidity() {
    local min_balance=$1
    local max_attempts=120
    local attempt=0
    local local_balance

    while [ $attempt -lt $max_attempts ]; do
        local_balance=$(hostr_lnd_local_channel_balance)
        if [[ "$local_balance" =~ ^[0-9]+$ ]] && [ "$local_balance" -ge "$min_balance" ]; then
            echo "Hostr LND local channel liquidity ready: $local_balance sats"
            return 0
        fi
        attempt=$((attempt + 1))
        if [ $((attempt % 10)) -eq 0 ]; then
            echo "Waiting for Hostr LND local liquidity >= $min_balance sats (current=$local_balance, attempt $attempt/$max_attempts)..."
        fi
        sleep 1
    done

    echo "Warning: Hostr LND local channel liquidity stayed below $min_balance sats"
    return 1
}

ensure_hostr_outbound_liquidity() {
    local min_balance="${HOSTR_LND_LOCAL_LIQUIDITY_MIN:-30000000}"
    local local_balance

    local_balance=$(hostr_lnd_local_channel_balance)
    echo "Hostr LND local channel liquidity: $local_balance sats"

    if [[ "$local_balance" =~ ^[0-9]+$ ]] && [ "$local_balance" -ge "$min_balance" ]; then
        echo "Hostr LND has enough outbound liquidity for e2e runs."
        return 0
    fi

    echo "Hostr LND outbound liquidity below $min_balance sats. Opening top-up channels..."
    ensure_lnd_wallet_synced_for_channel_open
    sync_nodes "LND" "lncli-sim 1" "lncli-sim 2" "lncli-sim 3" \
               "lightning-cli-sim 1" "lightning-cli-sim 2"
    reconnect_expected_peers

    open_missing_hostr_outbound_channels
    wait_for_hostr_lnd_local_liquidity "$min_balance"
}

# ── Main entry point ────────────────────────────────────────────────────

setup_channels() {
    source "$SCRIPT_DIR/aliases.sh"
    source "$SCRIPT_DIR/../dependencies/boltz-regtest/aliases.sh"

    # Local regtest tests spend from Alby/hostr to Boltz. Use the largest
    # channel size accepted by the unmodified Boltz LND peers, and keep
    # Boltz→hostr channels small because we do not need meaningful inbound
    # liquidity for these order payment tests.
    HOSTR_OUTBOUND_CHANNEL_SIZE="${HOSTR_OUTBOUND_CHANNEL_SIZE_SATS:-1000000000}"
    BOLTZ_INBOUND_CHANNEL_SIZE="${BOLTZ_INBOUND_CHANNEL_SIZE_SATS:-${CHANNEL_SIZE:-10000000}}"
    CHANNEL_SIZE="$HOSTR_OUTBOUND_CHANNEL_SIZE"
    LND_MIN_BALANCE="${HOSTR_LND_MIN_BALANCE_SATS:-$((HOSTR_OUTBOUND_CHANNEL_SIZE * 5 + 1000000))}"
    HOSTR_LND_LOCAL_LIQUIDITY_MIN="${HOSTR_LND_LOCAL_LIQUIDITY_MIN:-$HOSTR_OUTBOUND_CHANNEL_SIZE}"
    INITIAL_MINING_BLOCKS="${HOSTR_INITIAL_MINING_BLOCKS:-130}"

    # Override boltz-regtest helper commands for non-interactive execution.
    run_in_boltz_scripts() {
        docker exec boltz-scripts bash -lc "source /etc/profile.d/utils.sh && $(printf '%q ' "$@")"
    }
    lncli-sim() { run_in_boltz_scripts lncli-sim "$@"; }
    lightning-cli-sim() { run_in_boltz_scripts lightning-cli-sim "$@"; }

    # ── Phase 0: Pre-flight checks ────────────────────────────────────
    ensure_bitcoind_blockheights_match

    local pids=()
    ensure_node_online "LND"            & pids+=($!)
    ensure_node_online "lncli-sim 1"     & pids+=($!)
    ensure_node_online "lncli-sim 2"     & pids+=($!)
    ensure_node_online "lncli-sim 3"     & pids+=($!)
    ensure_node_online "lightning-cli-sim 1" & pids+=($!)
    ensure_node_online "lightning-cli-sim 2" & pids+=($!)
    wait_all_pids "${pids[@]}"

    # ── Phase 1: Fund hostr LND nodes if needed ───────────────────────
    # LND channel opens require confirmed spendable wallet outputs. The total
    # balance can include immature coinbase outputs and pending change.
    local lnd_balance=$(lnd_wallet_confirmed_balance)
    echo "LND confirmed balance: $lnd_balance sats"
    ensure_lnd_confirmed_balance "$((HOSTR_OUTBOUND_CHANNEL_SIZE + 1000000))"

    # ── Phase 2: Collect pubkeys & reconnect persisted peers ──────────
    BOLTZ_LND1_PUB=$(lncli-sim 1 getinfo | jq -r .identity_pubkey)
    BOLTZ_LND2_PUB=$(lncli-sim 2 getinfo | jq -r .identity_pubkey)
    BOLTZ_LND3_PUB=$(lncli-sim 3 getinfo | jq -r .identity_pubkey)
    BOLTZ_CLN1_PUB=$(lightning-cli-sim 1 getinfo | jq -r .id)
    BOLTZ_CLN2_PUB=$(lightning-cli-sim 2 getinfo | jq -r .id)

    sync_nodes "LND"
    reconnect_expected_peers

    local lnd_channels
    while true; do
        lnd_channels=$(LND listchannels 2>/dev/null | jq '.channels | length' 2>/dev/null || echo "0")
        if [[ "$lnd_channels" =~ ^[0-9]+$ ]]; then
            break
        fi
        echo "Waiting for LND listchannels to be ready..."
        sleep 5
    done

    local lnd_pending_channels
    lnd_pending_channels=$(lnd_pending_open_channel_count)
    if [ "$lnd_channels" -gt 0 ] || { [[ "$lnd_pending_channels" =~ ^[0-9]+$ ]] && [ "$lnd_pending_channels" -gt 0 ]; }; then
        echo "Channels already exist or are pending. Waiting for persisted channels to reactivate."
        wait_for_pending_hostr_open_channels
        open_missing_hostr_outbound_channels
        wait_for_expected_hostr_channels
        ensure_hostr_outbound_liquidity
        echo "Persisted channels are active."
        return 0
    fi

    echo "No channels found. Creating hostr outbound channels with ${HOSTR_OUTBOUND_CHANNEL_SIZE} sats each..."

    # ── Phase 3: Connect every peer before opening channels ───────────

    # Ensure all nodes (including CLN) have caught up with the blocks mined
    # during funding, otherwise CLN will silently drop incoming LN handshakes.
    sync_nodes "LND" "lncli-sim 1" "lncli-sim 2" "lncli-sim 3" \
               "lightning-cli-sim 1" "lightning-cli-sim 2"

    reconnect_expected_peers

    # ── Phase 4: Sync all nodes after peer connections ──────────────────
    sync_nodes "LND" "lncli-sim 1" "lncli-sim 2" "lncli-sim 3" \
               "lightning-cli-sim 1" "lightning-cli-sim 2"

    # ── Phase 5: Batch 1 — all outbound opens from hostr LND ──────
    # LND → boltz LND1/LND2/LND3/CLN1/CLN2 = 5 channels.
    ensure_lnd_wallet_synced_for_channel_open
    echo "Opening 5 outbound channels (hostr LND → all boltz peers, ${HOSTR_OUTBOUND_CHANNEL_SIZE} sats each)..."
    open_missing_hostr_outbound_channels

    pids=()
    wait_for_channel "LND" "${BOLTZ_LND1_PUB}" & pids+=($!)
    wait_for_channel "LND" "${BOLTZ_LND2_PUB}" & pids+=($!)
    wait_for_channel "LND" "${BOLTZ_LND3_PUB}" & pids+=($!)
    wait_for_channel "LND" "${BOLTZ_CLN1_PUB}" & pids+=($!)
    wait_for_channel "LND" "${BOLTZ_CLN2_PUB}" & pids+=($!)
    wait_all_pids "${pids[@]}"

    # ── Phase 6: Batch 2 — small inbound opens from boltz → hostr ────
    sync_nodes "LND" "lncli-sim 1" "lncli-sim 2" "lncli-sim 3" \
               "lightning-cli-sim 1" "lightning-cli-sim 2"

    echo "Opening 5 small inbound channels (boltz → hostr LND, ${BOLTZ_INBOUND_CHANNEL_SIZE} sats each)..."
    lncli-sim 1 openchannel ${LND_PUB} ${BOLTZ_INBOUND_CHANNEL_SIZE} >/dev/null
    lncli-sim 2 openchannel ${LND_PUB} ${BOLTZ_INBOUND_CHANNEL_SIZE} >/dev/null
    lncli-sim 3 openchannel ${LND_PUB} ${BOLTZ_INBOUND_CHANNEL_SIZE} >/dev/null
    # CLN: sequential per node to avoid wallet UTXO lock conflicts.
    lightning-cli-sim 1 fundchannel ${LND_PUB} ${BOLTZ_INBOUND_CHANNEL_SIZE} >/dev/null
    lightning-cli-sim 2 fundchannel ${LND_PUB} ${BOLTZ_INBOUND_CHANNEL_SIZE} >/dev/null

    # Mine on Boltz's bitcoind — the funding txs were broadcast by Boltz
    # nodes and may not have propagated to hostr's mempool yet.
    run_in_boltz_scripts bitcoin-cli-sim-client generatetoaddress ${CHANNEL_BLOCK_CONFIRMATIONS} $LND_ADDR >/dev/null

    pids=()
    wait_for_channel "lncli-sim 1" "${LND_PUB}"     & pids+=($!)
    wait_for_channel "lncli-sim 2" "${LND_PUB}"     & pids+=($!)
    wait_for_channel "lncli-sim 3" "${LND_PUB}"     & pids+=($!)
    wait_for_channel "lightning-cli-sim 1" "${LND_PUB}" & pids+=($!)
    wait_for_channel "lightning-cli-sim 2" "${LND_PUB}" & pids+=($!)
    wait_all_pids "${pids[@]}"

    wait_for_hostr_lnd_local_liquidity "${HOSTR_LND_LOCAL_LIQUIDITY_MIN:-30000000}"
    echo "All channels created successfully."
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_channels "$@"
fi
