#!/usr/bin/env bash
set -euo pipefail

cleanup() {
    echo 'SIGINT/SIGTERM received'
    exit 0
}

trap cleanup SIGINT SIGTERM

prepare_workdir() {
    local default_workdir="$1"

    export RIF_RELAY_WORKDIR="${RIF_RELAY_WORKDIR:-$default_workdir}"
    mkdir -p "$RIF_RELAY_WORKDIR"
    rm -f "$RIF_RELAY_WORKDIR/txstore.db"
}

sync_deployed_addresses() {
    local source_file="/rif-relay-contracts/contract-addresses.json"
    local target_file="$RIF_RELAY_WORKDIR/contract-addresses.json"

    if [[ ! -f "$source_file" ]]; then
        echo "No deployed relay address manifest found at $source_file" >&2
        return 1
    fi

    mkdir -p "$(dirname "$target_file")"
    cp "$source_file" "$target_file"
    echo "Copied relay address manifest to $target_file"
}

write_regtest_fast_config() {
    printf '%s\n' \
        '{' \
        '  app: {' \
        '    workdir: "'"$RIF_RELAY_WORKDIR"'",' \
        '  },' \
        '  blockchain: {' \
        '    rskNodeUrl: "'"${RPC_URL:-}"'",' \
        '    confirmationsNeeded: 1,' \
        '    successfulRoundsForReady: 0,' \
        '  },' \
        '  register: {' \
        '    funds: "'"${REGISTER_FUNDS:-}"'",' \
        '  },' \
        '}' \
        >/rif-relay-server/config/local.json5
}

allowlist_escrow_on_boltz_verifiers() {
    local boltz_verifiers
    boltz_verifiers="$(node -e "
      const fs=require('fs');
      const p='$RIF_RELAY_WORKDIR/contract-addresses.json';
      const j=JSON.parse(fs.readFileSync(p,'utf8'));
      const c=j['regtest.33']||{};
      const v=[c.BoltzDeployVerifier,c.BoltzRelayVerifier].filter(Boolean);
      process.stdout.write(v.join(','));
    " 2>/dev/null || true)"

    if [[ -z "$boltz_verifiers" ]]; then
        echo "Boltz verifier addresses not found — skipping allowlist"
        return 0
    fi

    for i in $(seq 1 120); do
        local escrow_addr
        escrow_addr="$(node -e "const fs=require('fs');const p='/escrow-contracts/contract-addresses.json';if(!fs.existsSync(p)){process.exit(2)};const j=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write(String(j['regtest.33']?.MultiEscrow||''));" 2>/dev/null || true)"

        if [[ -n "$escrow_addr" ]]; then
            echo "Allowlisting escrow $escrow_addr on verifiers $boltz_verifiers…"
            cd /rif-relay-contracts
            if npx hardhat allow-contracts \
                --contract-list "$escrow_addr" \
                --verifier-list "$boltz_verifiers" \
                --network regtest; then
                echo 'Escrow contract allowlisted on Boltz verifiers'
                return 0
            fi
            echo 'Allow-contracts failed, will retry…'
        else
            echo "Escrow contract address not available yet (attempt $i/120)…"
        fi

        sleep 2
    done
}

register_relay_when_ready() {
    cd /rif-relay-server
    for i in $(seq 1 30); do
        sleep 5
        if curl -sf http://127.0.0.1:8090/chain-info >/dev/null 2>&1; then
            echo "Server is up, attempting registration (attempt $i)..."
            if npm run register; then
                echo 'Registration successful'
                return 0
            fi
            echo 'Registration failed, will retry...'
        else
            echo "Server not ready yet (attempt $i/30)..."
        fi
    done
}

start_managed() {
    local default_workdir="$1"

    prepare_workdir "$default_workdir"
    /write_local_config.sh
    cd /rif-relay-server
    exec npm run start
}

start_regtest_fast() {
    prepare_workdir /tmp/rif-relay
    write_regtest_fast_config

    cd /rif-relay-contracts
    # Deploy the relay hub (+ penalizer) and the Boltz smart-wallet family
    # (BoltzSmartWallet + BoltzSmartWalletFactory + BoltzDeployVerifier +
    # BoltzRelayVerifier).  The Boltz factory forwards req.data during
    # deploy, which is required for claimAndFund-style relay calls.
    npx hardhat deploy --relay-hub --boltz-smart-wallet --network regtest
    sync_deployed_addresses

    # The Boltz verifiers enforce a destination-contract allowlist.
    # Allowlist the MultiEscrow so relayed calls targeting it are accepted.
    # We pass --verifier-list explicitly so the hardhat task doesn't try to
    # load every verifier family from the manifest (only Boltz is deployed).
    # This is the same mechanism used for mainnet allowlisting.
    #
    # The escrow contract is deployed by a separate container that starts
    # *after* rif-relay, so we run this in the background with retries.
    allowlist_escrow_on_boltz_verifiers &

    register_relay_when_ready &

    cd /rif-relay-server
    exec npm run start
}

case "${RIF_RELAY_MODE:-regtest-managed}" in
    regtest-fast)
        start_regtest_fast
        ;;
    regtest-managed)
        start_managed /tmp/rif-relay
        ;;
    hosted)
        start_managed /srv/app/environment
        ;;
    *)
        echo "Unsupported RIF_RELAY_MODE: ${RIF_RELAY_MODE:-}" >&2
        exit 64
        ;;
esac
