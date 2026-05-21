#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# deploy-uniswap-v3.sh
#
# Deploys the full Uniswap V3 stack on anvil-arbitrum for ERC20 quoting
# and swapping in the local regtest environment.
#
# Deployed contracts (dedicated deployer, deterministic addresses):
#   Nonce 0 → WETH9              0x057ef64E23666F000b34aE31332854aCBd1c8544
#   Nonce 1 → Multicall3         0x261D8c5e9742e6f7f1076Fa1F560894524e19cad
#   Nonce 2 → UniswapV3Factory   0xCE3478A9E0167a6Bc5716DC39DbbbfAc38F27623
#   Nonce 3 → NonfungiblePosMgr  0xCba6b9A951749B8735C603e7fFC5151849248772
#   Nonce 4 → QuoterV2           0xe4EB561155AFCe723bB1fF8606Fbfe9b28d5d38D
#   Nonce 5 → Permit2            0xcf27F781841484d5CF7e155b44954D7224caF1dD
#   Nonce 6 → UnsupportedProto   0x673cD70FA883394a1f3DEb3221937Ceb7C2618D7
#   Nonce 7 → UniversalRouter    0x6179FBb91b239b574A4565e2c55A6fD38C3372d3
#
# After deployment:
#   - Creates tBTC/USDT (fee=3000) pool
#   - Initialises pool at $70,000/tBTC
#   - Seeds full-range liquidity
#
# The Boltz sidecar generates DEX calldata targeting the Universal Router's
# execute(bytes,bytes[]) interface.  Previous versions deployed SwapRouter02
# here, which caused UserOp reverts because SwapRouter02 does not have the
# execute(bytes,bytes[]) function.
#
# Called from arbitrum-init.sh after MockTBTC + MockUSDT deployment.
#
# Required env:
#   ARBITRUM_RPC     – RPC endpoint (e.g. http://anvil-arbitrum:8545)
#   TBTC_ADDRESS     – deployed MockTBTC address
#   USDT_ADDRESS     – deployed MockUSDT address
#   DEPLOYER_PK      – private key of Account #1 (token holder)
# ─────────────────────────────────────────────────────────────────────────────
set -eu
export FOUNDRY_DISABLE_NIGHTLY_WARNING="${FOUNDRY_DISABLE_NIGHTLY_WARNING:-true}"

: "${ARBITRUM_RPC:?ARBITRUM_RPC is required}"
: "${TBTC_ADDRESS:?TBTC_ADDRESS is required}"
: "${USDT_ADDRESS:?USDT_ADDRESS is required}"
: "${DEPLOYER_PK:?DEPLOYER_PK is required}"

RPC="$ARBITRUM_RPC"

# ── Uniswap deployer: dedicated Anvil account (clean nonce 0) ─────────────
# Do not reuse this key for Alto, account abstraction deployers, or seed txs:
# those services run independently and would consume deterministic nonces.
UNI_PK="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
UNI_DEPLOYER="0x90F79bf6EB2c4f870365E785982E1f101E93b906"

# Pre-extracted creation bytecodes (mounted from host)
BYTECODES="${BYTECODES_DIR:-/scripts/uniswap-v3-bytecodes}"
LOCAL_BYTECODES="${LOCAL_BYTECODES_DIR:-/scripts/local-chain-bytecodes}"

# ── Expected deterministic addresses (deployer nonces 0-7) ────────────────
WETH_ADDR="0x057ef64E23666F000b34aE31332854aCBd1c8544"
MULTICALL3_ADDR="0x261D8c5e9742e6f7f1076Fa1F560894524e19cad"
FACTORY_ADDR="0xCE3478A9E0167a6Bc5716DC39DbbbfAc38F27623"
NFT_POS_MGR="0xCba6b9A951749B8735C603e7fFC5151849248772"
QUOTER_V2_ADDR="0xe4EB561155AFCe723bB1fF8606Fbfe9b28d5d38D"
PERMIT2_ADDR="0xcf27F781841484d5CF7e155b44954D7224caF1dD"
UNSUPPORTED_ADDR="0x673cD70FA883394a1f3DEb3221937Ceb7C2618D7"
UNIVERSAL_ROUTER_ADDR="0x6179FBb91b239b574A4565e2c55A6fD38C3372d3"

# Zero address for unused constructor args
ZERO="0x0000000000000000000000000000000000000000"

echo ""
echo "═══════════════════════════════════════════════"
echo " Deploying Uniswap V3 Stack"
echo "═══════════════════════════════════════════════"
echo "  Deployer:  $UNI_DEPLOYER (fresh nonce 0 required)"
echo "  tBTC:      $TBTC_ADDRESS"
echo "  USDT:      $USDT_ADDRESS"
echo ""

# ── Helper: verify deployed address matches expectation ───────────────────
verify_deploy() {
  local name="$1" actual="$2" expected="$3"
  # Compare case-insensitively (cast --json returns lowercase, compute-address returns checksummed)
  local actual_lc expected_lc
  actual_lc=$(echo "$actual" | tr '[:upper:]' '[:lower:]')
  expected_lc=$(echo "$expected" | tr '[:upper:]' '[:lower:]')
  if [ "$actual_lc" != "$expected_lc" ]; then
    echo "  ⚠ $name deployed at $actual (expected $expected)"
    echo "  All subsequent addresses will be wrong. Aborting."
    exit 1
  fi
  local code
  code=$(cast code --rpc-url "$RPC" "$actual")
  if [ "$code" = "0x" ] || [ -z "$code" ]; then
    echo "  ✗ No code at $name ($actual)"
    exit 1
  fi
  echo "  ✓ $name  $actual"
}

require_clean_uniswap_deployer() {
  local nonce
  nonce=$(cast nonce --rpc-url "$RPC" "$UNI_DEPLOYER")
  if [ "$nonce" != "0" ]; then
    echo "  ✗ Uniswap deployer nonce is $nonce; expected 0 before deterministic deployment."
    echo "  The expected addresses in this script depend on deploying from a fresh"
    echo "  $UNI_DEPLOYER account. Restart/recreate anvil-arbitrum and rerun the"
    echo "  one-shot init container instead of rerunning against the dirty chain."
    exit 1
  fi
}

# ══════════════════════════════════════════════════════════════════════════
# PHASE 1: Deploy contracts
# ══════════════════════════════════════════════════════════════════════════

require_clean_uniswap_deployer

# ── 1a. WETH9 (nonce 0) ──────────────────────────────────────────────────
echo "▶ [1/8] Deploying WETH9..."
WETH_BYTECODE=$(cat "$LOCAL_BYTECODES/WETH9.hex")
WETH_OUT=$(cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  --create "$WETH_BYTECODE" --json 2>&1)
WETH_DEPLOYED=$(echo "$WETH_OUT" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)
verify_deploy "WETH9" "$WETH_DEPLOYED" "$WETH_ADDR"

# ── 1b. Multicall3 (nonce 1) ─────────────────────────────────────────────
echo "▶ [2/8] Deploying Multicall3..."
MC_BYTECODE=$(cat "$LOCAL_BYTECODES/Multicall3.hex")
MC_OUT=$(cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  --create "$MC_BYTECODE" --json 2>&1)
MC_DEPLOYED=$(echo "$MC_OUT" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)
verify_deploy "Multicall3" "$MC_DEPLOYED" "$MULTICALL3_ADDR"

# ── 1c. UniswapV3Factory (nonce 2) — from pre-extracted bytecode ─────────
echo "▶ [3/8] Deploying UniswapV3Factory..."
FACTORY_BYTECODE=$(cat "$BYTECODES/UniswapV3Factory.hex")
FACTORY_TX=$(cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  --create "$FACTORY_BYTECODE" --json 2>&1)
FACTORY_DEPLOYED=$(echo "$FACTORY_TX" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)
verify_deploy "UniswapV3Factory" "$FACTORY_DEPLOYED" "$FACTORY_ADDR"

# ── 1d. NonfungiblePositionManager (nonce 3) ─────────────────────────────
echo "▶ [4/8] Deploying NonfungiblePositionManager..."
NFT_BYTECODE=$(cat "$BYTECODES/NonfungiblePositionManager.hex")
# Constructor: (address _factory, address _WETH9, address _tokenDescriptor_)
# Pass address(0) for tokenDescriptor — only used by tokenURI() which we don't need
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address,address)" \
  "$FACTORY_ADDR" "$WETH_ADDR" "$ZERO")
NFT_TX=$(cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  --create "${NFT_BYTECODE}$(echo "$CONSTRUCTOR_ARGS" | sed 's/^0x//')" --json 2>&1)
NFT_DEPLOYED=$(echo "$NFT_TX" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)
verify_deploy "NonfungiblePositionManager" "$NFT_DEPLOYED" "$NFT_POS_MGR"

# ── 1e. QuoterV2 (nonce 4) ───────────────────────────────────────────────
echo "▶ [5/8] Deploying QuoterV2..."
QUOTER_BYTECODE=$(cat "$BYTECODES/QuoterV2.hex")
# Constructor: (address _factory, address _WETH9)
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address)" \
  "$FACTORY_ADDR" "$WETH_ADDR")
QUOTER_TX=$(cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  --create "${QUOTER_BYTECODE}$(echo "$CONSTRUCTOR_ARGS" | sed 's/^0x//')" --json 2>&1)
QUOTER_DEPLOYED=$(echo "$QUOTER_TX" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)
verify_deploy "QuoterV2" "$QUOTER_DEPLOYED" "$QUOTER_V2_ADDR"

# ── 1f. Permit2 (nonce 5) ─────────────────────────────────────────────────
echo "▶ [6/8] Deploying Permit2..."
PERMIT2_BYTECODE=$(cat "$BYTECODES/Permit2.hex")
PERMIT2_TX=$(cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  --create "$PERMIT2_BYTECODE" --json 2>&1)
PERMIT2_DEPLOYED=$(echo "$PERMIT2_TX" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)
verify_deploy "Permit2" "$PERMIT2_DEPLOYED" "$PERMIT2_ADDR"

# ── 1g. UnsupportedProtocol (nonce 6) ────────────────────────────────────
echo "▶ [7/8] Deploying UnsupportedProtocol..."
UNSUPPORTED_BYTECODE=$(cat "$BYTECODES/UnsupportedProtocol.hex")
UNSUPPORTED_TX=$(cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  --create "$UNSUPPORTED_BYTECODE" --json 2>&1)
UNSUPPORTED_DEPLOYED=$(echo "$UNSUPPORTED_TX" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)
verify_deploy "UnsupportedProtocol" "$UNSUPPORTED_DEPLOYED" "$UNSUPPORTED_ADDR"

# ── 1h. UniversalRouter (nonce 7) ────────────────────────────────────────
# The Boltz sidecar encodes DEX swaps targeting the Universal Router's
# execute(bytes,bytes[]) function.  Constructor args: RouterParameters struct.
echo "▶ [8/8] Deploying UniversalRouter..."
ROUTER_BYTECODE=$(cat "$BYTECODES/UniversalRouter.hex")
# poolInitCodeHash: standard UniswapV3Pool init code hash
POOL_INIT_CODE_HASH="0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54"
# RouterParameters(permit2, weth9, v2Factory, v3Factory, pairInitCodeHash,
#                  poolInitCodeHash, v4PoolManager, v3NFTPositionManager,
#                  v4PositionManager, spokePool)
CONSTRUCTOR_ARGS=$(cast abi-encode \
  "constructor((address,address,address,address,bytes32,bytes32,address,address,address,address))" \
  "($PERMIT2_ADDR,$WETH_ADDR,$UNSUPPORTED_ADDR,$FACTORY_ADDR,0x0000000000000000000000000000000000000000000000000000000000000000,$POOL_INIT_CODE_HASH,$UNSUPPORTED_ADDR,$NFT_POS_MGR,$UNSUPPORTED_ADDR,$UNSUPPORTED_ADDR)")
ROUTER_TX=$(cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  --create "${ROUTER_BYTECODE}$(echo "$CONSTRUCTOR_ARGS" | sed 's/^0x//')" --json 2>&1)
ROUTER_DEPLOYED=$(echo "$ROUTER_TX" | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)
verify_deploy "UniversalRouter" "$ROUTER_DEPLOYED" "$UNIVERSAL_ROUTER_ADDR"

echo ""
echo "  All 8 contracts deployed ✓"

# ══════════════════════════════════════════════════════════════════════════
# PHASE 2: Create and initialise tBTC/USDT pool
# ══════════════════════════════════════════════════════════════════════════

# ── Determine token ordering (token0 = lower address) ────────────────────
# Uniswap V3 requires token0 < token1. The sqrtPriceX96 depends on ordering.

# Helper: returns "0" if $1 < $2 (hex comparison), else "1"
addr_lt() {
  local a
  a=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local b
  b=$(echo "$2" | tr '[:upper:]' '[:lower:]')
  if [ "$a" \< "$b" ]; then echo "0"; else echo "1"; fi
}

echo ""
echo "▶ Creating tBTC/USDT pool (fee=3000)..."

# Price: 1 tBTC = 70,000 USDT
# sqrtPriceX96 = sqrt(price_token1_per_token0_in_raw) * 2^96
if [ "$(addr_lt "$USDT_ADDRESS" "$TBTC_ADDRESS")" = "0" ]; then
  # USDT(6 dec) is token0, tBTC(18 dec) is token1
  # price = raw_tBTC / raw_USDT = 1e18 / (70000*1e6) ≈ 14285714.286
  POOL_T0="$USDT_ADDRESS"
  POOL_T1="$TBTC_ADDRESS"
  POOL_SQRT="299454306921933319110960707796992"
else
  # tBTC(18 dec) is token0, USDT(6 dec) is token1
  # price = raw_USDT / raw_tBTC = (70000*1e6) / 1e18 ≈ 0.00000007
  POOL_T0="$TBTC_ADDRESS"
  POOL_T1="$USDT_ADDRESS"
  POOL_SQRT="20961801484535330867511296"
fi

cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  "$FACTORY_ADDR" "createPool(address,address,uint24)(address)" \
  "$POOL_T0" "$POOL_T1" 3000 >/dev/null

TBTC_USDT_POOL=$(cast call --rpc-url "$RPC" \
  "$FACTORY_ADDR" "getPool(address,address,uint24)(address)" \
  "$TBTC_ADDRESS" "$USDT_ADDRESS" 3000)
TBTC_USDT_POOL=$(echo "$TBTC_USDT_POOL" | tr -d '[:space:]')
echo "  Pool: $TBTC_USDT_POOL"

echo "  Initialising (1 tBTC = 70,000 USDT)..."
cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  "$TBTC_USDT_POOL" "initialize(uint160)" "$POOL_SQRT" >/dev/null
echo "  ✓ tBTC/USDT pool initialised"

# ══════════════════════════════════════════════════════════════════════════
# PHASE 3: Seed liquidity
# ══════════════════════════════════════════════════════════════════════════

echo ""
echo "▶ Funding Uniswap deployer with tokens for liquidity..."

# Transfer MockUSDT and MockTBTC from main deployer (Account #1) to UNI deployer
USDT_LIQ="500000000000"              # 500k USDT (6 decimals)
TBTC_LIQ="10000000000000000000"      # 10 tBTC (18 decimals)

cast send --rpc-url "$RPC" --private-key "$DEPLOYER_PK" \
  "$USDT_ADDRESS" "transfer(address,uint256)" "$UNI_DEPLOYER" "$USDT_LIQ" >/dev/null
echo "  ✓ 500k USDT → $UNI_DEPLOYER"

cast send --rpc-url "$RPC" --private-key "$DEPLOYER_PK" \
  "$TBTC_ADDRESS" "transfer(address,uint256)" "$UNI_DEPLOYER" "$TBTC_LIQ" >/dev/null
echo "  ✓ 10 tBTC → $UNI_DEPLOYER"

# ── Approve tokens for NonfungiblePositionManager ─────────────────────────
MAX_UINT="115792089237316195423570985008687907853269984665640564039457584007913129639935"

echo "  Approving tokens for NonfungiblePositionManager..."
cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  "$USDT_ADDRESS" "approve(address,uint256)" "$NFT_POS_MGR" "$MAX_UINT" >/dev/null
cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  "$TBTC_ADDRESS" "approve(address,uint256)" "$NFT_POS_MGR" "$MAX_UINT" >/dev/null
echo "  ✓ Tokens approved"

# ── Add full-range liquidity ──────────────────────────────────────────────
# fee=3000 → tickSpacing=60 → min/max ticks rounded to spacing:
TICK_LOWER="-887220"   # = ceil(-887272 / 60) * 60
TICK_UPPER="887220"    # = floor(887272 / 60) * 60
DEADLINE="9999999999"

echo ""
echo "▶ Adding liquidity to tBTC/USDT pool..."

if [ "$(addr_lt "$USDT_ADDRESS" "$TBTC_ADDRESS")" = "0" ]; then
  # USDT is token0, tBTC is token1
  MINT_A0="$USDT_LIQ"
  MINT_A1="$TBTC_LIQ"
else
  MINT_A0="$TBTC_LIQ"
  MINT_A1="$USDT_LIQ"
fi

cast send --rpc-url "$RPC" --private-key "$UNI_PK" \
  "$NFT_POS_MGR" \
  "mint((address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256))(uint256,uint128,uint256,uint256)" \
  "($POOL_T0,$POOL_T1,3000,$TICK_LOWER,$TICK_UPPER,$MINT_A0,$MINT_A1,0,0,$UNI_DEPLOYER,$DEADLINE)" \
  >/dev/null
echo "  ✓ tBTC/USDT liquidity added"

# ── Verify pool has liquidity ─────────────────────────────────────────────
echo ""
echo "▶ Verifying pool..."

LIQ=$(cast call --rpc-url "$RPC" "$TBTC_USDT_POOL" "liquidity()(uint128)")
echo "  tBTC/USDT liquidity: $LIQ"

# ── Test: run a QuoterV2 quote ───────────────────────────────────────────
echo ""
echo "▶ Testing QuoterV2 quote (1 tBTC → USDT, fee=3000)..."
ONE_TBTC="1000000000000000000"
QUOTE_RESULT=$(cast call --rpc-url "$RPC" "$QUOTER_V2_ADDR" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($TBTC_ADDRESS,$USDT_ADDRESS,$ONE_TBTC,3000,0)" 2>&1 || echo "QUOTE_FAILED")

if echo "$QUOTE_RESULT" | grep -q "QUOTE_FAILED"; then
  echo "  ⚠ QuoterV2 quote failed (may indicate POOL_INIT_CODE_HASH mismatch)"
  echo "  Result: $QUOTE_RESULT"
else
  echo "  ✓ Quote result: $QUOTE_RESULT"
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo " Uniswap V3 Deployment Complete"
echo "═══════════════════════════════════════════════"
echo "  WETH9:                  $WETH_ADDR"
echo "  Multicall3:             $MULTICALL3_ADDR"
echo "  UniswapV3Factory:       $FACTORY_ADDR"
echo "  NonfungiblePosMgr:      $NFT_POS_MGR"
echo "  QuoterV2:               $QUOTER_V2_ADDR"
echo "  Permit2:                $PERMIT2_ADDR"
echo "  UnsupportedProtocol:    $UNSUPPORTED_ADDR"
echo "  UniversalRouter:        $UNIVERSAL_ROUTER_ADDR"
echo ""
echo "  tBTC/USDT pool (3000):  $TBTC_USDT_POOL"
echo "═══════════════════════════════════════════════"
