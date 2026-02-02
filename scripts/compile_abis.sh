
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=$SCRIPT_DIR/../

(
    cd $ROOT_DIR/dependencies/boltz-core && npm install && curl -L https://foundry.paradigm.xyz | bash && foundryup && npm run compile:solidity
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
(cd $ROOT_DIR/app && dart run build_runner build --delete-conflicting-outputs)