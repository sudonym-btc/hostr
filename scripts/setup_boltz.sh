#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### Lightning liquidity with boltz
source "$SCRIPT_DIR/../dependencies/boltz-regtest/aliases.sh"

setup_boltz() {
    # Source aliases here, after containers are running
    source "$SCRIPT_DIR/aliases.sh"

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
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_boltz "$@"
fi
