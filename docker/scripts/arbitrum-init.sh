#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# arbitrum-init.sh
#
# Deploys EtherSwap, ERC20Swap, and a mock tBTC ERC20 token to the
# anvil-arbitrum chain (chain-id 412346).  Uses bytecodes extracted
# from the boltz-regtest utils.sh (mounted read-only).
#
# Runs once at startup via the `arbitrum-init` service.
# ─────────────────────────────────────────────────────────────────────────────
set -eu
export FOUNDRY_DISABLE_NIGHTLY_WARNING="${FOUNDRY_DISABLE_NIGHTLY_WARNING:-true}"

ARBITRUM_RPC="http://anvil-arbitrum:8545"

# Anvil Account #1 — deployer for swap contracts (deterministic addresses)
DEPLOYER_PK="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
LOCAL_BYTECODES="${LOCAL_BYTECODES_DIR:-/scripts/local-chain-bytecodes}"
DEPLOY_CREATE_ADDRESS=""

deploy_create() {
  local name="$1"
  local bytecode_file="$2"
  local private_key="$3"
  local constructor_args="${4:-}"
  local bytecode args tx deployed code

  bytecode=$(cat "$bytecode_file")
  args=$(echo "$constructor_args" | sed 's/^0x//')
  tx=$(cast send --rpc-url "$ARBITRUM_RPC" --private-key "$private_key" \
    --create "${bytecode}${args}" --json 2>&1)
  deployed=$(echo "$tx" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)

  if [ -z "$deployed" ]; then
    echo "ERROR: Failed to extract $name address from deployment output"
    echo "$tx"
    exit 1
  fi

  code=$(cast code --rpc-url "$ARBITRUM_RPC" "$deployed")
  if [ "$code" = "0x" ] || [ -z "$code" ]; then
    echo "ERROR: No contract code at $name address $deployed"
    exit 1
  fi

  DEPLOY_CREATE_ADDRESS="$deployed"
  echo "  ✓ $name deployed at $deployed"
}

echo "Waiting for anvil-arbitrum..."
until cast chain-id --rpc-url "$ARBITRUM_RPC" 2>/dev/null; do sleep 0.5; done
echo "anvil-arbitrum is up (chain-id: $(cast chain-id --rpc-url "$ARBITRUM_RPC"))"

# ── 1. Deploy swap contracts ─────────────────────────────────────────────
# Extract bytecodes from the mounted boltz-regtest utils.sh (read-only).
# deploy_contracts() calls deploy_contract() with EtherSwap then ERC20Swap.
ETHERSWAP_BYTECODE=$(sed -n '/# EtherSwap/{n;s/^[[:space:]]*deploy_contract //;p;}' /scripts/boltz-utils.sh)
ERC20SWAP_BYTECODE=$(sed -n '/# ERC20Swap/{n;s/^[[:space:]]*deploy_contract //;p;}' /scripts/boltz-utils.sh)

if [ -z "$ETHERSWAP_BYTECODE" ] || [ -z "$ERC20SWAP_BYTECODE" ]; then
  echo "ERROR: Failed to extract bytecodes from /scripts/boltz-utils.sh"
  exit 1
fi

echo "Deploying EtherSwap (nonce 0)..."
cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" --create $ETHERSWAP_BYTECODE

echo "Deploying ERC20Swap (nonce 1)..."
cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" --create $ERC20SWAP_BYTECODE

# ── 2. Deploy MockTBTC ERC20 (nonce 2) ───────────────────────────────────
echo "Deploying MockTBTC..."
TBTC_SUPPLY="1000000000000000000000000"  # 1M tBTC (18 decimals)
TBTC_ARGS=$(cast abi-encode "constructor(uint256)" "$TBTC_SUPPLY")
deploy_create "MockTBTC" "$LOCAL_BYTECODES/MockTBTC.hex" "$DEPLOYER_PK" "$TBTC_ARGS"
TBTC_ADDRESS="$DEPLOY_CREATE_ADDRESS"

EXPECTED_ADDRESS="0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F"
if [ "$(echo "$TBTC_ADDRESS" | tr '[:upper:]' '[:lower:]')" != "$(echo "$EXPECTED_ADDRESS" | tr '[:upper:]' '[:lower:]')" ]; then
  echo "WARNING: MockTBTC deployed at $TBTC_ADDRESS (expected $EXPECTED_ADDRESS)"
  echo "         Update docker/boltz.conf contractAddress if this persists!"
fi

# ── 3. Deploy MockUSDT ERC20 (nonce 3) ───────────────────────────────────
echo "Deploying MockUSDT..."
USDT_SUPPLY="1000000000000"  # 1M USDT (6 decimals)
USDT_ARGS=$(cast abi-encode "constructor(uint256)" "$USDT_SUPPLY")
deploy_create "MockUSDT" "$LOCAL_BYTECODES/MockUSDT.hex" "$DEPLOYER_PK" "$USDT_ARGS"
USDT_ADDRESS="$DEPLOY_CREATE_ADDRESS"

echo ""
echo "═══════════════════════════════════════════════"
echo " Arbitrum Contracts Deployed"
echo "═══════════════════════════════════════════════"
echo " EtherSwap:  0x8464135c8F25Da09e49BC8782676a84730C318bC"
echo " ERC20Swap:  0x71C95911E9a5D330f4D621842EC243EE1343292e"
echo " MockTBTC:   $TBTC_ADDRESS"
echo " MockUSDT:   $USDT_ADDRESS"
echo "═══════════════════════════════════════════════"

# ── 4. Write token address manifest ──────────────────────────────────────
# Written to a mounted volume so sync-contract-env.sh can read it.
TOKEN_MANIFEST="/data/token-addresses.json"
cat > "$TOKEN_MANIFEST" << JSONEOF
{
  "regtest.412346": {
    "tBTC": { "address": "$TBTC_ADDRESS", "decimals": 18 },
    "USDT": { "address": "$USDT_ADDRESS", "decimals": 6 }
  }
}
JSONEOF
echo "Token manifest written to $TOKEN_MANIFEST"

# ── 5. Fund default Anvil accounts with tBTC and USDT ───────────────────
echo ""
echo "Funding default Anvil accounts with tBTC and USDT..."
TBTC_AMOUNT="100000000000000000000000"  # 100k tBTC each (18 decimals)
USDT_AMOUNT="100000000000"              # 100k USDT each (6 decimals)

for ACCT in \
  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" \
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC" \
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906" \
  "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65" \
  "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"
do
  echo "  Sending 100k tBTC to $ACCT"
  cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" \
    "$TBTC_ADDRESS" "transfer(address,uint256)" "$ACCT" "$TBTC_AMOUNT" >/dev/null
  echo "  Sending 100k USDT to $ACCT"
  cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" \
    "$USDT_ADDRESS" "transfer(address,uint256)" "$ACCT" "$USDT_AMOUNT" >/dev/null
done

# Fund explicit boltz wallet if specified
if [ -n "${BOLTZ_WALLET_ADDRESS:-}" ]; then
  echo "  Sending 100k tBTC to boltz wallet $BOLTZ_WALLET_ADDRESS"
  cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" \
    "$TBTC_ADDRESS" "transfer(address,uint256)" "$BOLTZ_WALLET_ADDRESS" "$TBTC_AMOUNT" >/dev/null

  echo "  Sending 100k USDT to boltz wallet $BOLTZ_WALLET_ADDRESS"
  cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" \
    "$USDT_ADDRESS" "transfer(address,uint256)" "$BOLTZ_WALLET_ADDRESS" "$USDT_AMOUNT" >/dev/null

  # Also send native ETH/ARB for gas
  echo "  Sending 1000 ETH to boltz wallet for gas"
  cast send --rpc-url "$ARBITRUM_RPC" \
    --private-key "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" \
    --value 1000ether "$BOLTZ_WALLET_ADDRESS" >/dev/null
fi

# ── 6. Deploy Uniswap V3 stack ───────────────────────────────────────────
# Deploys WETH9, Multicall3, UniswapV3Factory, NonfungiblePositionManager,
# QuoterV2, SwapRouter02.  Creates WETH/USDT + WETH/tBTC pools and seeds
# full-range liquidity.
export ARBITRUM_RPC="$ARBITRUM_RPC"
export TBTC_ADDRESS="$TBTC_ADDRESS"
export USDT_ADDRESS="$USDT_ADDRESS"
export DEPLOYER_PK="$DEPLOYER_PK"
sh /scripts/deploy-uniswap-v3.sh

echo ""
echo "Arbitrum init complete."
