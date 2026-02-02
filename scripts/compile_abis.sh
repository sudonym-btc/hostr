
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=$SCRIPT_DIR/../


# First compile the boltz abis

(
    cd $ROOT_DIR/dependencies/boltz-core && npm install && \
    if command -v foundryup >/dev/null 2>&1; then
        echo "Foundry already installed; skipping install"
    else
        curl -L https://foundry.paradigm.xyz | bash
    fi && \
    foundryup && npm run compile:solidity
) &&
rm -rf "$ROOT_DIR/app/lib/data/sources/boltz/contracts"/* &&
find "$ROOT_DIR/dependencies/boltz-core/out" \
    -type f \
    -name "*.json" \
    ! -name "*.dbg.json" \
    ! -path "*/build-info/*" \
    -exec cp {} "$ROOT_DIR/app/lib/data/sources/boltz/contracts" \; &&
(
    cd $ROOT_DIR/app/lib/data/sources/boltz/contracts
    for file in *.json; do
        mv -- "$file" "${file%.json}.abi.json"
    done
) &&

# Then compile RIF (Rootstock gasless transactions) abis

(
    cd $ROOT_DIR/dependencies/rif-relay-contracts && npm install
) &&
find "$ROOT_DIR/dependencies/rif-relay-contracts/artifacts/contracts" \
    -type f \
    -name "*.json" \
    ! -name "*.dbg.json" \
    ! -path "*/build-info/*" \
    -exec cp {} "$ROOT_DIR/app/lib/data/sources/rif_relay/contracts" \; &&
(
    cd $ROOT_DIR/app/lib/data/sources/rif_relay/contracts
    for file in *.json; do
        mv -- "$file" "${file%.json}.abi.json"
    done
) &&

# Lastly, compile our escrow abis
(
    cd $ROOT_DIR/escrow/contracts && npm install && npx hardhat compile
) &&
cp "$ROOT_DIR/escrow/contracts/artifacts/contracts/MultiEscrow.sol/MultiEscrow.json" \
   "$ROOT_DIR/app/lib/data/sources/escrow/MultiEscrow.abi.json" &&

# Now run build_runner to compile abis into dart interfaces

(cd $ROOT_DIR/app && dart run build_runner build --delete-conflicting-outputs)