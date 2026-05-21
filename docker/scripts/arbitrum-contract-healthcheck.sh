#!/bin/sh
# Verifies that the local Arbitrum RPC is reachable and the deterministic
# contracts deployed by arbitrum-init are present on-chain.
set -eu

RPC_URL="${ARBITRUM_HEALTHCHECK_RPC_URL:-http://127.0.0.1:8545}"
EXPECTED_CHAIN_ID="${ARBITRUM_HEALTHCHECK_CHAIN_ID:-412346}"

ETHERSWAP_ADDRESS="${ARBITRUM_HEALTHCHECK_ETHERSWAP_ADDRESS:-0x8464135c8F25Da09e49BC8782676a84730C318bC}"
ERC20SWAP_ADDRESS="${ARBITRUM_HEALTHCHECK_ERC20SWAP_ADDRESS:-0x71C95911E9a5D330f4D621842EC243EE1343292e}"
TBTC_ADDRESS="${ARBITRUM_HEALTHCHECK_TBTC_ADDRESS:-0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F}"
USDT_ADDRESS="${ARBITRUM_HEALTHCHECK_USDT_ADDRESS:-0x712516e61C8B383dF4A63CFe83d7701Bce54B03e}"
WETH_ADDRESS="${ARBITRUM_HEALTHCHECK_WETH_ADDRESS:-0x057ef64E23666F000b34aE31332854aCBd1c8544}"
MULTICALL3_ADDRESS="${ARBITRUM_HEALTHCHECK_MULTICALL3_ADDRESS:-0x261D8c5e9742e6f7f1076Fa1F560894524e19cad}"
UNISWAP_FACTORY_ADDRESS="${ARBITRUM_HEALTHCHECK_UNISWAP_FACTORY_ADDRESS:-0xCE3478A9E0167a6Bc5716DC39DbbbfAc38F27623}"
NFT_POSITION_MANAGER_ADDRESS="${ARBITRUM_HEALTHCHECK_NFT_POSITION_MANAGER_ADDRESS:-0xCba6b9A951749B8735C603e7fFC5151849248772}"
QUOTER_V2_ADDRESS="${ARBITRUM_HEALTHCHECK_QUOTER_V2_ADDRESS:-0xe4EB561155AFCe723bB1fF8606Fbfe9b28d5d38D}"
PERMIT2_ADDRESS="${ARBITRUM_HEALTHCHECK_PERMIT2_ADDRESS:-0xcf27F781841484d5CF7e155b44954D7224caF1dD}"
UNSUPPORTED_PROTOCOL_ADDRESS="${ARBITRUM_HEALTHCHECK_UNSUPPORTED_PROTOCOL_ADDRESS:-0x673cD70FA883394a1f3DEb3221937Ceb7C2618D7}"
UNIVERSAL_ROUTER_ADDRESS="${ARBITRUM_HEALTHCHECK_UNIVERSAL_ROUTER_ADDRESS:-0x6179FBb91b239b574A4565e2c55A6fD38C3372d3}"

normalize_address() {
  echo "$1" | tr -d '[:space:]' | sed 's/^0x000000000000000000000000/0x/' | tr '[:upper:]' '[:lower:]'
}

is_zero_address() {
  local address
  address="$(normalize_address "$1")"
  [ -z "$address" ] || [ "$address" = "0x" ] || [ "$address" = "0x0000000000000000000000000000000000000000" ]
}

require_code() {
  local name="$1"
  local address="$2"
  local code

  code="$(cast code --rpc-url "$RPC_URL" "$address" 2>/dev/null || true)"
  code="$(echo "$code" | tr -d '[:space:]')"

  if [ -z "$code" ] || [ "$code" = "0x" ]; then
    echo "missing contract code: $name ($address)"
    exit 1
  fi
}

CHAIN_ID="$(cast chain-id --rpc-url "$RPC_URL" 2>/dev/null || true)"
CHAIN_ID="$(echo "$CHAIN_ID" | tr -d '[:space:]')"
if [ "$CHAIN_ID" != "$EXPECTED_CHAIN_ID" ]; then
  echo "unexpected or unavailable Arbitrum chain id: ${CHAIN_ID:-<none>} (expected $EXPECTED_CHAIN_ID)"
  exit 1
fi

require_code "EtherSwap" "$ETHERSWAP_ADDRESS"
require_code "ERC20Swap" "$ERC20SWAP_ADDRESS"
require_code "MockTBTC" "$TBTC_ADDRESS"
require_code "MockUSDT" "$USDT_ADDRESS"
require_code "WETH9" "$WETH_ADDRESS"
require_code "Multicall3" "$MULTICALL3_ADDRESS"
require_code "UniswapV3Factory" "$UNISWAP_FACTORY_ADDRESS"
require_code "NonfungiblePositionManager" "$NFT_POSITION_MANAGER_ADDRESS"
require_code "QuoterV2" "$QUOTER_V2_ADDRESS"
require_code "Permit2" "$PERMIT2_ADDRESS"
require_code "UnsupportedProtocol" "$UNSUPPORTED_PROTOCOL_ADDRESS"
require_code "UniversalRouter" "$UNIVERSAL_ROUTER_ADDRESS"

TBTC_USDT_POOL="$(cast call --rpc-url "$RPC_URL" \
  "$UNISWAP_FACTORY_ADDRESS" "getPool(address,address,uint24)(address)" \
  "$TBTC_ADDRESS" "$USDT_ADDRESS" 3000 2>/dev/null || true)"

if is_zero_address "$TBTC_USDT_POOL"; then
  echo "missing Uniswap V3 tBTC/USDT pool"
  exit 1
fi

require_code "UniswapV3 tBTC/USDT pool" "$(normalize_address "$TBTC_USDT_POOL")"
