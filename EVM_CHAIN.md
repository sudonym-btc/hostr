# EVM Chain Architecture — Composable Multi-Chain Design

## Status: Proposal

## Problem

Today the codebase has:

1. **A single `Rootstock` subclass** of `EvmChain`, even though production actually targets Arbitrum One. Adding a second chain means writing another 200+ line subclass that largely duplicates Rootstock.
2. **Swap logic (Boltz) is baked into the chain subclass.** Every `EvmChain` is forced to implement `swapIn()`, `swapOut()`, `getEtherSwapContract()`, etc. — even if the chain is only used for escrow proof verification or other non-swap work.
3. **Escrow contract addresses are resolved through a fragile multi-source fallback** (`ESCROW_CONTRACT_ADDRESS` → `ESCROW_CONTRACT_ADDRESS_KEY` → JSON file → repo file). The bytecode hash is a separate env variable.
4. **Paymaster / Account Abstraction config is a flat set of `AA_*` env vars** with no association to a specific chain, making multi-chain AA impossible.
5. **`Evm.getChainForEscrowService()` returns the first chain unconditionally** — the chain-matching logic is commented out.

The result: adding a second EVM chain or a second escrow contract is a significant manual effort touching config, env files, compose files, DI, and multiple classes.

---

## Design Goals

| Goal                        | Description                                                                                                                                 |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **Zero new subclasses**     | Adding a chain = adding a JSON/env config block, not a Dart class.                                                                          |
| **Swap-dynamic**            | Boltz swap capability is discovered at runtime from the Boltz API, not hardcoded per chain.                                                 |
| **Escrow-global**           | Supported escrow bytecode hashes are a bundled constant shared across SDK, app, and daemon — not per-chain or per-env.                      |
| **Paymaster-per-chain**     | Each chain independently declares its AA stack (bundler, entrypoint, factory, paymaster). Chains without a paymaster send raw transactions. |
| **One env block per chain** | All chain-specific config lives in a single, self-contained declaration.                                                                    |
| **Backward compatible**     | The refactor should be phased; existing `Rootstock` can be a thin migration shim initially.                                                 |

---

## 1. Config Model — One Block Per Chain

### 1.1 Env format

Replace the current flat `RPC_URL` / `AA_*` variables with a **single JSON config object**:

```env
# .env.production
EVM_CONFIG='{
  "boltz": {
    "apiUrl": "https://api.boltz.exchange/v2"
  },
  "chains": [
    {
      "id": "arbitrum",
      "chainId": 42161,
      "rpcUrl": "https://arb1.arbitrum.io/rpc",
      "accountAbstraction": {
        "bundlerUrl": "https://paymaster.hostr.network/rpc",
        "entryPointAddress": "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
        "accountFactoryAddress": "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
        "paymasterAddress": "0x..."
      }
    }
  ]
}'
```

```env
# .env.dev (two chains — Boltz will auto-discover which ones it can swap on)
EVM_CONFIG='{
  "boltz": {
    "apiUrl": "https://boltz.hostr.development/v2"
  },
  "chains": [
    {
      "id": "anvil-arbitrum",
      "chainId": 412346,
      "rpcUrl": "http://anvil-arbitrum:8545",
      "accountAbstraction": {
        "bundlerUrl": "http://bundler:3000/rpc",
        "entryPointAddress": "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
        "accountFactoryAddress": "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
        "paymasterAddress": "0x0000000000000000000000000000000000000000"
      }
    },
    {
      "id": "sepolia-escrow-only",
      "chainId": 11155111,
      "rpcUrl": "https://rpc.sepolia.org"
    }
  ]
}'
```

Notice: **no `boltz` per chain, no `supportedBytecodes` anywhere in the env.** Boltz swap capability is discovered at runtime (§3.1). Escrow bytecode hashes are a compiled-in constant (§4).

> **Why one variable?** Docker Compose, Dart `String.fromEnvironment`, and Flutter web all handle a single string well. Parsing multiple numbered `RPC_URL_1`, `RPC_URL_2` variables is fragile and requires convention. A JSON object is self-describing and trivially extensible.

> **Alternative for Compose ergonomics:** If the JSON-in-env approach feels unwieldy, mount an `evm-config.json` file instead (similar to the existing `contract-addresses.json` pattern). The env variable `EVM_CONFIG_PATH` would point to it.

### 1.2 Coexistence with existing env vars

`RPC_URL`, `AA_*`, and `ESCROW_CONTRACT_ADDRESS` are consumed by **non-Dart infrastructure**: the hosted paymaster service reads `RPC_URL`, Hardhat uses it for contract deployment, `compose.paymaster.yaml` passes `AA_ENTRY_POINT_ADDRESS` to the bundler, and the escrow daemon's Docker entrypoint resolves `ESCROW_CONTRACT_ADDRESS` from `contract-addresses.json`. We **cannot simply delete these vars** — Docker services don't parse JSON.

The strategy: **dual-source during migration, then generate one from the other.**

```
┌─────────────────────────────────────────────────────────────────┐
│                    .env.{environment}                            │
│                                                                 │
│  # Legacy vars — consumed by Docker services, scripts, Hardhat  │
│  RPC_URL=http://anvil-arbitrum:8545                             │
│  ESCROW_CONTRACT_ADDRESS=0x...       (auto-synced by scripts)   │
│  ESCROW_CONTRACT_ADDRESS_KEY=regtest.412346                     │
│  AA_BUNDLER_URL=http://bundler:3000/rpc                         │
│  AA_ENTRY_POINT_ADDRESS=0x...        (auto-synced by scripts)   │
│  AA_ACCOUNT_FACTORY_ADDRESS=0x...    (auto-synced by scripts)   │
│  AA_PAYMASTER_ADDRESS=0x...          (auto-synced by scripts)   │
│                                                                 │
│  # New — consumed by Dart (SDK, app, escrow daemon)             │
│  EVM_CONFIG='{...}'                  (auto-generated by scripts) │
│  BOLTZ_API_URL=https://boltz.hostr.development/v2               │
└─────────────────────────────────────────────────────────────────┘
```

**Phase 1 (now):** `sync-contract-env.sh` continues to write the legacy vars as today. Additionally, it **generates `EVM_CONFIG`** from those same vars. The Dart config shim reads `EVM_CONFIG` when present, falls back to the legacy vars. Docker services are unaffected.

**Phase 2 (later):** Once all Dart code reads `EVM_CONFIG`, the legacy vars become Docker-only. They can optionally be extracted _from_ `EVM_CONFIG` by a small shell helper, or just kept as parallel declarations (they rarely change in prod/staging).

This means **zero breaking changes to Docker infrastructure** during the migration.

### 1.3 Dart config classes

```
┌──────────────────────────────┐
│         EvmConfig            │  ← top-level, one per deployment
│  ────────────────────────    │
│  boltz: BoltzConfig?         │  ← nullable = deployment has no Boltz
│  chains: List<EvmChainConfig>│
└──────────────────────────────┘

┌───────────────────────────┐
│      EvmChainConfig       │  ← one per chain
│  ─────────────────────    │
│  id: String               │
│  chainId: int             │
│  rpcUrl: String           │
│  aa: AAConfig?            │  ← nullable = raw tx mode
└───────────────────────────┘
```

```dart
/// Top-level EVM config for the deployment.
@freezed
class EvmConfig with _$EvmConfig {
  const factory EvmConfig({
    BoltzConfig? boltz,                // null → no Boltz in this deployment
    @Default([]) List<EvmChainConfig> chains,
  }) = _EvmConfig;

  factory EvmConfig.fromJson(Map<String, dynamic> json) =>
      _$EvmConfigFromJson(json);
}

/// Per-chain config. Deliberately minimal — no swap or escrow fields.
@freezed
class EvmChainConfig with _$EvmChainConfig {
  const factory EvmChainConfig({
    required String id,
    required int chainId,
    required String rpcUrl,
    AAConfig? accountAbstraction, // null → use raw EOA transactions
  }) = _EvmChainConfig;

  factory EvmChainConfig.fromJson(Map<String, dynamic> json) =>
      _$EvmChainConfigFromJson(json);
}
```

`HostrConfig.rootstockConfig` becomes `HostrConfig.evmConfig: EvmConfig` (with a migration getter for backward compat during transition).

---

## 2. EvmChain — Concrete, Not Abstract

### 2.1 Core principle

`EvmChain` becomes **a concrete, final class** constructed directly from an `EvmChainConfig`. All the current base-class infrastructure (RPC self-healing, block polling, log batching, HD address scanning, balance subscriptions) stays, but the abstract swap/escrow methods are **removed from the class**.

```dart
/// No longer abstract. No swap methods. No escrow methods.
final class EvmChain {
  final EvmChainConfig config;

  EvmChain(this.config);

  // --- existing infra (unchanged) ---
  Web3Client get client => ...;
  Stream<BlockNum> get newBlocks => ...;
  Future<List<FilterEvent>> getLogs(...) => ...;
  // HD address management, balance subscriptions, etc.
  // ...
}
```

**What about `@Singleton()`?** Instead of a singleton class, the `Evm` orchestrator holds the `List<EvmChain>` instances. DI resolves `Evm`, not individual chains.

### 2.2 Why remove swap/escrow from `EvmChain`?

The chain is a **transport layer** — it knows how to talk to an RPC node, poll blocks, and manage keys. Swap protocols and escrow contracts are **capabilities** that sit on top of the transport. Bundling them into the chain forces every chain to implement or stub them.

---

## 3. Capabilities — Composition vs Mixins

Capabilities are attached to a chain **at construction time** based on what the config declares. Two patterns are detailed below — pick the one that fits best.

### Option A: Capability Objects

Each capability is a standalone class that **wraps** an `EvmChain`:

```
┌─────────────────────┐     ┌──────────────────────┐
│      EvmChain       │◄────│   BoltzSwapProvider   │
│  (transport layer)  │     │  - etherSwapContract  │
│                     │     │  - swapIn()           │
│                     │     │  - swapOut()           │
│                     │     │  - getSwapInLimits()  │
└─────────────────────┘     └──────────────────────┘
          ▲
          │
┌─────────┴───────────┐
│  EscrowCapability    │
│  - getSupportedContract()  │
│  - verifyProof()    │
└──────────────────────┘
          ▲
          │
┌─────────┴───────────┐
│    AACapability      │
│  - userOpService     │
│  - sendUserOp()     │
│  - estimateGas()    │
└──────────────────────┘
```

### 3.1 Dynamic Boltz Discovery

The Boltz V2 API already exposes multi-chain discovery endpoints (they exist in the generated Swagger client but are currently unused):

| Endpoint               | Returns                                                                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `GET /chain/contracts` | All supported EVM chains: `{ "rsk": { network: { chainId }, swapContracts: { EtherSwap, ERC20Swap }, tokens }, "arbitrum": { ... } }` |
| `GET /swap/submarine`  | All submarine pairs as nested map: `{ "RBTC": { "BTC": SubmarinePair }, "tBTC": { "BTC": SubmarinePair } }`                           |
| `GET /swap/reverse`    | All reverse pairs as nested map: `{ "BTC": { "RBTC": ReversePair, "tBTC": ReversePair } }`                                            |

At startup, `BoltzClient.discoverChains()` calls `GET /chain/contracts` and returns a map of `chainId → BoltzChainInfo`:

```dart
class BoltzChainInfo {
  final String currency;           // e.g. 'RBTC', 'tBTC'
  final int chainId;
  final EthereumAddress etherSwap;
  final EthereumAddress erc20Swap;
  final Map<String, EthereumAddress> tokens;
}

class BoltzClient {
  /// Discover all EVM chains this Boltz instance supports.
  Future<Map<int, BoltzChainInfo>> discoverChains() async {
    final contracts = await _service.chainContractsGet(); // existing generated method
    return {
      for (final entry in contracts.entries)
        entry.value.network.chainId.toInt(): BoltzChainInfo(
          currency: _chainNameToCurrency(entry.key),
          chainId: entry.value.network.chainId.toInt(),
          etherSwap: EthereumAddress.fromHex(entry.value.swapContracts.etherSwap!),
          erc20Swap: EthereumAddress.fromHex(entry.value.swapContracts.eRC20Swap!),
          tokens: entry.value.tokens.map((k, v) => MapEntry(k, EthereumAddress.fromHex(v))),
        ),
    };
  }

  /// Use the discovered currency symbol for pair lookups.
  Future<ReversePair> getReversePair({required String currency}) =>
      _parseReversePair(from: 'BTC', to: currency);
  Future<SubmarinePair> getSubmarinePair({required String currency}) =>
      _parseSubmarinePair(from: currency, to: 'BTC');
}
```

The key insight: **chain config never mentions Boltz**. The `Evm` orchestrator queries the Boltz API, matches `chainId`s, and attaches `BoltzSwapProvider` to chains that Boltz supports.

### 3.2 BoltzSwapProvider

```dart
class BoltzSwapProvider {
  final EvmChain chain;
  final BoltzClient boltzClient;
  final BoltzChainInfo chainInfo;   // discovered at runtime

  BoltzSwapProvider(this.chain, this.boltzClient, this.chainInfo);

  Future<EtherSwap> getEtherSwapContract() async =>
      EtherSwap(address: chainInfo.etherSwap, client: chain.client);

  SwapInOperation swapIn(SwapInParams params) => SwapInOperation(chain, this, params);
  Future<List<SwapOutOperation>> swapOutAll() async { ... }

  Future<({TokenAmount min, TokenAmount max})> getSwapInLimits() async {
    final pair = await boltzClient.getReversePair(currency: chainInfo.currency);
    return (min: pair.limits.minimal, max: pair.limits.maximal);
  }
}
```

### 3.3 How capabilities are assembled

Assembly is **async** because Boltz discovery requires an API call:

```dart
class ConfiguredEvmChain {
  final EvmChain chain;
  BoltzSwapProvider? swaps;        // null until Boltz discovery says otherwise
  final AACapability? aa;          // null if config.accountAbstraction == null
  final EscrowCapability escrow;   // always present, uses global bytecode registry

  ConfiguredEvmChain(this.chain, EvmChainConfig config)
      : aa = config.accountAbstraction != null
            ? AACapability(chain, config.accountAbstraction!)
            : null,
        escrow = EscrowCapability(chain);

  /// Called by Evm orchestrator after Boltz discovery.
  void attachSwaps(BoltzClient client, BoltzChainInfo info) {
    swaps = BoltzSwapProvider(chain, client, info);
  }
}
```

### Option B: Mixin-Based

The mixin approach keeps the hierarchy flat — `EvmChain` remains the single class, and capabilities are layered on as mixins. The key challenge (you can't `with` a mixin conditionally at runtime) is solved by making `EvmChain` **not** `final`, using a single factory, and having each mixin gracefully degrade when its config is absent.

#### 3.4 EvmChain as mixin target

```dart
/// Base class — open for mixin application, but never subclassed manually.
class EvmChain with BoltzSwappable, AAEnabled, EscrowEnabled {
  @override
  final EvmChainConfig config;

  // Boltz — injected after construction by the orchestrator
  @override
  BoltzChainInfo? boltzChainInfo;
  @override
  BoltzClient? boltzClient;

  // AA — derived from config
  @override
  AAConfig? get aaConfig => config.accountAbstraction;

  EvmChain(this.config);

  // --- existing infra (unchanged) ---
  Web3Client get client => ...;
  Stream<BlockNum> get newBlocks => ...;
  Future<List<FilterEvent>> getLogs(...) => ...;
  // HD address management, balance subscriptions, etc.
}
```

Every chain instance has all three mixins, but each mixin **checks its own "enabled" state** before doing anything. No subclass needed.

#### 3.5 BoltzSwappable mixin

```dart
mixin BoltzSwappable on _EvmChainBase {
  /// Set by Evm orchestrator after Boltz API discovery.
  /// null = Boltz doesn't support this chain (or hasn't been discovered yet).
  BoltzChainInfo? get boltzChainInfo;
  BoltzClient? get boltzClient;

  bool get hasSwaps => boltzChainInfo != null && boltzClient != null;

  Future<EtherSwap> getEtherSwapContract() async {
    _requireSwaps();
    return EtherSwap(address: boltzChainInfo!.etherSwap, client: client);
  }

  SwapInOperation swapIn(SwapInParams params) {
    _requireSwaps();
    return SwapInOperation(this, params);
  }

  Future<List<SwapOutOperation>> swapOutAll() async {
    _requireSwaps();
    // ... existing logic, using boltzClient! and boltzChainInfo!
  }

  Future<({TokenAmount min, TokenAmount max})> getSwapInLimits() async {
    _requireSwaps();
    final pair = await boltzClient!.getReversePair(currency: boltzChainInfo!.currency);
    return (min: pair.limits.minimal, max: pair.limits.maximal);
  }

  void _requireSwaps() {
    if (!hasSwaps) throw SwapsNotAvailableException(config.chainId);
  }
}
```

#### 3.6 AAEnabled mixin

```dart
mixin AAEnabled on _EvmChainBase {
  AAConfig? get aaConfig;

  bool get hasAA => aaConfig != null;

  late final UserOpService? _userOpService = aaConfig != null
      ? UserOpService(
          rpcUrl: config.rpcUrl,
          bundlerUrl: aaConfig!.bundlerUrl,
          entryPointAddress: aaConfig!.entryPointAddress,
          accountFactoryAddress: aaConfig!.accountFactoryAddress,
          paymasterAddress: aaConfig!.paymasterAddress,
        )
      : null;

  UserOpService get userOpService {
    if (_userOpService == null) throw AANotAvailableException(config.chainId);
    return _userOpService!;
  }

  /// Route transaction through AA (if available) or raw EOA.
  Future<String> sendTransaction(ContractCallIntent intent) {
    if (hasAA) {
      return userOpService.sendUserOp(intent);
    } else {
      return client.sendTransaction(...);
    }
  }

  Future<BigInt> estimateGasFee(ContractCallIntent intent) async {
    if (hasAA) return BigInt.zero; // paymaster sponsors
    return intent.maxGas * (await client.getGasPrice());
  }
}
```

#### 3.7 EscrowEnabled mixin

```dart
mixin EscrowEnabled on _EvmChainBase {
  final _escrowCache = <String, SupportedEscrowContract>{};
  int _escrowCacheGen = -1;

  /// Always available — uses the global bytecode registry.
  Future<SupportedEscrowContract?> getEscrowContract(EthereumAddress address) async {
    if (_escrowCacheGen != clientGeneration) {
      _escrowCache.clear();
      _escrowCacheGen = clientGeneration;
    }
    final key = address.eip55With0x;
    if (_escrowCache.containsKey(key)) return _escrowCache[key];

    final bytecode = await client.getCode(address);
    final hash = sha256.convert(bytecode).toString();

    final contract = SupportedEscrowContractRegistry.fromBytecodeHash(
      hash, client, address, this,
    );
    if (contract != null) _escrowCache[key] = contract;
    return contract;
  }
}
```

#### 3.8 Boltz discovery — same as Option A

The `Evm` orchestrator discovers Boltz chains at startup and injects the info:

```dart
@Singleton()
class Evm {
  late final List<EvmChain> chains;
  BoltzClient? _boltzClient;

  Evm(HostrConfig config) {
    final evmConfig = config.evmConfig;
    chains = evmConfig.chains.map((c) => EvmChain(c)).toList();
    if (evmConfig.boltz != null) {
      _boltzClient = BoltzClient(apiUrl: evmConfig.boltz!.apiUrl);
    }
  }

  Future<void> initialize() async {
    if (_boltzClient == null) return;
    final boltzChains = await _boltzClient!.discoverChains();
    for (final chain in chains) {
      final info = boltzChains[chain.config.chainId];
      if (info != null) {
        chain.boltzChainInfo = info;
        chain.boltzClient = _boltzClient;
      }
      // Chains that Boltz doesn't know about: boltzChainInfo stays null,
      // hasSwaps returns false, swap methods throw if called.
    }
  }

  EvmChain? chainById(int chainId) =>
      chains.firstWhereOrNull((c) => c.config.chainId == chainId);

  Iterable<EvmChain> get swappableChains => chains.where((c) => c.hasSwaps);

  EvmChain getChainForEscrowService(EscrowService service) {
    return chainById(service.chainId)
        ?? (throw UnsupportedChainException(service.chainId));
  }
}
```

#### 3.9 Consuming code — flat access

With mixins, call sites access capabilities directly on the chain object — no `.swaps!.` or `.aa!.` indirection:

```dart
// Option A (composition):
final chain = evm.chainById(42161)!;
chain.swaps!.swapIn(params);               // must null-check .swaps
chain.aa!.userOpService.sendUserOp(intent); // must null-check .aa
chain.escrow.getContract(address);          // escrow is on a separate object

// Option B (mixins):
final chain = evm.chainById(42161)!;
chain.swapIn(params);                   // direct call, throws if not available
chain.sendTransaction(intent);          // routes through AA or raw EOA transparently
chain.getEscrowContract(address);       // direct call on chain
```

The trade-off: Option A makes capability absence **visible at the type level** (nullable fields you must check), while Option B makes it **visible at runtime** (throws if you call a method on a chain that doesn't support it). Option B is flatter and more ergonomic for call sites that know the chain supports the capability.

#### 3.10 Comparison

| Aspect                               | Option A (Composition)                                                                                         | Option B (Mixins)                                          |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Class count**                      | 4 classes (`EvmChain`, `BoltzSwapProvider`, `AACapability`, `EscrowCapability`) + `ConfiguredEvmChain` wrapper | 1 class + 3 mixins. No wrapper needed.                     |
| **Hierarchy depth**                  | Flat (no inheritance)                                                                                          | Flat (no inheritance — mixins are horizontal)              |
| **Type safety for "has capability"** | Compile-time: `chain.swaps != null`                                                                            | Runtime: `chain.hasSwaps` / throws                         |
| **Call site ergonomics**             | `chain.swaps!.swapIn(...)`                                                                                     | `chain.swapIn(...)`                                        |
| **Adding a new capability**          | New class + add field to `ConfiguredEvmChain`                                                                  | New mixin + `with` it on `EvmChain`                        |
| **Runtime conditional attachment**   | ✅ natural (set field to null or non-null)                                                                     | ✅ via nullable backing fields + `hasX` checks             |
| **Testability**                      | Mock each capability independently                                                                             | Override mixin methods or use `@visibleForTesting` setters |
| **Boltz runtime discovery**          | `chain.attachSwaps(client, info)`                                                                              | `chain.boltzChainInfo = info; chain.boltzClient = client;` |

**Downsides of mixins**: Every `EvmChain` instance carries all mixin methods even if the capability is disabled — the methods just throw. This is a wider API surface than composition, where disabled capabilities simply don't exist on the object. That said, the `hasSwaps` / `hasAA` guards keep things safe at runtime, and the flatter call-site ergonomics may be worth the trade-off.

---

## 4. Escrow Contracts — Global Bytecode Registry

### 4.1 Core insight: escrow contracts are chain-agnostic

The `MultiEscrow` contract (and any future escrow contracts) are **not tied to a specific chain**. The same bytecode can be deployed on Arbitrum, Sepolia, a local Anvil — wherever. The contract address varies per deployment, but the bytecode hash is a property of the **Solidity source**, not the chain.

Therefore `supportedBytecodes` does **not** belong in per-chain config. It belongs in a **global, compile-time constant** shared across all packages.

### 4.2 Bundled constant in `hostr_sdk`

The bytecode hashes live as a Dart constant in the SDK, importable by the Flutter app, the escrow daemon, and tests:

```dart
/// hostr_sdk/lib/src/evm/escrow/supported_bytecodes.dart
///
/// SHA-256 hashes of runtime bytecodes for all supported escrow contracts.
/// Generated by: dart run hostr_sdk:update_bytecodes (see §4.7)
const supportedEscrowBytecodeHashes = {
  // MultiEscrow v1 — generated from escrow/contracts/MultiEscrow.sol
  'a1b2c3d4e5f6...': 'MultiEscrow',
  // Future: MultiEscrow v2, SimpleEscrow, etc.
};
```

**Key property: bytecode hashes are stable across restarts.** The bytecode hash is a property of the Solidity source code, not the deployment. Restarting Anvil changes the nonce (→ new contract address), but the same source compiles to the same bytecode (→ same hash). So this constant only needs updating when the **Solidity source changes**, not on every restart.

**Why a compiled constant, not an env variable or asset file?**

| Approach          | SDK tests                        | Escrow daemon | Flutter app          | Flutter web    |
| ----------------- | -------------------------------- | ------------- | -------------------- | -------------- |
| `dart-define` env | ✅                               | ✅            | ✅                   | ✅ but awkward |
| Asset file (JSON) | ❌ needs file path               | ✅            | ✅ via rootBundle    | ✅             |
| **Dart constant** | **✅ import**                    | **✅ import** | **✅ import**        | **✅ import**  |
| Env variable      | ❌ not available in all contexts | ✅            | ❌ compile-time only | ❌             |

A Dart constant is the **only approach that works identically** across SDK unit tests (no file system), the escrow daemon (server-side), the Flutter app (mobile/desktop), and Flutter web (no `dart-define` at runtime, no file system). It's also the simplest: `import 'package:hostr_sdk/.../supported_bytecodes.dart'`.

### 4.3 Registry keyed by bytecode hash

Evolve the current `SupportedEscrowContractRegistry` to key by bytecode hash:

```dart
typedef EscrowContractFactory = SupportedEscrowContract Function(
  Web3Client client, EthereumAddress address, EvmChain chain,
);

class SupportedEscrowContractRegistry {
  static final Map<String, EscrowContractFactory> _byBytecodeHash = {
    // hash from supportedEscrowBytecodeHashes → wrapper constructor
    for (final hash in supportedEscrowBytecodeHashes.keys)
      if (supportedEscrowBytecodeHashes[hash] == 'MultiEscrow')
        hash: (client, address, chain) =>
            MultiEscrowWrapper(client: client, address: address, chain: chain),
    // Future contract types would add more branches here.
  };

  static SupportedEscrowContract? fromBytecodeHash(
    String hash, Web3Client client, EthereumAddress address, EvmChain chain,
  ) => _byBytecodeHash[hash]?.call(client, address, chain);
}
```

### 4.4 Resolution flow

When a user encounters an escrow proof referencing contract address `0xABC` on chain `42161`:

```
1. Evm.getChainForEscrowService(service)  // match by service.chainId
2. chain.escrow.getContract(0xABC)
   a. Fetch runtime bytecode: eth_getCode(0xABC)
   b. Hash it: sha256(bytecode)
   c. Look up SupportedEscrowContractRegistry.fromBytecodeHash(hash)
   d. If found → return wrapper instance (e.g. MultiEscrowWrapper)
   e. If not found → contract is not supported, reject
```

No per-chain allow-list check is needed. If the bytecode hash is in the global registry, it's supported on **any** chain. The chain just provides the transport (RPC client) to talk to that contract.

### 4.5 What lives where — the clear boundary

| Data                               | Where it lives                                                                          | Why                                                                                                                                                | Changes when                                  |
| ---------------------------------- | --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| **Bytecode hashes**                | `supported_bytecodes.dart` (compiled Dart constant)                                     | Must be accessible in SDK tests, Flutter web, daemon — all without filesystem or env.                                                              | Solidity source changes (rare, deliberate)    |
| **Escrow contract address** (dev)  | `contract-addresses.json` → `sync-contract-env.sh` → `.env` → `ESCROW_CONTRACT_ADDRESS` | Changes on every Anvil restart (nonce reset). Must be **fully automated** — the deploy→sync→env pipeline handles this today and continues to.      | Every `docker compose up` / Anvil restart     |
| **Escrow contract address** (prod) | `.env.prod` / `.env.staging` → `ESCROW_CONTRACT_ADDRESS`                                | Set once when deploying to mainnet. Stable. The escrow daemon needs this to know which contract to monitor and publish in its Nostr service event. | Contract redeployment (very rare)             |
| **AA addresses** (dev)             | `contract-addresses.json` → `sync-contract-env.sh` → `.env` → `AA_*`                    | Same as escrow address — changes on restart, automated.                                                                                            | Every Anvil restart                           |
| **AA addresses** (prod)            | `.env.prod` / `.env.staging` → `AA_*`                                                   | EntryPoint is a well-known canonical address. Factory/paymaster set once at deploy.                                                                | Never (EntryPoint) / contract redeploy (rare) |
| **RPC URLs**                       | `.env` → `RPC_URL` (Docker services) + `EVM_CONFIG` chains (Dart)                       | Docker services (Hardhat, paymaster, Boltz init) need plain env vars. Dart reads from `EVM_CONFIG`.                                                | Environment change only                       |
| **Boltz API URL**                  | `.env` → `BOLTZ_API_URL` + `EVM_CONFIG` boltz (Dart)                                    | Only Dart needs this; kept in env for `sync-contract-env.sh` to assemble `EVM_CONFIG`.                                                             | Environment change only                       |
| **Swap contract addresses**        | Boltz API (`GET /chain/contracts`) at runtime                                           | Boltz deploys its own contracts. We never configure these.                                                                                         | Boltz redeploys (transparent to us)           |

The following env variables **can be eliminated** from Dart consumption (but may remain for Docker):

| Variable                      | Dart replacement                                            | Docker still uses?                  |
| ----------------------------- | ----------------------------------------------------------- | ----------------------------------- |
| `MULTI_ESCROW_BYTECODE_HASH`  | `supportedEscrowBytecodeHashes` constant                    | No — remove entirely                |
| `ESCROW_CONTRACT_ADDRESS_KEY` | Not needed by Dart (address comes from env or escrow proof) | Only by compose entrypoint fallback |

The following **must remain in `.env`** because Docker infrastructure reads them directly:

| Variable                     | Docker consumers                                          |
| ---------------------------- | --------------------------------------------------------- |
| `RPC_URL`                    | `escrow` service, `paymaster` (hosted), Hardhat deploy    |
| `ESCROW_CONTRACT_ADDRESS`    | `escrow` service entrypoint                               |
| `AA_BUNDLER_URL`             | `escrow` service, `app` (build arg)                       |
| `AA_ENTRY_POINT_ADDRESS`     | `escrow` service, `app` (build arg), `paymaster` (hosted) |
| `AA_ACCOUNT_FACTORY_ADDRESS` | `escrow` service, `app` (build arg)                       |
| `AA_PAYMASTER_ADDRESS`       | `escrow` service, `app` (build arg)                       |

### 4.6 EscrowCapability

```dart
class EscrowCapability {
  final EvmChain chain;
  final _cache = <String, SupportedEscrowContract>{};
  int _cacheGeneration = -1;

  EscrowCapability(this.chain);

  /// Validate and wrap an escrow contract at [address] on this chain.
  /// Returns null if the deployed bytecode is not in the global registry.
  Future<SupportedEscrowContract?> getContract(EthereumAddress address) async {
    if (_cacheGeneration != chain.clientGeneration) {
      _cache.clear();
      _cacheGeneration = chain.clientGeneration;
    }
    final key = address.eip55With0x;
    if (_cache.containsKey(key)) return _cache[key];

    final bytecode = await chain.client.getCode(address);
    final hash = sha256.convert(bytecode).toString();

    // Global registry — not chain-specific.
    final contract = SupportedEscrowContractRegistry.fromBytecodeHash(
      hash, chain.client, address, chain,
    );
    if (contract != null) _cache[key] = contract;
    return contract;
  }
}
```

### 4.7 Automated dev workflow for bytecode hash updates

The bytecode hash constant only changes when the Solidity source changes — **not on every restart**. But when it does change, we need a frictionless update path:

```bash
# After modifying escrow/contracts/MultiEscrow.sol:
$ dart run hostr_sdk:update_bytecodes

# What it does:
# 1. Compiles the Solidity source via solc/forge (or reads the existing artifact)
# 2. Extracts the deployed runtime bytecode from the compilation output
# 3. SHA-256 hashes it
# 4. Updates supported_bytecodes.dart in-place
# 5. Prints: "Updated MultiEscrow hash: a1b2c3d4... → e5f6a7b8..."
```

This script works **without a running chain** — it compiles locally and hashes the bytecode from the Solidity compiler output. No Anvil needed, no deployment needed, no nonce involved.

Alternatively, if working with an already-deployed contract on a live chain:

```bash
$ dart run hostr_sdk:update_bytecodes --rpc http://localhost:8546 --address 0x...
# Fetches eth_getCode, hashes it, updates the constant.
```

The `restart.sh` / `sync-contract-env.sh` pipeline does **not** touch `supported_bytecodes.dart`. Addresses change on restart; bytecode hashes don't. This is the key distinction that keeps the automated pipeline simple.

---

## 5. Paymaster / Account Abstraction — Per-Chain

### 5.1 Why per-chain?

Paymasters are **smart contracts deployed on a specific chain**. An Arbitrum paymaster cannot sponsor gas on Sepolia. The bundler endpoint also targets a specific chain's mempool. Therefore AA config **must** be 1:1 with a chain.

The current `AccountAbstractionConfig` is correct in shape; it just needs to live inside each chain's config block rather than as a global set of `AA_*` env vars.

### 5.2 AACapability

```dart
class AACapability {
  final EvmChain chain;
  final AAConfig config;
  late final UserOpService userOpService;

  AACapability(this.chain, this.config) {
    userOpService = UserOpService(
      rpcUrl: chain.config.rpcUrl,
      bundlerUrl: config.bundlerUrl,
      entryPointAddress: config.entryPointAddress,
      accountFactoryAddress: config.accountFactoryAddress,
      paymasterAddress: config.paymasterAddress,
    );
  }
}
```

Chains **without** an `accountAbstraction` block in their config simply get `aa = null`. Operations on such chains would use raw `eth_sendTransaction` (or fail if they require sponsored gas).

### 5.3 Transaction routing

Today, `OnchainOperation` and swap operations directly use `UserOpService`. With per-chain AA:

```dart
/// In OnchainOperation or wherever tx sending happens:
Future<String> sendTransaction(ConfiguredEvmChain cchain, ContractCallIntent intent) {
  if (cchain.aa != null) {
    return cchain.aa!.userOpService.sendUserOp(intent);
  } else {
    // Fallback: raw transaction via EOA
    return cchain.chain.client.sendTransaction(...);
  }
}
```

### 5.4 `UserOpService` — Keep, Flatten, or Inline?

The current `UserOpService` (~130 lines) is a `@injectable` factory that wraps
the `permissionless` package's client stack.

#### What it actually does

| Layer                    | Work                                                                                                              | Lines                                                                            |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Config extraction**    | Reads `chainId`, `rpcUrl`, and `AccountAbstractionConfig` from `HostrConfig`                                      | constructor, 4 fields                                                            |
| **Client wiring**        | Creates `PublicClient`, `BundlerClient`, `PaymasterClient`, `SimpleSmartAccount`, `SmartAccountClient` per call   | `_initPublicClient`, `_initSimpleAccount`, `_initSmartAccountClient` (~25 lines) |
| **Fee quoting**          | `publicClient.getFeeData()` → picks `max(gasPrice, maxPriorityFeePerGas)`                                         | `_getFeeQuote` (~8 lines)                                                        |
| **Intent mapping**       | `ContractCallIntent` → `permissionless.Call` (to/value/data with hex encoding)                                    | `_toPermissionlessCall` (~5 lines)                                               |
| **EntryPoint detection** | Maps entrypoint address → `EntryPointVersion` enum                                                                | `_entryPointVersion` (~12 lines)                                                 |
| **Orchestration**        | `_sendCalls`: wire clients → get fees → map intents → `sendUserOperationAndWait` → extract tx hash → close client | ~20 lines                                                                        |

The **heavy lifting** (nonce management, account deployment detection, ABI encoding,
paymaster two-phase sponsorship, gas estimation, signing, submission, receipt
polling) all lives inside `permissionless.SmartAccountClient.sendUserOperationAndWait`.

#### Observed issues

1. **Stateless** — all four fields are immutable config. No cached clients, no
   session, no nonce tracking. Every `sendUserOp` builds and tears down the full
   client stack from scratch.
2. **Registered as `factory`** — `getIt<UserOpService>()` returns a fresh instance
   every time, so callers can't even share one.
3. **Hardcoded to Rootstock** — constructor reads `config.rootstockConfig.*`,
   making it single-chain.
4. **`estimateGasFee` is a stub** — always returns `BigInt.zero`. The paymaster
   pays, but this leaks a "free gas" assumption into fee display via
   `SwapInOperation.estimateFees`.
5. **`sendUserOpBatch` has zero call sites** — dead code.

#### Option 1: Refactor into `AACapability` / `AAEnabled` (absorb & dissolve)

`UserOpService` exists to bridge hostr domain types to the `permissionless` API.
In the new architecture that bridge belongs **inside** the AA capability. We can
absorb it:

```dart
class AACapability {
  final EvmChain chain;
  final AAConfig config;

  AACapability(this.chain, this.config);

  // ── Public API (same 3 methods, minus dead `sendUserOpBatch`) ────

  Future<EthereumAddress> getSmartAccountAddress(EthPrivateKey signer) async {
    final publicClient = _initPublicClient();
    final account = _initSimpleAccount(signer, publicClient: publicClient);
    return account.getAddress();
  }

  Future<String> sendUserOp(EthPrivateKey signer, ContractCallIntent intent) =>
      _sendCalls(signer, [intent]);

  Future<BigInt> estimateGasFee(ContractCallIntent intent) async {
    if (config.paymasterAddress.isNotEmpty) return BigInt.zero;
    final pc = _initPublicClient();
    final fee = await pc.getFeeData();
    return (fee.gasPrice) * BigInt.from(intent.maxGas ?? 200000);
  }

  // ── Private: same internals, now reading from this.chain / this.config ──

  permissionless.PublicClient _initPublicClient() =>
      permissionless.createPublicClient(url: chain.config.rpcUrl);

  permissionless.SimpleSmartAccount _initSimpleAccount(
    EthPrivateKey signer, {
    required permissionless.PublicClient publicClient,
  }) => permissionless.createSimpleSmartAccount(
    owner: permissionless.PrivateKeyOwner(_privateKeyHex(signer)),
    chainId: BigInt.from(chain.config.chainId),
    entryPointVersion: _entryPointVersion,
    customFactoryAddress: EthereumAddress.fromHex(config.accountFactoryAddress),
    publicClient: publicClient,
  );

  // ... _initSmartAccountClient, _sendCalls, _toPermissionlessCall,
  //     _getFeeQuote, _entryPointVersion — moved verbatim
}
```

Or for the mixin approach, the exact same internals go into `AAEnabled`:

```dart
mixin AAEnabled on _EvmChainBase {
  AAConfig? get aaConfig;
  bool get hasAA => aaConfig != null;

  Future<String> sendUserOp(EthPrivateKey signer, ContractCallIntent intent) =>
      _sendCalls(signer, [intent]);

  // ... same private methods as above, reading from `config` and `aaConfig!`
}
```

**Either way `UserOpService` as a separate class is deleted.** The same ~60 lines
of glue code move into the capability/mixin where they naturally belong.

#### Option 2: Keep `UserOpService` as a standalone helper

If there's concern about `AACapability` / `AAEnabled` growing too large, keep
`UserOpService` but fix the pain points:

```dart
class UserOpService {
  // Now takes chain-specific args directly, not HostrConfig
  UserOpService({
    required int chainId,
    required String rpcUrl,
    required AAConfig aaConfig,
  });

  // Drop dead code
  // ✘ sendUserOpBatch — removed (zero callers)

  // Fix gas estimation
  Future<BigInt> estimateGasFee(ContractCallIntent intent) async {
    if (_aaConfig.paymasterAddress.isNotEmpty) return BigInt.zero;
    // … actual gas estimation for non-sponsored chains
  }
}
```

The capability then becomes a one-liner wrapper:

```dart
class AACapability {
  late final userOpService = UserOpService(
    chainId: chain.config.chainId,
    rpcUrl: chain.config.rpcUrl,
    aaConfig: config,
  );
}
```

This is viable but adds an extra layer of indirection with no clear benefit — the
"service" holds no mutable state and has no independent lifecycle.

#### Verdict

| Criterion                           | Option 1 (absorb)                                     | Option 2 (keep)                               |
| ----------------------------------- | ----------------------------------------------------- | --------------------------------------------- |
| File count                          | –1 file                                               | same                                          |
| Lines of glue code                  | ~60 (in capability)                                   | ~60 (in service) + ~10 (capability wraps it)  |
| DI registrations                    | 0 (`AACapability` is created by orchestrator, not DI) | 1 (`@injectable` or `@factoryMethod`)         |
| Testability                         | Mock `AACapability` in tests                          | Mock either `AACapability` or `UserOpService` |
| Where `permissionless` import lives | In the capability/mixin file                          | In `user_op_service.dart`                     |

**Recommendation: Option 1 — absorb into the capability/mixin.**

`UserOpService` is a stateless config-to-library adapter with no independent
lifecycle, no shared state, and no callers outside the AA concern. That's the
definition of code that should live in its parent abstraction. Absorbing it
reduces the object graph by one node, kills one DI factory registration, and
keeps the `permissionless` dependency contained in a single file.

The only counter-argument is file size. `AACapability` / `AAEnabled` with the
absorbed internals would be ~100 lines — well within reason for a single-concern
class.

**Migration note:** Phase 2 (§9) step "Extract `AACapability` from
`UserOpService`" should be read as "absorb `UserOpService` into `AACapability`"
— move the internals, delete the file, remove the DI registration.

---

## 6. Evm Orchestrator

The `Evm` class becomes a thin registry:

```dart
@Singleton()
class Evm {
  late final List<ConfiguredEvmChain> chains;
  BoltzClient? _boltzClient;

  Evm(HostrConfig config) {
    final evmConfig = config.evmConfig;
    chains = evmConfig.chains
        .map((c) => ConfiguredEvmChain(EvmChain(c), c))
        .toList();
    if (evmConfig.boltz != null) {
      _boltzClient = BoltzClient(apiUrl: evmConfig.boltz!.apiUrl);
    }
  }

  /// Must be called once at startup. Queries the Boltz API to discover
  /// which configured chains have swap support, and attaches BoltzSwapProvider.
  Future<void> initialize() async {
    if (_boltzClient == null) return;

    final boltzChains = await _boltzClient!.discoverChains();
    for (final chain in chains) {
      final info = boltzChains[chain.chain.config.chainId];
      if (info != null) {
        chain.attachSwaps(_boltzClient!, info);
      }
    }
  }

  /// Find chain by numeric chain ID.
  ConfiguredEvmChain? chainById(int chainId) =>
      chains.firstWhereOrNull((c) => c.chain.config.chainId == chainId);

  /// Find chain for an escrow service (uses chainId from the escrow proof).
  ConfiguredEvmChain getChainForEscrowService(EscrowService service) {
    final chain = chainById(service.chainId);
    if (chain == null) {
      throw UnsupportedChainException(service.chainId);
    }
    return chain;
  }

  /// Chains that Boltz reported swap support for (discovered at init).
  Iterable<ConfiguredEvmChain> get swappableChains =>
      chains.where((c) => c.swaps != null);

  /// Aggregate balance across all chains.
  Stream<TokenAmount> get totalBalance =>
      Rx.combineLatestList(chains.map((c) => c.chain.subscribeTotalBalance()))
          .map((balances) => balances.fold(TokenAmount.zero, (a, b) => a + b));
}
```

---

## 7. Swap Operations Without Chain Subclasses

Today `RootstockSwapInOperation` and `RootstockSwapOutOperation` extend base classes and are tightly coupled to `Rootstock`. With the new design:

```dart
/// Generic, works for any chain with swap + AA capability.
class SwapInOperation extends OnchainOperation {
  final ConfiguredEvmChain cchain;
  final SwapInParams params;

  SwapInOperation(this.cchain, this.params)
      : assert(cchain.swaps != null, 'Chain does not support swaps'),
        assert(cchain.aa != null, 'Chain does not support sponsored gas');

  @override
  Future<void> claimRelay() async {
    final etherSwap = await cchain.swaps!.getEtherSwapContract();
    final claimIntent = etherSwap.claimIntent(params.claimArgs);
    await cchain.aa!.userOpService.sendUserOp(claimIntent);
  }
  // ...
}
```

The `Rootstock`-specific swap classes disappear. The swap logic is parameterised by the chain's capabilities, not by its class identity.

---

## 8. Escrow Service — Chain Matching

The `EscrowService` Nostr event (from the reservation NIP or escrow NIP) should include a `chainId` field so the client can route to the correct chain. If the escrow proof references a contract at `0xABC` on chain `42161`:

```
EscrowService {
  chainId: 42161,
  contractAddress: "0xABC...",
  // ...
}
```

Resolution:

```
Evm.getChainForEscrowService(service)
  → chains.firstWhere(c.chain.config.chainId == service.chainId)
  → chain.escrow.getContract(service.contractAddress)
  → SupportedEscrowContractRegistry.fromBytecodeHash(...)
  → MultiEscrowWrapper
```

This replaces the current "return first chain" hack.

---

## 9. Migration Path

### Phase 1: Config restructure (non-breaking)

1. Add `EvmConfig`, `EvmChainConfig.fromJson` and the `EVM_CONFIG` env variable.
2. Create `hostr_sdk/lib/src/evm/escrow/supported_bytecodes.dart` with the current MultiEscrow bytecode hash as the first entry.
3. Add a **migration shim** in `HostrConfig` that constructs `EvmConfig` from the old `rootstockConfig` fields so existing env files keep working.
4. `Evm` starts constructing chains from `config.evmConfig.chains`.

### Phase 2: Extract capabilities + Boltz discovery

1. Add `BoltzClient.discoverChains()` using the existing (but unused) `chainContractsGet()` generated method.
2. Extract `BoltzSwapProvider` from `Rootstock` — move swap logic into the capability. Provider receives `BoltzChainInfo` (with currency symbol) instead of hardcoded `'RBTC'`.
3. Absorb `UserOpService` into `AACapability` / `AAEnabled` (see §5.4) — delete `user_op_service.dart`, remove DI registration. Drop dead `sendUserOpBatch`. Fix `estimateGasFee` stub.
4. Extract `EscrowCapability` from `Rootstock.getSupportedEscrowContractByName` — use global `SupportedEscrowContractRegistry` keyed by bytecode hash.
5. `Evm.initialize()` performs Boltz discovery and attaches swap providers to matching chains.

### Phase 3: Remove Rootstock subclass

1. `Rootstock` becomes a type alias or thin wrapper for `ConfiguredEvmChain` (for DI migration).
2. Swap operations become generic (`SwapInOperation` instead of `RootstockSwapInOperation`).
3. Expand `ChainIds` enum to include Arbitrum (`42161`) and Anvil (`412346`).
4. Delete `Rootstock`, `RootstockSwapInOperation`, `RootstockSwapOutOperation`.

### Phase 4: Clean up env

1. Migrate all environments to `EVM_CONFIG` JSON (or `evm-config.json` file) for Dart consumption.
2. Remove `MULTI_ESCROW_BYTECODE_HASH` entirely (replaced by compiled constant).
3. **Keep `RPC_URL`, `AA_*`, `ESCROW_CONTRACT_ADDRESS`** in `.env` — Docker services (compose entrypoints, hosted paymaster, Hardhat, app build args) still read them as plain env vars.
4. Update `sync-contract-env.sh` to also generate `EVM_CONFIG` from the legacy vars.
5. Remove `contract-addresses.json` consumption from Dart code (keep for deploy scripts + `sync-contract-env.sh` pipeline).
6. Add `dart run hostr_sdk:update_bytecodes` script for Solidity source change workflow.

---

## 10. Final Config Examples

### Production — single chain, Boltz auto-discovers swap support

```json
{
  "boltz": { "apiUrl": "https://api.boltz.exchange/v2" },
  "chains": [
    {
      "id": "arbitrum",
      "chainId": 42161,
      "rpcUrl": "https://arb1.arbitrum.io/rpc",
      "accountAbstraction": {
        "bundlerUrl": "https://paymaster.hostr.network/rpc",
        "entryPointAddress": "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
        "accountFactoryAddress": "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
        "paymasterAddress": "0xABCDEF..."
      }
    }
  ]
}
```

### Dev — two chains, Boltz discovers it can swap on anvil-arbitrum but not sepolia

```json
{
  "boltz": { "apiUrl": "https://boltz.hostr.development/v2" },
  "chains": [
    {
      "id": "anvil-arbitrum",
      "chainId": 412346,
      "rpcUrl": "http://anvil-arbitrum:8545",
      "accountAbstraction": {
        "bundlerUrl": "http://bundler:3000/rpc",
        "entryPointAddress": "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
        "accountFactoryAddress": "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
        "paymasterAddress": "0x0000000000000000000000000000000000000000"
      }
    },
    {
      "id": "sepolia",
      "chainId": 11155111,
      "rpcUrl": "https://rpc.sepolia.org"
    }
  ]
}
```

### Escrow daemon — no Boltz needed, just escrow + AA

```json
{
  "chains": [
    {
      "id": "arbitrum",
      "chainId": 42161,
      "rpcUrl": "https://arb1.arbitrum.io/rpc",
      "accountAbstraction": {
        "bundlerUrl": "https://paymaster.hostr.network/rpc",
        "entryPointAddress": "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
        "accountFactoryAddress": "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
        "paymasterAddress": "0xABCDEF..."
      }
    }
  ]
}
```

Note: **No `boltz` key at all** for the escrow daemon. Swap capability simply doesn't get attached to any chain. Escrow contract support comes from the compiled-in `supportedEscrowBytecodeHashes` constant — zero config.

---

## 11. Dependency Diagram (Target State)

```
                      HostrConfig
                          │
                      EvmConfig
                     /         \
              BoltzConfig?    chains: List<EvmChainConfig>
                  │                     │
                  ▼                     ▼
             BoltzClient          ┌─────┴──────┐
       (discovers chains)         │     Evm    │
             │                    └─────┬──────┘
             │  matchByChainId          │
             └──────────┐     ┌─────────┼─────────────┐
                        ▼     ▼         ▼             ▼
                 ConfiguredEvmChain  ...    ConfiguredEvmChain
                    │    │    │                │    │
                    │    │    └── EscrowCap    │    └── EscrowCap
                    │    └─── AACap           │
                    └──── BoltzSwapProvider   └──── (no swaps, no AA)
                                                    (escrow still works!)
                               ▲
                    (attached at runtime,
                     not from config)

               ┌──────────────────────────────────────┐
               │  supportedEscrowBytecodeHashes        │
               │  (compiled-in Dart constant)          │
               │  ← imported by all packages equally   │
               └──────────────────────────────────────┘
```

```
SwapInOperation ──► ConfiguredEvmChain.swaps  (BoltzSwapProvider, runtime-attached)
                ──► ConfiguredEvmChain.aa     (AACapability)
                ──► ConfiguredEvmChain.chain  (EvmChain — transport)

EscrowFundOp   ──► ConfiguredEvmChain.escrow (EscrowCapability → global registry)
               ──► ConfiguredEvmChain.aa     (AACapability)
               ──► ConfiguredEvmChain.chain  (EvmChain — transport)
```

---

## 12. Key Design Decisions & Rationale

| Decision                                       | Rationale                                                                                                                                                                                                                                                                                    |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Composition over inheritance**               | Capability objects (`BoltzSwapProvider`, `AACapability`, `EscrowCapability`) vs. `Rootstock extends EvmChain`. Avoids combinatorial subclass explosion.                                                                                                                                      |
| **Paymaster is per-chain**                     | Paymaster contracts live on-chain. Cross-chain paymasters don't exist. Bundler endpoints are chain-specific. Putting AA inside each chain config is the only correct model.                                                                                                                  |
| **Escrow bytecodes are global, not per-chain** | The same Solidity source compiles to the same bytecode regardless of which chain it's deployed on. An escrow contract at `0xABC` on Arbitrum and `0xDEF` on Sepolia have the same bytecode hash. Per-chain allow-lists would just duplicate the same hashes.                                 |
| **Escrow bytecodes as compiled Dart constant** | Must be accessible in SDK tests (no file system), Flutter app (mobile + web), and escrow daemon (server). A Dart constant is the only mechanism that works identically in all four contexts without `dart-define` or asset bundling gymnastics.                                              |
| **Boltz support discovered at runtime**        | The Boltz API already has `GET /chain/contracts` which returns all supported EVM chains with their `chainId`. Querying this at startup and matching against configured chains means zero Boltz config per chain. Adding a new Boltz-supported chain = just adding the chain to `EVM_CONFIG`. |
| **`accountAbstraction: null` means raw EOA**   | Chains without paymaster infra fall back to direct transactions.                                                                                                                                                                                                                             |
| **Single JSON config object**                  | `RPC_URL_1`, `RPC_URL_2` is brittle and requires parsing conventions. A single `EVM_CONFIG` JSON object is self-describing, validated by `fromJson`, and composes naturally.                                                                                                                 |
| **Same HD path for all EVM chains**            | BIP-44 coin type 60 (Ethereum) for all chains → same addresses everywhere. This is standard practice (MetaMask, Rainbow, etc.) and gives the simplest UX. Users see one set of addresses across all chains.                                                                                  |
| **Registry keyed by bytecode hash**            | Decouples "which wrapper to use" from deployment addresses. The escrow proof supplies the address; the global registry validates and wraps it.                                                                                                                                               |

---

## 13. Resolved Decisions

1. **`chainId` in escrow proofs** — `EscrowServiceContent` already has a `chainId` field. The `ChainIds` enum (currently only `Rootstock(30)` and `RootstockRegtest(33)`) must be expanded to include Arbitrum (`42161`), the Anvil dev chain (`412346`), and any future chains. This is the routing key for `Evm.getChainForEscrowService()`.

2. **HD key derivation** — Use **BIP-44 coin type 60 (Ethereum) for all EVM chains**. This gives the same set of addresses on every chain, which is standard practice across the ecosystem (MetaMask, Rainbow, Rabby, etc.). Users see one address and can receive/send on any supported chain. Per-chain coin types would fragment the UX with no security benefit (all EVM chains share the same secp256k1 + keccak256 address derivation anyway).

3. **Escrow bytecodes as compiled Dart constant** — Lives in `hostr_sdk/lib/src/evm/escrow/supported_bytecodes.dart` as a `const Map<String, String>` mapping bytecode hash → contract name. Bytecode hashes are **stable across restarts** (same Solidity source → same bytecode → same hash, regardless of nonce/address). They only change when the Solidity source changes, which is a deliberate code change that also requires a new wrapper implementation. Automated via `dart run hostr_sdk:update_bytecodes` (§4.7).

4. **Boltz discovery** — `BoltzClient.discoverChains()` calls `GET /chain/contracts` (already in the generated Swagger client, just unused) and returns `Map<int, BoltzChainInfo>` keyed by `chainId`. Each `BoltzChainInfo` carries the `currency` symbol (e.g. `'RBTC'`, `'tBTC'`), contract addresses, and token mappings. The `BoltzSwapProvider` uses the correct currency for all pair lookups (`getReversePair(currency: info.currency)` instead of hardcoded `'RBTC'`). No per-chain Boltz config needed.

5. **Boltz API failure** — Use backoff with retry at startup. If discovery still fails, boot without swap capability (`swaps = null` on all chains). When a user attempts a swap, throw an actionable error ("Swap service temporarily unavailable"). Optionally retry discovery lazily in the background. This keeps the app functional for escrow-only workflows even when Boltz is down.

6. **Single Boltz instance** — One Boltz API URL per deployment is sufficient. A deployment is either mainnet or testnet, never both. `EvmConfig.boltz` stays a single nullable `BoltzConfig`, not a list.

7. **`contract-addresses.json` stays** — It's the backbone of the automated dev pipeline: Hardhat deploys → writes to JSON → `sync-contract-env.sh` reads → writes to `.env`. Dart code in the SDK/app doesn't read it directly, but the escrow daemon gets its `ESCROW_CONTRACT_ADDRESS` from the env that was populated from it. This pipeline is what makes restarts fully automated.

8. **Env var coexistence** — `RPC_URL`, `AA_*`, and `ESCROW_CONTRACT_ADDRESS` remain in `.env` because Docker services read them as plain env vars. `EVM_CONFIG` is generated alongside them by `sync-contract-env.sh` for Dart consumption. See §1.3.

---

## 14. The .env / Dart / JSON Boundary (Summary)

```
┌─ Solidity source changes (rare) ─────────────────────────────────┐
│                                                                   │
│  Developer modifies MultiEscrow.sol                               │
│       │                                                           │
│       ▼                                                           │
│  dart run hostr_sdk:update_bytecodes                              │
│       │                                                           │
│       ▼                                                           │
│  supported_bytecodes.dart updated (commit to git)                 │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘

┌─ Every restart / docker compose up (frequent, fully automated) ──┐
│                                                                   │
│  contract-deployer → contract-addresses.json                      │
│       │                 (Hardhat writes escrow address)            │
│       │                                                           │
│  contract-deployer (AA) → contract-addresses.json                 │
│       │                    (Pimlico writes AA addresses)           │
│       │                                                           │
│       ▼                                                           │
│  sync-contract-env.sh reads JSON, writes:                         │
│       → ESCROW_CONTRACT_ADDRESS into .env                         │
│       → AA_* addresses into .env                                  │
│       → EVM_CONFIG (generated from RPC_URL + AA_* + BOLTZ_*)      │
│                                                                   │
│  Docker services read plain env vars (RPC_URL, AA_*, etc.)        │
│  Dart reads EVM_CONFIG (falls back to legacy vars if absent)      │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘

┌─ Production / Staging (set once, stable) ────────────────────────┐
│                                                                   │
│  .env.prod / .env.staging:                                        │
│       RPC_URL=https://arb1.arbitrum.io/rpc                        │
│       ESCROW_CONTRACT_ADDRESS=0x...   (set at mainnet deploy)     │
│       AA_*=0x...                      (canonical / set at deploy) │
│       EVM_CONFIG='{...}'              (hand-written or generated) │
│       BOLTZ_API_URL=https://api.boltz.exchange/v2                 │
│                                                                   │
│  Secrets (via GCP Secret Manager):                                │
│       ESCROW_PRIVATE_KEY, etc.                                    │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

**The golden rule:** Addresses change per deployment → `.env` (automated in dev, set once in prod). Bytecode hashes change per Solidity version → Dart constant (automated by script, committed to git). RPC/infra URLs are per environment → `.env`. Nothing is manual on restart.
