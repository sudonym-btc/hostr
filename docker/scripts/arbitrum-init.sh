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

ARBITRUM_RPC="http://anvil-arbitrum:8545"

# Anvil Account #1 — deployer for swap contracts (deterministic addresses)
DEPLOYER_PK="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

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
mkdir -p /tmp/tbtc/src

cat > /tmp/tbtc/src/MockTBTC.sol << 'SOLEOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockTBTC {
    // Storage layout matches OpenZeppelin ERC20:
    //   slot 0 → balanceOf, slot 1 → allowance
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name     = "tBTC";
    string public symbol   = "tBTC";
    uint8  public decimals = 18;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _supply) {
        totalSupply = _supply;
        balanceOf[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
SOLEOF

cat > /tmp/tbtc/foundry.toml << 'FEOF'
[profile.default]
src = "src"
out = "out"
FEOF

cd /tmp/tbtc
TBTC_SUPPLY="1000000000000000000000000"  # 1M tBTC (18 decimals)
FORGE_OUTPUT=$(forge create src/MockTBTC.sol:MockTBTC \
  --rpc-url "$ARBITRUM_RPC" \
  --private-key "$DEPLOYER_PK" \
  --broadcast \
  --constructor-args "$TBTC_SUPPLY" 2>&1)
echo "$FORGE_OUTPUT"

# Extract deployed address from forge output
TBTC_ADDRESS=$(echo "$FORGE_OUTPUT" | grep -i "Deployed to:" | awk '{print $NF}')
if [ -z "$TBTC_ADDRESS" ]; then
  echo "ERROR: Failed to extract MockTBTC address from forge create output"
  exit 1
fi

# Verify contract code exists at the deployed address
CODE=$(cast code --rpc-url "$ARBITRUM_RPC" "$TBTC_ADDRESS")
if [ "$CODE" = "0x" ] || [ -z "$CODE" ]; then
  echo "ERROR: No contract code at MockTBTC address $TBTC_ADDRESS"
  exit 1
fi

EXPECTED_ADDRESS="0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F"
if [ "$TBTC_ADDRESS" != "$EXPECTED_ADDRESS" ]; then
  echo "WARNING: MockTBTC deployed at $TBTC_ADDRESS (expected $EXPECTED_ADDRESS)"
  echo "         Update docker/boltz.conf contractAddress if this persists!"
fi

# ── 3. Deploy MockUSDT ERC20 (nonce 3) ───────────────────────────────────
echo "Deploying MockUSDT..."

cat > /tmp/tbtc/src/MockUSDT.sol << 'SOLEOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockUSDT {
    // Storage layout matches OpenZeppelin ERC20:
    //   slot 0 → balanceOf, slot 1 → allowance
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name     = "Tether USD";
    string public symbol   = "USDT";
    uint8  public decimals = 6;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _supply) {
        totalSupply = _supply;
        balanceOf[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
SOLEOF

USDT_SUPPLY="1000000000000"  # 1M USDT (6 decimals)
FORGE_OUTPUT_USDT=$(forge create src/MockUSDT.sol:MockUSDT \
  --rpc-url "$ARBITRUM_RPC" \
  --private-key "$DEPLOYER_PK" \
  --broadcast \
  --constructor-args "$USDT_SUPPLY" 2>&1)
echo "$FORGE_OUTPUT_USDT"

USDT_ADDRESS=$(echo "$FORGE_OUTPUT_USDT" | grep -i "Deployed to:" | awk '{print $NF}')
if [ -z "$USDT_ADDRESS" ]; then
  echo "ERROR: Failed to extract MockUSDT address from forge create output"
  exit 1
fi

CODE=$(cast code --rpc-url "$ARBITRUM_RPC" "$USDT_ADDRESS")
if [ "$CODE" = "0x" ] || [ -z "$CODE" ]; then
  echo "ERROR: No contract code at MockUSDT address $USDT_ADDRESS"
  exit 1
fi

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
    "$TBTC_ADDRESS" "transfer(address,uint256)" "$ACCT" "$TBTC_AMOUNT"
  echo "  Sending 100k USDT to $ACCT"
  cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" \
    "$USDT_ADDRESS" "transfer(address,uint256)" "$ACCT" "$USDT_AMOUNT"
done

# Fund explicit boltz wallet if specified
if [ -n "${BOLTZ_WALLET_ADDRESS:-}" ]; then
  echo "  Sending 100k tBTC to boltz wallet $BOLTZ_WALLET_ADDRESS"
  cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" \
    "$TBTC_ADDRESS" "transfer(address,uint256)" "$BOLTZ_WALLET_ADDRESS" "$TBTC_AMOUNT"

  echo "  Sending 100k USDT to boltz wallet $BOLTZ_WALLET_ADDRESS"
  cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PK" \
    "$USDT_ADDRESS" "transfer(address,uint256)" "$BOLTZ_WALLET_ADDRESS" "$USDT_AMOUNT"

  # Also send native ETH/ARB for gas
  echo "  Sending 1000 ETH to boltz wallet for gas"
  cast send --rpc-url "$ARBITRUM_RPC" \
    --private-key "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" \
    --value 1000ether "$BOLTZ_WALLET_ADDRESS"
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
