# Boltz Arbitrum Regtest: Required Changes

> **Constraint:** No files inside `dependencies/` are modified. All changes are
> done via Compose overrides, Hostr-owned config files, and init containers.

## Overview

Adding Arbitrum chain support to the Boltz regtest stack requires:

1. A **second Anvil** instance (`anvil-arbitrum`, chain-id `412346`)
2. An **init container** (`arbitrum-init`) that deploys EtherSwap, ERC20Swap, and a **mock tBTC** ERC20 token to the new chain
3. A **custom `boltz.conf`** (`docker/boltz.conf`) mounted over the submodule default, adding the `[arbitrum]` section with native (ARB) + ERC20 (tBTC) tokens
4. **Pair configuration** for ARB/BTC, tBTC/BTC (and optionally ARB/L-BTC, tBTC/L-BTC)

The boltz-backend already has first-class Arbitrum support — `ArbitrumConfig` extends `EthereumConfig` (adding the required `l1Providers` field) in TypeScript, and uses the same `boltz_evm::Config` on the Rust sidecar side.

---

## 1. New Docker Service: `anvil-arbitrum`

**Where:** `compose.boltz.yaml` (override — new service definition)

```yaml
services:
  anvil-arbitrum:
    hostname: anvil-arbitrum
    container_name: boltz-anvil-arbitrum
    image: ${FOUNDRY_IMAGE:-ghcr.io/foundry-rs/foundry:latest}
    platform: ${DOCKER_DEFAULT_PLATFORM:-linux/arm64}
    entrypoint: "anvil --host 0.0.0.0 --chain-id 412346"
    ports:
      - 8546:8545
    healthcheck:
      test: ["CMD-SHELL", "timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/8545'"]
      timeout: 1s
      retries: 3
      interval: 1s
      start_period: 0s
    profiles: ["default", "ci", "backend-dev", "webapp-ci"]
```

**Notes:**

- Chain ID `412346` matches the existing `ESCROW_CONTRACT_ADDRESS_KEY=regtest.412346` already used by the escrow service in `compose.yaml`.
- The chain ID is **auto-detected** by boltz-backend from the RPC — it is NOT configured in `boltz.conf`.
- Exposed on host port `8546` to avoid conflict with the existing RSK anvil on `8545`.

---

## 2. Contract & tBTC Deployment (Init Container)

**Where:** `compose.boltz.yaml` (new `arbitrum-init` service) + `docker/scripts/arbitrum-init.sh` (new script)

Since we cannot modify `dependencies/boltz-regtest/images/scripts/utils.sh`, we run a **separate init container** based on the Foundry image that:

1. Deploys **EtherSwap** (nonce 0) and **ERC20Swap** (nonce 1) using the same bytecodes the submodule uses
2. Deploys a **mock tBTC** ERC20 token (nonce 2)
3. Optionally funds the boltz wallet with tBTC

### 2a. Deterministic addresses

Contract addresses are derived from `keccak256(rlp(sender, nonce))`. On a fresh Anvil, all accounts start at nonce 0, so deploying with Anvil Account #1 (`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`, private key `0x59c6995e…`) produces **identical addresses** regardless of chain-id:

| Nonce | Contract  | Address                                      |
| ----- | --------- | -------------------------------------------- |
| 0     | EtherSwap | `0x8464135c8F25Da09e49BC8782676a84730C318bC` |
| 1     | ERC20Swap | `0x71C95911E9a5D330f4D621842EC243EE1343292e` |
| 2     | MockTBTC  | `0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F` |

### 2b. Mock tBTC ERC20 Token

The mock token needs to be a standard ERC20 with `transfer`, `approve`, `transferFrom`, and `balanceOf`. The simplest approach is to compile a minimal Solidity contract inline using `forge` (available in the Foundry image).

The init script (`docker/scripts/arbitrum-init.sh`) will:

```bash
#!/bin/bash
set -euo pipefail

RPC_URL="http://anvil-arbitrum:8545"
# Anvil Account #1 — deployer for swap contracts (keeps same deterministic addresses)
DEPLOYER_PK="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
# Anvil Account #0 — used for funding operations
FUNDER_PK="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

echo "Waiting for anvil-arbitrum..."
until cast chain-id --rpc-url "$RPC_URL" 2>/dev/null; do sleep 0.5; done

# ── 1. Deploy EtherSwap (nonce 0) ──
echo "Deploying EtherSwap..."
cast send --rpc-url "$RPC_URL" --private-key "$DEPLOYER_PK" --create "$ETHERSWAP_BYTECODE"

# ── 2. Deploy ERC20Swap (nonce 1) ──
echo "Deploying ERC20Swap..."
cast send --rpc-url "$RPC_URL" --private-key "$DEPLOYER_PK" --create "$ERC20SWAP_BYTECODE"

# ── 3. Deploy MockTBTC ERC20 (nonce 2) ──
echo "Deploying MockTBTC..."
mkdir -p /tmp/tbtc/src
cat > /tmp/tbtc/src/MockTBTC.sol << 'SOLEOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockTBTC {
    string public name     = "tBTC";
    string public symbol   = "tBTC";
    uint8  public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

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
forge create src/MockTBTC.sol:MockTBTC \
  --rpc-url "$RPC_URL" \
  --private-key "$DEPLOYER_PK" \
  --constructor-args "$TBTC_SUPPLY"

TBTC_ADDRESS="0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F"

echo "EtherSwap:  0x8464135c8F25Da09e49BC8782676a84730C318bC"
echo "ERC20Swap:  0x71C95911E9a5D330f4D621842EC243EE1343292e"
echo "MockTBTC:   $TBTC_ADDRESS"

# ── 4. (Optional) Fund boltz wallet with tBTC ──
# Boltz derives its EVM wallet from the seed mnemonic.
# If BOLTZ_WALLET_ADDRESS is set, transfer tBTC to it.
if [ -n "${BOLTZ_WALLET_ADDRESS:-}" ]; then
  echo "Funding boltz wallet $BOLTZ_WALLET_ADDRESS with tBTC..."
  cast send --rpc-url "$RPC_URL" --private-key "$DEPLOYER_PK" \
    "$TBTC_ADDRESS" "transfer(address,uint256)" \
    "$BOLTZ_WALLET_ADDRESS" "500000000000000000000000"  # 500k tBTC
fi

echo "Arbitrum init complete."
```

### 2c. Compose service definition

```yaml
services:
  arbitrum-init:
    image: ${FOUNDRY_IMAGE:-ghcr.io/foundry-rs/foundry:latest}
    platform: ${DOCKER_DEFAULT_PLATFORM:-linux/arm64}
    container_name: boltz-arbitrum-init
    restart: "no"
    depends_on:
      anvil-arbitrum:
        condition: service_healthy
    volumes:
      - ./docker/scripts/arbitrum-init.sh:/scripts/arbitrum-init.sh:ro
    entrypoint: ["/bin/bash", "/scripts/arbitrum-init.sh"]
    environment:
      # The EtherSwap and ERC20Swap bytecodes are the same huge hex blobs
      # from dependencies/boltz-regtest/images/scripts/utils.sh.
      # They are passed as env vars to avoid duplicating in the script.
      # See "Bytecode Sourcing" section below.
      - ETHERSWAP_BYTECODE=${ETHERSWAP_BYTECODE}
      - ERC20SWAP_BYTECODE=${ERC20SWAP_BYTECODE}
      - BOLTZ_WALLET_ADDRESS=${BOLTZ_WALLET_ADDRESS:-}
    profiles: ["default", "ci", "backend-dev", "webapp-ci"]
```

### 2d. Bytecode sourcing

The EtherSwap and ERC20Swap bytecodes are enormous hex blobs currently hardcoded in `dependencies/boltz-regtest/images/scripts/utils.sh`. Since we cannot edit that file, we have two options:

**Option A — Env vars in `.env.local` / `.env.test`:**
Copy the two hex blobs from `utils.sh` into env vars `ETHERSWAP_BYTECODE` and `ERC20SWAP_BYTECODE`. This keeps the init script clean but makes the `.env` files huge.

**Option B — Read from the submodule at build time:**
Create a small helper script that `grep`s the bytecodes from `utils.sh` and exports them:

```bash
# In docker/scripts/extract-bytecodes.sh (run once / sourced by restart.sh)
ETHERSWAP_BYTECODE=$(sed -n '/# EtherSwap/{n;s/.*deploy_contract //;p}' \
  dependencies/boltz-regtest/images/scripts/utils.sh)
ERC20SWAP_BYTECODE=$(sed -n '/# ERC20Swap/{n;s/.*deploy_contract //;p}' \
  dependencies/boltz-regtest/images/scripts/utils.sh)
export ETHERSWAP_BYTECODE ERC20SWAP_BYTECODE
```

**Option C (simplest) — Mount `utils.sh` read-only and source it:**
Mount the submodule script into `arbitrum-init` and reuse its `deploy_contract` function:

```yaml
arbitrum-init:
  volumes:
    - ./docker/scripts/arbitrum-init.sh:/scripts/arbitrum-init.sh:ro
    - ./dependencies/boltz-regtest/images/scripts/utils.sh:/scripts/utils.sh:ro
```

Then in the init script:

```bash
source /scripts/utils.sh
# Override RPC URL for our chain
deploy_contract() {
  cast send --rpc-url http://anvil-arbitrum:8545 \
    --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
    --create $1
}
deploy_contracts  # reuses the bytecodes from utils.sh
```

This reads `dependencies/` **read-only** without modifying it.

---

## 3. Startup Dependencies

**Where:** `compose.boltz.yaml` (overrides only)

```yaml
services:
  # regtest-start needs anvil-arbitrum healthy before it runs
  regtest-start:
    depends_on:
      anvil-arbitrum:
        condition: service_healthy

  # boltz-backend needs arbitrum-init completed (contracts deployed)
  boltz-backend:
    depends_on:
      arbitrum-init:
        condition: service_completed_successfully
```

Docker Compose merges `depends_on` maps — the override adds to existing deps without removing the upstream ones (`regtest-start`, `postgres`).

---

## 4. boltz.conf Override

**Where:** `docker/boltz.conf` (already exists, currently unused) → mount into boltz-backend

### 4a. Uncomment volume mount in `compose.boltz.yaml`

The mount is already present but commented out:

```yaml
boltz-backend:
  volumes:
    - ./docker/boltz.conf:/boltz-data/boltz.conf:ro
```

This file-level mount takes precedence over the directory-level `boltz-data` volume for this one file.

### 4b. Fix the `docker/boltz.conf`

The current file has an incorrect `[arb]` section. The correct TOML key is **`[arbitrum]`** — matching the Rust struct field `pub arbitrum: Option<boltz_evm::Config>` and TypeScript's `ConfigType.arbitrum?: ArbitrumConfig`.

Replace the `[arb]` section with:

```toml
[arbitrum]
providerEndpoint = "ws://anvil-arbitrum:8545"

  [[arbitrum.l1Providers]]
  # REQUIRED — boltz-backend uses L1 block height for Arbitrum locktime.
  # In regtest, the RSK anvil acts as a stand-in "L1".
  endpoint = "ws://anvil:8545"

  [[arbitrum.contracts]]
  etherSwap = "0x8464135c8F25Da09e49BC8782676a84730C318bC"
  erc20Swap = "0x71C95911E9a5D330f4D621842EC243EE1343292e"

  # Native token (gas token)
  [[arbitrum.tokens]]
  symbol = "ARB"
  maxSwapAmount = 4_294_96700
  minSwapAmount = 10000
  minWalletBalance = 100_000_000

  # ERC20 token: mock tBTC
  [[arbitrum.tokens]]
  symbol = "tBTC"
  decimals = 18
  contractAddress = "0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F"
  maxSwapAmount = 4_294_96700
  minSwapAmount = 10000
  minWalletBalance = 100_000_000
```

### 4c. Critical config details

| Key                    | Notes                                                                                                                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `[arbitrum]`           | **Not** `[arb]`. Must match the struct field name in both TS and Rust.                                                                                                                                        |
| `l1Providers`          | **REQUIRED** even in regtest. `ArbitrumConfig` extends `EthereumConfig` with `l1Providers: ProviderConfig[]`. Boltz uses L1 block numbers for locktime. In regtest, pointing to the existing RSK anvil works. |
| `l1Providers.endpoint` | The `ProviderConfig` type uses `endpoint`, not `providerEndpoint`.                                                                                                                                            |
| `networkName`          | Optional — defaults to `"Arbitrum"`.                                                                                                                                                                          |
| Native token symbol    | Must be `"ARB"` — matches `networks.Arbitrum.symbol` in `lib/wallet/ethereum/EvmNetworks.ts`.                                                                                                                 |
| tBTC `contractAddress` | Present → boltz treats it as ERC20 (creates `ERC20WalletProvider`). Absent → native token.                                                                                                                    |
| tBTC `decimals`        | Required when `contractAddress` is set. Standard 18 for tBTC.                                                                                                                                                 |

---

## 5. Pair Configuration

**Where:** `docker/boltz.conf`

Add pairs for ARB (native) and tBTC (ERC20):

```toml
# ── ARB / BTC ──
[[pairs]]
base = "ARB"
quote = "BTC"
rate = 1
fee = 0.25
swapInFee = 0.1
maxSwapAmount = 4_294_967
minSwapAmount = 50_000

  [pairs.timeoutDelta]
  chain = 1440
  reverse = 1440
  swapMinimal = 1440
  swapMaximal = 2880
  swapTaproot = 10080

# ── tBTC / BTC  (the key swap-in pair) ──
[[pairs]]
base = "tBTC"
quote = "BTC"
rate = 1
fee = 0.25
swapInFee = 0.1
maxSwapAmount = 4_294_967
minSwapAmount = 50_000

  [pairs.timeoutDelta]
  chain = 1440
  reverse = 1440
  swapMinimal = 1440
  swapMaximal = 2880
  swapTaproot = 10080

# ── ARB / L-BTC (chain swaps only) ──
[[pairs]]
base = "ARB"
quote = "L-BTC"
rate = 1
fee = 0.25
swapInFee = 0.1
maxSwapAmount = 10_000_000
minSwapAmount = 2_500
swapTypes = ["chain"]

  [pairs.chainSwap]
  buyFee = 0.1
  sellFee = 0.1
  minSwapAmount = 25_000

  [pairs.timeoutDelta]
  chain = 1440
  reverse = 1440
  swapMinimal = 1440
  swapMaximal = 2880
  swapTaproot = 10080

# ── tBTC / L-BTC (chain swaps only) ──
[[pairs]]
base = "tBTC"
quote = "L-BTC"
rate = 1
fee = 0.25
swapInFee = 0.1
maxSwapAmount = 10_000_000
minSwapAmount = 2_500
swapTypes = ["chain"]

  [pairs.chainSwap]
  buyFee = 0.1
  sellFee = 0.1
  minSwapAmount = 25_000

  [pairs.timeoutDelta]
  chain = 1440
  reverse = 1440
  swapMinimal = 1440
  swapMaximal = 2880
  swapTaproot = 10080
```

---

## 6. Deferred Claims

**Where:** `docker/boltz.conf`

Add `"ARB"` and `"tBTC"` to the `deferredClaimSymbols` list:

```toml
[swap]
deferredClaimSymbols = ["BTC", "L-BTC", "RBTC", "ARB", "tBTC"]
```

---

## 7. Wallet Funding

Boltz-backend derives its EVM wallet from the mnemonic seed (`test test test test test test test test test test test junk`). Anvil pre-funds its default 10 accounts with 10,000 ETH each for native gas.

**Native (ARB):** If the derived wallet is one of Anvil's 10 pre-funded accounts, it already has 10k ETH. If not, the `arbitrum-init` script should fund it via `cast send --value`.

**ERC20 (tBTC):** The mock tBTC is minted entirely to Account #1 (the deployer). The `arbitrum-init` script transfers tBTC to the boltz wallet via the `BOLTZ_WALLET_ADDRESS` env var. Additionally, boltz-backend's `EthereumManager.init()` automatically calls `approve(erc20Swap, MAX_UINT256)` on the ERC20 for each contract version, so no manual approval is needed.

---

## 8. Mock tBTC Token — How It Works End-to-End

```
┌──────────────────────────────────────────────────────┐
│  arbitrum-init container (runs once at startup)      │
│                                                      │
│  1. cast send --create  → EtherSwap   (nonce 0)     │
│  2. cast send --create  → ERC20Swap   (nonce 1)     │
│  3. forge create        → MockTBTC    (nonce 2)     │
│     └─ 1M tBTC minted to deployer (Account #1)      │
│  4. transfer 500k tBTC → boltz wallet               │
└──────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│  boltz-backend reads docker/boltz.conf               │
│                                                      │
│  [arbitrum]                                          │
│    providerEndpoint = "ws://anvil-arbitrum:8545"     │
│    [[arbitrum.tokens]]                               │
│      symbol = "tBTC"                                 │
│      contractAddress = "0x948B3c65..."               │
│      decimals = 18                                   │
│                                                      │
│  EthereumManager.init() →                            │
│    Creates ERC20WalletProvider for tBTC              │
│    Sets max allowance on ERC20Swap contract          │
│    Registers tBTC as CurrencyType.ERC20              │
└──────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│  Swap flow: tBTC → BTC (submarine swap-in)           │
│                                                      │
│  User calls:                                         │
│    POST /v2/swap/submarine  { from: "tBTC",          │
│                                to: "BTC", ... }      │
│                                                      │
│  User locks tBTC into ERC20Swap on anvil-arbitrum    │
│  Boltz claims tBTC via ERC20Swap.claim()             │
│  Boltz pays BTC invoice on Lightning                 │
└──────────────────────────────────────────────────────┘
```

---

## Summary of Files to Change

| File                              | Change                                                                                                                                                   |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `compose.boltz.yaml`              | Add `anvil-arbitrum` service, `arbitrum-init` service, depends_on overrides for `regtest-start` and `boltz-backend`, uncomment `boltz.conf` volume mount |
| `docker/boltz.conf`               | Fix `[arb]` → `[arbitrum]`, point to `anvil-arbitrum`, add `l1Providers`, add tBTC token config, add ARB+tBTC pairs, update `deferredClaimSymbols`       |
| `docker/scripts/arbitrum-init.sh` | **New file.** Deploys EtherSwap + ERC20Swap + MockTBTC to anvil-arbitrum, funds boltz wallet with tBTC                                                   |
| `.env.local` / `.env.test`        | Add `ETHERSWAP_BYTECODE`, `ERC20SWAP_BYTECODE`, `BOLTZ_WALLET_ADDRESS` (if using Option A for bytecodes)                                                 |

> **No files in `dependencies/` are modified.** The submodule is read-only (at most mounted as a volume for reading bytecodes).

---

## Architecture Diagram

```
┌─────────────────────────┐     ┌──────────────────────────────┐
│   anvil (chain-id 33)   │     │  anvil-arbitrum (chain-id    │
│   Rootstock regtest     │     │  412346) Arbitrum regtest    │
│                         │     │                              │
│ EtherSwap: 0x8464...   │     │ EtherSwap: 0x8464...         │
│ ERC20Swap: 0x71C9...   │     │ ERC20Swap: 0x71C9...         │
│                         │     │ MockTBTC:  0x948B...         │
│                         │     │                              │
└────────┬────────────────┘     └────────┬─────────────────────┘
         │                               │
         │  ws://anvil:8545              │  ws://anvil-arbitrum:8545
         │  (also serves as L1)          │
         │                               │
         └───────────┬───────────────────┘
                     │
              ┌──────┴──────┐
              │   boltz-    │
              │  backend    │
              │             │
              │ [rsk]  ───────► anvil:8545       → RBTC
              │ [arbitrum] ───► anvil-arb:8545   → ARB + tBTC
              │   └─ l1Providers ─► anvil:8545
              └─────────────┘
              reads: docker/boltz.conf (mounted ro)
```

---

## Risks & Considerations

1. **l1Providers in regtest**: Using the RSK anvil as the "L1" for Arbitrum is a hack — in production, this would be Ethereum mainnet. In regtest it works because boltz just needs _some_ block height that advances. If it causes issues, spin up a third anvil dedicated to being "L1".

2. **Bytecode drift**: The EtherSwap/ERC20Swap bytecodes in `utils.sh` may change when the boltz-regtest submodule is updated. Option C (mounting `utils.sh` read-only and sourcing it) is the most resilient to this. Options A/B require manual syncing.

3. **tBTC contract address stability**: The MockTBTC address (`0x948B3c65…`) is deterministic as long as it's the 3rd contract deployed by Account #1 (nonce 2). If the deployment order changes (e.g., adding another contract before tBTC), the address changes and `boltz.conf` must be updated.

4. **boltz.conf sync**: The `docker/boltz.conf` is a full copy of the upstream config with our additions. When the boltz-regtest submodule updates its default `boltz.conf`, the Hostr copy must be manually synced. Consider a future templating approach to reduce drift.

5. **ERC20 allowance**: Boltz-backend's `EthereumManager.init()` automatically approves `MAX_UINT256` on the ERC20Swap contract for each configured ERC20 token. No manual `approve` call is needed in the init script beyond the `transfer` to fund the boltz wallet.
