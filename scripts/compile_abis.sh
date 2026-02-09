
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../"

BOLTZ_CONTRACTS_DIR="$ROOT_DIR/dependencies/boltz-core"
BOLTZ_CONTRACTS_DIR_OUT="$ROOT_DIR/hostr_sdk/lib/datasources/contracts/boltz"

RIF_RELAY_CONTRACTS_DIR="$ROOT_DIR/dependencies/rif-relay-contracts"
RIF_RELAY_CONTRACTS_DIR_OUT="$ROOT_DIR/hostr_sdk/lib/datasources/contracts/rif_relay"

ESCROW_CONTRACTS_DIR_IN="$ROOT_DIR/escrow/contracts"
ESCROW_CONTRACTS_DIR_OUT="$ROOT_DIR/hostr_sdk/lib/datasources/contracts/escrow"

rm -rf "$BOLTZ_CONTRACTS_DIR_OUT"/* &&
rm -rf "$RIF_RELAY_CONTRACTS_DIR_OUT"/* &&
rm -rf "$ESCROW_CONTRACTS_DIR_OUT"/* &&

# First compile the boltz abis

(
    cd $BOLTZ_CONTRACTS_DIR && npm install && \
    if command -v foundryup >/dev/null 2>&1; then
        echo "Foundry already installed; skipping install"
    else
        curl -L https://foundry.paradigm.xyz | bash
    fi && \
    foundryup && npm run compile:solidity
) &&
find "$BOLTZ_CONTRACTS_DIR/out" \
    -type f \
    -name "*.json" \
    ! -name "*.dbg.json" \
    ! -path "*/build-info/*" \
    -exec cp {} "$BOLTZ_CONTRACTS_DIR_OUT" \; &&
(
    cd $BOLTZ_CONTRACTS_DIR_OUT
    for file in *.json; do
        mv -- "$file" "${file%.json}.abi.json"
    done
) &&

# Then compile RIF (Rootstock gasless transactions) abis

(
    cd $RIF_RELAY_CONTRACTS_DIR && npm install
) &&
find "$RIF_RELAY_CONTRACTS_DIR/artifacts/contracts" \
    -type f \
    -name "*.json" \
    ! -name "*.dbg.json" \
    ! -path "*/build-info/*" \
    -exec cp {} "$RIF_RELAY_CONTRACTS_DIR_OUT" \; &&
(
    cd $RIF_RELAY_CONTRACTS_DIR_OUT
    for file in *.json; do
        mv -- "$file" "${file%.json}.abi.json"
    done
) &&

# Lastly, compile our escrow abis
(
    cd $ESCROW_CONTRACTS_DIR_IN && npm install && npx hardhat compile
) &&
cp "$ESCROW_CONTRACTS_DIR_IN/artifacts/contracts/MultiEscrow.sol/MultiEscrow.json" \
   "$ESCROW_CONTRACTS_DIR_OUT/MultiEscrow.abi.json"

# Now run build_runner to compile abis into dart interfaces

(cd $ROOT_DIR/hostr_sdk && dart run build_runner build --delete-conflicting-outputs)