# Boltz Arbitrum Regtest: Implementation

> **Status:** ✅ IMPLEMENTED
> **Constraint:** No files inside `dependencies/` are modified. All changes are
> done via Compose overrides, Hostr-owned config files, and init containers.

## Overview

Arbitrum chain support has been added to the Boltz regtest stack. The
`anvil-arbitrum` chain (chain-id `412346`) serves as the unified EVM chain for:

- **Boltz swaps** — tBTC ↔ BTC via Lightning (submarine + reverse)
- **Escrow contract** — MultiEscrow deployed to the same chain
- **Account Abstraction** — paymaster / bundler / ERC-4337 infra

### Key routes enabled

| Direction | Flow |
|-----------|------|
| Lightning → tBTC | User pays BTC invoice → receives tBTC on Arbitrum (reverse swap) |
| tBTC → Lightning | User locks tBTC into ERC20Swap → receives BTC Lightning payment (submarine swap) |

---

## Files Changed

| File | Change |
|------|--------|
| `compose.boltz.yaml` | Added `anvil-arbitrum` service (VHOST `arbitrum.hostr.development`), `arbitrum-init` service, `boltz-backend` depends_on + boltz.conf volume mount |
| `docker/boltz.conf` | Fixed `[arb]` → `[arbitrum]`, pointed to `anvil-arbitrum`, added `l1Providers`, added tBTC ERC20 token, added tBTC/BTC pair, updated `deferredClaimSymbols` |
| `docker/scripts/arbitrum-init.sh` | **New.** Deploys EtherSwap + ERC20Swap + MockTBTC to anvil-arbitrum, funds default accounts with tBTC |
| `compose.paymaster.yaml` | Pointed `contract-deployer` and `bundler` to `anvil-arbitrum`, added depends_on |
| `alto-config.json` | Changed `rpc-url` to `http://anvil-arbitrum:8545` |
| `compose.yaml` | Added `arbitrum.${DOMAIN}` to nginx-proxy network aliases |
| `compose.local.yaml` | Updated `escrow-contract-deploy` and `escrow` to use `anvil-arbitrum` |
| `docker/tls/generate-dev-certs.sh` | Added TLS cert for `arbitrum.${DOMAIN}` |
| `.env` | Changed `RPC_URL` to `http://anvil-arbitrum:8545` |

> **No files in `dependencies/` were modified.** The submodule `utils.sh` is
> mounted read-only into `arbitrum-init` to extract contract bytecodes.

---

## 1. `anvil-arbitrum` Service

**File:** `compose.boltz.yaml`

A second Anvil instance running chain-id `412346`:

- **VHOST:** `arbitrum.hostr.development` — accessible from the app via nginx-proxy
- **Host port:** `8546` (avoids conflict with RSK anvil on `8545`)
- **Healthcheck:** `cast chain-id --rpc-url http://127.0.0.1:8545`
- Chain-id `412346` matches `ESCROW_CONTRACT_ADDRESS_KEY=regtest.412346`

---

## 2. `arbitrum-init` Service (Contract Deployment)

**Files:** `compose.boltz.yaml` + `docker/scripts/arbitrum-init.sh`

Runs once at startup using the Foundry image. Extracts swap contract
bytecodes from `dependencies/boltz-regtest/images/scripts/utils.sh`
(mounted read-only) via `sed`, then deploys to anvil-arbitrum.

### Deployment order & deterministic addresses

All contracts deployed by Anvil Account #1 (`0x70997970...`):

| Nonce | Contract  | Address |
|-------|-----------|---------|
| 0 | EtherSwap | `0x8464135c8F25Da09e49BC8782676a84730C318bC` |
| 1 | ERC20Swap | `0x71C95911E9a5D330f4D621842EC243EE1343292e` |
| 2 | MockTBTC  | `0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F` |

### MockTBTC ERC20

Minimal Solidity ERC20 compiled inline via `forge create`. 1M tBTC
(18 decimals) minted to deployer. 100k tBTC distributed to each of
Anvil Accounts #0, #2, #3, #4, #5. If `BOLTZ_WALLET_ADDRESS` env var
is set, that address also receives 100k tBTC + 1000 ETH for gas.

### Bytecode extraction (Option C hybrid)

```yaml
volumes:
  - ./dependencies/boltz-regtest/images/scripts/utils.sh:/scripts/boltz-utils.sh:ro
```

```sh
ETHERSWAP_BYTECODE=$(sed -n '/# EtherSwap/{n;s/^[[:space:]]*deploy_contract //;p;}' /scripts/boltz-utils.sh)
ERC20SWAP_BYTECODE=$(sed -n '/# ERC20Swap/{n;s/^[[:space:]]*deploy_contract //;p;}' /scripts/boltz-utils.sh)
```

This reads the submodule file **without modifying it** — if the
bytecodes change upstream, the init container automatically picks
up the new versions.

---

## 3. `boltz.conf` Override

**File:** `docker/boltz.conf` (mounted read-only into boltz-backend)

### Key fix: `[arb]` → `[arbitrum]`

The TOML section key **must** be `[arbitrum]` — matching:
- TypeScript: `ConfigType.arbitrum?: ArbitrumConfig` (`lib/Config.ts`)
- Rust: `GlobalConfig.arbitrum: Option<boltz_evm::Config>` (`boltzr/src/config.rs`)

### `[arbitrum]` section

```toml
[arbitrum]
providerEndpoint = "ws://anvil-arbitrum:8545"

  [[arbitrum.l1Providers]]
  endpoint = "ws://anvil:8545"

  [[arbitrum.contracts]]
  etherSwap = "0x8464135c8F25Da09e49BC8782676a84730C318bC"
  erc20Swap = "0x71C95911E9a5D330f4D621842EC243EE1343292e"

  [[arbitrum.tokens]]
  symbol = "ARB"
  ...

  [[arbitrum.tokens]]
  symbol = "tBTC"
  decimals = 18
  contractAddress = "0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F"
  ...
```

### Key details

| Key | Value | Notes |
|-----|-------|-------|
| `[arbitrum]` | section name | Must match struct field names in TS + Rust |
| `l1Providers` | `ws://anvil:8545` | **Required.** Boltz uses L1 block height for locktime. RSK anvil acts as stand-in L1 in regtest |
| `l1Providers.endpoint` | not `providerEndpoint` | `ProviderConfig` type uses `endpoint` |
| ARB token | no `contractAddress` | Native gas token — treated as EtherSwap |
| tBTC token | has `contractAddress` | ERC20 — triggers `ERC20WalletProvider` creation |
| `deferredClaimSymbols` | includes `"tBTC"` | Enables batched claiming |

### Pair: tBTC/BTC only

Single pair for Lightning ↔ tBTC swaps (submarine + reverse):

```toml
[[pairs]]
base = "tBTC"
quote = "BTC"
rate = 1
fee = 0.25
swapInFee = 0.1
maxSwapAmount = 4_294_967
minSwapAmount = 50_000
```

No ARB/L-BTC or tBTC/L-BTC pairs.

---

## 4. Paymaster Stack → `anvil-arbitrum`

**Files:** `compose.paymaster.yaml` + `alto-config.json`

All ERC-4337 infra now targets `anvil-arbitrum:8545`:

| Service | Change |
|---------|--------|
| `contract-deployer` | `ANVIL_RPC=http://anvil-arbitrum:8545`, depends_on `anvil-arbitrum` |
| `alto` | `rpc-url` in `alto-config.json` → `http://anvil-arbitrum:8545` |
| `bundler` | `ANVIL_RPC=http://anvil-arbitrum:8545` |

---

## 5. Escrow → `anvil-arbitrum`

**Files:** `compose.local.yaml` + `.env`

- `escrow-contract-deploy`: `RPC_URL=http://anvil-arbitrum:8545`, depends_on `anvil-arbitrum`
- `escrow`: depends_on changed from `anvil` to `anvil-arbitrum`
- `.env`: `RPC_URL=http://anvil-arbitrum:8545`

Hardhat auto-detects chain-id `412346` → writes to `contract-addresses.json`
under key `regtest.412346`, which matches `ESCROW_CONTRACT_ADDRESS_KEY`.

---

## 6. VHOST: `arbitrum.hostr.development`

**Files:** `compose.boltz.yaml`, `compose.yaml`, `docker/tls/generate-dev-certs.sh`

- `anvil-arbitrum` has `VIRTUAL_HOST=arbitrum.${DOMAIN}` + `VIRTUAL_PORT=8545`
- nginx-proxy network alias `arbitrum.${DOMAIN}` added
- TLS cert generated with SAN: `DNS:arbitrum.${DOMAIN},DNS:arbitrum,DNS:anvil-arbitrum`
- App can reach the RPC at `https://arbitrum.hostr.development`

---

## Startup Dependency Graph

```
              anvil (RSK, chain-id 33)
                │
                ├── regtest-start (deploys RSK contracts, inits LN)
                │     └── boltz-backend ────┐
                │                           │ depends on BOTH
    anvil-arbitrum (chain-id 412346)        │
                │                           │
                ├── arbitrum-init ───────────┘
                │     (EtherSwap + ERC20Swap + MockTBTC)
                │
                ├── escrow-contract-deploy
                │     (MultiEscrow)
                │     └── escrow
                │
                └── contract-deployer (ERC-4337)
                      └── alto → bundler
```

---

## Architecture Diagram

```
┌─────────────────────────┐     ┌──────────────────────────────┐
│   anvil (chain-id 33)   │     │  anvil-arbitrum (chain-id    │
│   Rootstock regtest     │     │  412346)                     │
│                         │     │  VHOST: arbitrum.hostr.dev   │
│ EtherSwap: 0x8464...   │     │                              │
│ ERC20Swap: 0x71C9...   │     │ EtherSwap:    0x8464...      │
│                         │     │ ERC20Swap:    0x71C9...      │
│                         │     │ MockTBTC:     0x948B...      │
│                         │     │ MultiEscrow:  0x663F...      │
│                         │     │ ERC-4337:     (pimlico)      │
└────────┬────────────────┘     └────────┬─────────────────────┘
         │                               │
         │  ws://anvil:8545              │  ws://anvil-arbitrum:8545
         │  (also serves as L1)          │  https://arbitrum.hostr.development
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

## End-to-End tBTC Swap Flow

```
┌──────────────────────────────────────────────────────┐
│  arbitrum-init container (runs once at startup)      │
│                                                      │
│  1. cast send --create  → EtherSwap   (nonce 0)     │
│  2. cast send --create  → ERC20Swap   (nonce 1)     │
│  3. forge create        → MockTBTC    (nonce 2)     │
│     └─ 1M tBTC minted to deployer (Account #1)      │
│  4. transfer 100k tBTC to each of 5 Anvil accounts  │
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
│  Swap: tBTC → Lightning (submarine)                  │
│                                                      │
│  POST /v2/swap/submarine  { from: "tBTC",            │
│                              to: "BTC", ... }        │
│  User locks tBTC into ERC20Swap on anvil-arbitrum    │
│  Boltz claims tBTC via ERC20Swap.claim()             │
│  Boltz pays BTC invoice on Lightning                 │
│                                                      │
│  Swap: Lightning → tBTC (reverse)                    │
│                                                      │
│  POST /v2/swap/reverse  { from: "BTC",               │
│                            to: "tBTC", ... }         │
│  User pays BTC Lightning invoice                     │
│  Boltz locks tBTC in ERC20Swap on anvil-arbitrum     │
│  User claims tBTC via ERC20Swap.claim()              │
└──────────────────────────────────────────────────────┘
```

---

## Risks & Considerations

1. **l1Providers in regtest**: Using the RSK anvil as the "L1" for Arbitrum is a hack — in production, this would be Ethereum mainnet. In regtest it works because boltz just needs _some_ block height that advances. If it causes issues, spin up a third anvil dedicated to being "L1".

2. **Bytecode drift**: The EtherSwap/ERC20Swap bytecodes are extracted from `utils.sh` via `sed`. If the comment format changes (`# EtherSwap` / `# ERC20Swap`), the extraction breaks. The script validates that both bytecodes are non-empty.

3. **tBTC contract address stability**: The MockTBTC address (`0x948B3c65…`) is deterministic only if it's the 3rd contract deployed by Account #1 (nonce 2). If deployment order changes, the address changes and `boltz.conf` must be updated.

4. **boltz.conf sync**: `docker/boltz.conf` is a full copy of the upstream config with our additions. When the boltz-regtest submodule updates its default config, the Hostr copy must be manually synced.

5. **Boltz wallet funding**: The init script funds Anvil Accounts #0, #2–#5 with 100k tBTC each. If boltz-backend derives a wallet at a different address (from its own mnemonic), set `BOLTZ_WALLET_ADDRESS` in `.env` to fund it explicitly.

6. **ERC20 allowance**: boltz-backend's `EthereumManager.init()` automatically calls `approve(erc20Swap, MAX_UINT256)` for each configured ERC20 token. No manual approval needed.
