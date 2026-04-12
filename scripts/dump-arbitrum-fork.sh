#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# dump-arbitrum-fork.sh
#
# One-shot: spins up a disposable Anvil container that forks Arbitrum One
# mainnet, warms up the Uniswap V3 / Multicall3 / Permit2 contracts the
# Boltz quoter sidecar needs, then dumps the state for offline use.
#
# The output file can later be loaded with:
#   anvil --load-state docker/data/arbitrum-fork-state.json \
#         --host 0.0.0.0 --chain-id 412346
#
# Note: chain-id can be overridden at load time (e.g. 412346 for regtest)
# even though the state was captured from chain 42161 (Arbitrum One).
#
# Usage:
#   ./scripts/dump-arbitrum-fork.sh                            # public RPC
#   ARB_RPC_URL="https://arb-mainnet.g.alchemy.com/v2/KEY" \
#     ./scripts/dump-arbitrum-fork.sh                          # your own RPC
#
# Requirements: docker, curl
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# ── Config ────────────────────────────────────────────────────────────────────
CONTAINER="anvil-arb-fork-dump"
DUMP_FILE="arbitrum-fork-state.json"
DATA_DIR="$ROOT_DIR/docker/data"
HOST_PORT=18545                                          # avoid clashing with 8545/8546
ARB_CHAIN_ID=42161
ARB_RPC_URL="${ARB_RPC_URL:-https://arb1.arbitrum.io/rpc}"
FOUNDRY_IMAGE="${FOUNDRY_IMAGE:-ghcr.io/foundry-rs/foundry:latest}"
PLATFORM="${DOCKER_DEFAULT_PLATFORM:-linux/arm64}"

# ── Canonical Arbitrum One addresses ──────────────────────────────────────────
WETH="0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
USDT="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"
USDC="0xaf88d065e77c8cC2239327C5EDb3A432268e5831"       # native (Circle)
USDC_E="0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"     # bridged USDC.e
TBTC="0x6c84a8f1c29108F47a79964b5Fe888D4f4D0dE40"        # tBTC v2 (Threshold)
UNI_V3_FACTORY="0x1F98431c8aD98523631AE4a59f267346ea31F984"
QUOTER_V2="0x61fFE014bA17989E743c5F6cB21bF9697530B21e"
MULTICALL3="0xcA11bde05977b3631167028862bE2a173976CA11"
PERMIT2="0x000000000022D473030F116dDEE9F6B43aC78BA3"

# Internal RPC (inside the container)
INT_RPC="http://127.0.0.1:8545"

# ── Helpers ───────────────────────────────────────────────────────────────────
cleanup() {
  echo ""
  echo "🧹 Removing container $CONTAINER"
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Run cast inside the Anvil container (no host dependency on foundry)
cc() { docker exec "$CONTAINER" cast "$@" --rpc-url "$INT_RPC"; }

# Pretty-print a warm-up step
warm() {
  local label="$1"; shift
  printf "  %-30s " "$label"
  if "$@" >/dev/null 2>&1; then
    echo "✓"
  else
    echo "⚠  (call failed — code still cached)"
  fi
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "✗ docker not found"; exit 1
fi
if ! command -v curl &>/dev/null; then
  echo "✗ curl not found"; exit 1
fi

# Kill any leftover from a previous run
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
mkdir -p "$DATA_DIR"

# Make sure the host port is free
if curl -sf "http://localhost:$HOST_PORT" >/dev/null 2>&1; then
  echo "✗ Port $HOST_PORT is already in use — is a previous dump container still running?"
  exit 1
fi

# ── Start Anvil fork ─────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo " Arbitrum One fork → state dump"
echo "═══════════════════════════════════════════════════════════════"
echo "  RPC source:  $ARB_RPC_URL"
echo "  Image:       $FOUNDRY_IMAGE"
echo "  Container:   $CONTAINER"
echo "  Host port:   $HOST_PORT"
echo "  Output:      docker/data/$DUMP_FILE"
echo ""

echo "▶ Starting Anvil (forking Arbitrum One, chain $ARB_CHAIN_ID)..."
docker run -d \
  --name "$CONTAINER" \
  --platform "$PLATFORM" \
  -p "${HOST_PORT}:8545" \
  -v "$DATA_DIR:/data" \
  --entrypoint anvil \
  "$FOUNDRY_IMAGE" \
  --host 0.0.0.0 \
  --fork-url "$ARB_RPC_URL" \
  --chain-id "$ARB_CHAIN_ID" \
  >/dev/null

# ── Wait for ready ───────────────────────────────────────────────────────────
printf "⏳ Waiting for Anvil"
for i in $(seq 1 90); do
  if curl -sf "http://localhost:$HOST_PORT" \
       -X POST -H "Content-Type: application/json" \
       -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
       >/dev/null 2>&1; then
    echo ""
    BLOCK=$(docker exec "$CONTAINER" cast block-number --rpc-url "$INT_RPC" 2>/dev/null || echo "?")
    echo "✓ Anvil ready — forked at block $BLOCK"
    break
  fi
  printf "."
  sleep 1
  if [ "$i" -eq 90 ]; then
    echo ""
    echo "✗ Anvil failed to start within 90 s.  Logs:"
    docker logs --tail 20 "$CONTAINER"
    exit 1
  fi
done

# ── Warm up: tokens ──────────────────────────────────────────────────────────
# Anvil's fork dump only contains state that was accessed during the session.
# We call key functions on every contract the Boltz quoter sidecar checks at
# startup (check_contract_exists + actual quoting logic).
echo ""
echo "▶ Warming up token contracts..."
warm "WETH name"             cc call "$WETH" "name()(string)"
warm "WETH symbol"           cc call "$WETH" "symbol()(string)"
warm "WETH decimals"         cc call "$WETH" "decimals()(uint8)"
warm "WETH totalSupply"      cc call "$WETH" "totalSupply()(uint256)"

warm "USDT name"             cc call "$USDT" "name()(string)"
warm "USDT symbol"           cc call "$USDT" "symbol()(string)"
warm "USDT decimals"         cc call "$USDT" "decimals()(uint8)"
warm "USDT totalSupply"      cc call "$USDT" "totalSupply()(uint256)"

warm "USDC name"             cc call "$USDC" "name()(string)"
warm "USDC symbol"           cc call "$USDC" "symbol()(string)"
warm "USDC decimals"         cc call "$USDC" "decimals()(uint8)"

warm "USDC.e name"           cc call "$USDC_E" "name()(string)"
warm "USDC.e decimals"       cc call "$USDC_E" "decimals()(uint8)"

warm "tBTC name"             cc call "$TBTC" "name()(string)"
warm "tBTC symbol"           cc call "$TBTC" "symbol()(string)"
warm "tBTC decimals"         cc call "$TBTC" "decimals()(uint8)"
warm "tBTC totalSupply"      cc call "$TBTC" "totalSupply()(uint256)"

# ── Warm up: factory ─────────────────────────────────────────────────────────
echo ""
echo "▶ Warming up UniswapV3Factory..."
warm "Factory owner"         cc call "$UNI_V3_FACTORY" "owner()(address)"
warm "Factory fee 100"       cc call "$UNI_V3_FACTORY" "feeAmountTickSpacing(uint24)(int24)" 100
warm "Factory fee 500"       cc call "$UNI_V3_FACTORY" "feeAmountTickSpacing(uint24)(int24)" 500
warm "Factory fee 3000"      cc call "$UNI_V3_FACTORY" "feeAmountTickSpacing(uint24)(int24)" 3000
warm "Factory fee 10000"     cc call "$UNI_V3_FACTORY" "feeAmountTickSpacing(uint24)(int24)" 10000

# ── Warm up: discover & load pools ───────────────────────────────────────────
echo ""
echo "▶ Discovering pools..."

POOLS=""

discover_pool() {
  local label="$1" tA="$2" tB="$3" fee="$4"
  local pool
  pool=$(cc call "$UNI_V3_FACTORY" \
    "getPool(address,address,uint24)(address)" "$tA" "$tB" "$fee" 2>/dev/null || echo "")
  # strip whitespace
  pool=$(echo "$pool" | tr -d '[:space:]')
  if [ -n "$pool" ] && [ "$pool" != "0x0000000000000000000000000000000000000000" ]; then
    printf "  %-22s fee=%-5s → %s\n" "$label" "$fee" "$pool"
    POOLS="$POOLS $pool"
  fi
}

# Pairs × fee tiers likely used by the quoter
for FEE in 100 500 3000 10000; do
  discover_pool "WETH/USDT"   "$WETH"   "$USDT"   "$FEE"
  discover_pool "WETH/USDC"   "$WETH"   "$USDC"   "$FEE"
  discover_pool "USDC/USDT"   "$USDC"   "$USDT"   "$FEE"
  discover_pool "WETH/USDC.e" "$WETH"   "$USDC_E" "$FEE"
  discover_pool "USDC.e/USDT" "$USDC_E" "$USDT"   "$FEE"
  discover_pool "USDC/USDC.e" "$USDC"   "$USDC_E" "$FEE"
  discover_pool "WETH/tBTC"   "$WETH"   "$TBTC"   "$FEE"
  discover_pool "tBTC/USDT"   "$TBTC"   "$USDT"   "$FEE"
  discover_pool "tBTC/USDC"   "$TBTC"   "$USDC"   "$FEE"
done

POOL_COUNT=$(echo "$POOLS" | wc -w | tr -d ' ')
echo "  Found $POOL_COUNT pools"

echo ""
echo "▶ Warming pool state (slot0 + liquidity + tickBitmap)..."
for POOL in $POOLS; do
  SHORT="${POOL:0:10}…"
  warm "slot0    $SHORT"   cc call "$POOL" "slot0()(uint160,int24,uint16,uint16,uint16,uint8,bool)"
  warm "liquidity $SHORT"  cc call "$POOL" "liquidity()(uint128)"
  warm "fee       $SHORT"  cc call "$POOL" "fee()(uint24)"
  warm "token0    $SHORT"  cc call "$POOL" "token0()(address)"
  warm "token1    $SHORT"  cc call "$POOL" "token1()(address)"
  warm "tSpacing  $SHORT"  cc call "$POOL" "tickSpacing()(int24)"
done

# ── Warm up: QuoterV2 ────────────────────────────────────────────────────────
echo ""
echo "▶ Running QuoterV2 quotes (warms deep pool + tick state)..."
ONE_ETH="1000000000000000000"
ONE_USDT="1000000000"     # 1000 USDT (6 dec)

# Single-hop quotes
warm "Quote WETH→USDT 500"  cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($WETH,$USDT,$ONE_ETH,500,0)"

warm "Quote WETH→USDC 500"  cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($WETH,$USDC,$ONE_ETH,500,0)"

warm "Quote USDT→WETH 500"  cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($USDT,$WETH,$ONE_USDT,500,0)"

warm "Quote WETH→USDT 3000" cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($WETH,$USDT,$ONE_ETH,3000,0)"

warm "Quote WETH→USDC 3000" cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($WETH,$USDC,$ONE_ETH,3000,0)"

warm "Quote USDC→USDT 100"  cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($USDC,$USDT,$ONE_USDT,100,0)"

# tBTC quotes (multi-hop via WETH if no direct pool)
ONE_TBTC="100000000000000000"  # 0.1 tBTC (18 dec)
warm "Quote tBTC→WETH 3000" cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($TBTC,$WETH,$ONE_TBTC,3000,0)"

warm "Quote WETH→tBTC 3000" cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($WETH,$TBTC,$ONE_ETH,3000,0)"

warm "Quote tBTC→WETH 500"  cc call "$QUOTER_V2" \
  "quoteExactInputSingle((address,address,uint256,uint24,uint160))(uint256,uint160,uint32,uint256)" \
  "($TBTC,$WETH,$ONE_TBTC,500,0)"

# ── Warm up: infrastructure contracts ─────────────────────────────────────────
echo ""
echo "▶ Warming infrastructure contracts..."
warm "Multicall3 blockNumber" cc call "$MULTICALL3" "getBlockNumber()(uint256)"
warm "Multicall3 blockHash"   cc call "$MULTICALL3" "getLastBlockHash()(bytes32)"
warm "Permit2 code"           cc code "$PERMIT2"

# ── Dump state via RPC ────────────────────────────────────────────────────────
# `--dump-state` only captures the local delta (modified accounts), not forked
# state.  The `anvil_dumpState` RPC method captures EVERYTHING that was accessed
# from the fork — bytecodes, storage slots, the lot.
echo ""
echo "▶ Dumping full state via anvil_dumpState RPC (this may take a moment)..."

# anvil_dumpState returns a hex-encoded blob; we save the raw JSON response.
DUMP_RESPONSE=$(curl -sf "http://localhost:$HOST_PORT" \
  -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"anvil_dumpState","params":[],"id":1}')

if [ -z "$DUMP_RESPONSE" ]; then
  echo "✗ anvil_dumpState returned empty response"
  docker logs --tail 20 "$CONTAINER" 2>/dev/null || true
  exit 1
fi

# Extract the hex result and write it to the dump file
HEX_STATE=$(echo "$DUMP_RESPONSE" | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"])' 2>/dev/null || true)

if [ -z "$HEX_STATE" ] || [ "$HEX_STATE" = "null" ]; then
  echo "✗ Failed to extract state from anvil_dumpState response"
  echo "  Response (first 500 chars): ${DUMP_RESPONSE:0:500}"
  exit 1
fi

# Save as a JSON file that anvil_loadState can consume
echo "$HEX_STATE" > "$DATA_DIR/$DUMP_FILE"

# Stop the container now — we already have the dump
echo "▶ Stopping Anvil container..."
docker stop --time 10 "$CONTAINER" >/dev/null 2>&1 || true

# ── Verify ────────────────────────────────────────────────────────────────────
if [ -f "$DATA_DIR/$DUMP_FILE" ]; then
  SIZE=$(du -h "$DATA_DIR/$DUMP_FILE" | cut -f1)
  # Quick sanity: file should be at least 100 KB for a real fork dump
  SIZE_BYTES=$(wc -c < "$DATA_DIR/$DUMP_FILE" | tr -d ' ')
  if [ "$SIZE_BYTES" -lt 100000 ]; then
    echo ""
    echo "⚠  State file is suspiciously small ($SIZE / $SIZE_BYTES bytes)."
    echo "   The fork state may not have been captured properly."
    echo "   First 200 chars: $(head -c 200 "$DATA_DIR/$DUMP_FILE")"
    exit 1
  fi
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo " ✅  State dumped successfully"
  echo ""
  echo "   File:  docker/data/$DUMP_FILE  ($SIZE)"
  echo "   Block: $BLOCK  (Arbitrum One)"
  echo ""
  echo " To load offline (standalone):"
  echo "   anvil --host 0.0.0.0 --chain-id 412346"
  echo "   # then in another shell:"
  echo "   curl -X POST http://localhost:8545 \\"
  echo '     -H "Content-Type: application/json" \'
  echo '     -d "{\"jsonrpc\":\"2.0\",\"method\":\"anvil_loadState\",'
  echo '          \"params\":[\"$(cat docker/data/'"$DUMP_FILE"')\"],\"id\":1}"'
  echo ""
  echo " Addresses baked into this dump:"
  echo "   WETH           $WETH"
  echo "   USDT           $USDT"
  echo "   USDC           $USDC"
  echo "   USDC.e         $USDC_E"
  echo "   tBTC           $TBTC"
  echo "   V3 Factory     $UNI_V3_FACTORY"
  echo "   QuoterV2       $QUOTER_V2"
  echo "   Multicall3     $MULTICALL3"
  echo "   Permit2        $PERMIT2"
  echo "═══════════════════════════════════════════════════════════════"
else
  echo ""
  echo "✗ State file not found at docker/data/$DUMP_FILE"
  docker logs --tail 20 "$CONTAINER" 2>/dev/null || true
  exit 1
fi
