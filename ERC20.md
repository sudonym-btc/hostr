# ERC20 Multi-Token Support

> Roadmap for future-proofing Hostr to negotiate prices, lock escrow, and settle payments in ERC20 tokens (USDT, USDC, etc.) alongside native RBTC — powered by Boltz's ERC20 swap upgrade.

## Table of Contents

- [Overview](#overview)
- [Design Principles](#design-principles)
- [1. Models](#1-models)
- [2. Logic (hostr_sdk)](#2-logic-hostr_sdk)
- [3. Multi-Escrow.sol](#3-multi-escrowsol)
- [4. UI](#4-ui)
- [Migration & Rollout Strategy](#migration--rollout-strategy)

---

## Overview

Today, all prices, escrow amounts, fees, and on-chain operations are denominated in BTC (sats). The `Currency` enum has only `{BTC, USD}`, the `EscrowService` advertisement expresses fees/limits in sats, and the `MultiEscrow.sol` contract handles only native RBTC via `msg.value`.

Boltz now supports **ERC20 reverse submarine swaps** (Lightning → ERC20 on Rootstock). The `ERC20Swap` contract bindings and `BoltzRouter` bindings already exist in the codebase (generated but unused). The Boltz API returns token contract addresses via `GET /chain/contracts` → `Contracts.tokens` (e.g. `{"USDT": "0x...", "USDC": "0x..."}`), and the `from`/`to` fields in `ReverseRequest`/`SubmarineRequest` accept arbitrary currency strings like `"USDT"`.

This document defines the changes required at every layer to support multi-token escrow.

---

## Design Principles

### Tokens are identified by contract address, never by name

Any ERC20 contract can call itself "USDT". A listing that says `price: USDT, 50` is meaningless without knowing _which_ USDT contract. Therefore:

- **All on-wire representations (Nostr tags, event content, escrow service advertisements) MUST include the token's contract address and chain ID.**
- Human-readable names (symbol, decimals) are derived client-side by reading the ERC20 contract or by matching the address against a known-token registry.
- A "native" sentinel (e.g. address `0x0000000000000000000000000000000000000000` or a `"native"` string) represents the chain's native asset (RBTC on Rootstock).

### Clean break — no backward compatibility

This is a breaking change across all layers. The `Currency` enum, `Amount`, and `BitcoinAmount` types are replaced wholesale by a unified `Token` + `TokenAmount` model. The `MultiEscrow.sol` contract is updated in-place (redeployed, not proxied). Existing listings, reservations, and escrow service advertisements are republished in the new format. There is no migration path for old events — they are superseded.

---

## 1. Models

### 1.1 Token Identity Model (new)

A new first-class `Token` model that unambiguously identifies any asset:

```
Token:
  chainId:   int              # EVM chain ID (30 = RSK mainnet, 31 = RSK testnet, 33 = regtest)
  address:   String           # ERC20 contract address, checksummed (EIP-55)
                              # "0x0000000000000000000000000000000000000000" for native RBTC

  # Client-resolved (NOT serialized into events — read from chain or registry):
  symbol:    String?          # e.g. "USDT", "RBTC"
  name:      String?          # e.g. "Tether USD"
  decimals:  int?             # e.g. 18, 6
```

The serialized form in Nostr tags is `chainId:address`, e.g. `30:0xdAC17F958D2ee523a2206206994597C13D831ec7`.

A static **known-token registry** ships with the app (similar to Uniswap's token lists) mapping `(chainId, address) → (symbol, name, decimals, logoUri)`. For unknown tokens the client falls back to on-chain `name()`, `symbol()`, `decimals()` calls.

### 1.2 Replace `Currency` + `Amount` + `BitcoinAmount` → `Token` + `TokenAmount`

Delete the `Currency` enum, `Amount` class, and `BitcoinAmount` class. Replace with a single unified model.

**Every monetary value in the system is a `TokenAmount`:**

```dart
class TokenAmount {
  final BigInt value;    // in token's smallest unit (sats, wei, USDT×10⁶, etc.)
  final Token token;

  String toDecimalString() => _formatWithDecimals(value, token.decimals);

  factory TokenAmount.fromDecimal(String decimal, Token token) { ... }

  // EVM helpers (for contract interaction)
  BigInt get asEvm => token.isNative || token.isERC20
      ? value  // already in on-chain smallest unit
      : throw UnsupportedError('Token ${token.address} is not on-chain');
}
```

**`Token` covers every asset type via sentinels:**

| Asset           | `Token`                                                              | `decimals` |
| --------------- | -------------------------------------------------------------------- | ---------- |
| BTC (Lightning) | `Token.btcLightning` → `Token(chainId: 0, address: "lightning")`     | 8          |
| RBTC (native)   | `Token.rbtc(chainId)` → `Token(chainId: 30, address: "0x000...000")` | 18         |
| USDT on RSK     | `Token(chainId: 30, address: "0xdAC17...")`                          | 6          |
| USDC on RSK     | `Token(chainId: 30, address: "0xA0b8...")`                           | 6          |

```dart
class Token {
  final int chainId;
  final String address;   // checksummed EIP-55; "lightning" sentinel for LN-BTC; address(0) for native
  final int decimals;     // resolved from registry or on-chain call

  bool get isLightning => address == 'lightning';
  bool get isNative => address == '0x0000000000000000000000000000000000000000';
  bool get isERC20 => !isLightning && !isNative;

  // Serialized form for Nostr tags
  String get tagId => isLightning ? 'BTC' : '$chainId:$address';

  // Well-known constants
  static final btcLightning = Token(chainId: 0, address: 'lightning', decimals: 8);
  static Token rbtc(int chainId) => Token(chainId: chainId, address: '0x' + '0' * 40, decimals: 18);
}
```

This eliminates the `Currency` enum entirely. Every price, reservation amount, escrow fee, and on-chain value is a `TokenAmount`. The `BitcoinAmount` class (which hardcoded 18 decimals) is deleted — `TokenAmount` reads decimals from `token.decimals` and handles the conversion generically.

### 1.3 Listing Price Tags

**Current tag format (deleted):**

```
["price", "0.00050000:BTC:daily"]   # old — gone
```

**New tag format — all prices use `Token.tagId`:**

```
["price", "0.00050000:BTC:daily"]                                          # BTC Lightning ("BTC" is Token.btcLightning.tagId)
["price", "50.000000:30:0xdAC17F958D2ee523a2206206994597C13D831ec7:daily"]  # 50 USDT on RSK mainnet
["price", "0.01000000:30:0x0000000000000000000000000000000000000000:daily"]  # 0.01 RBTC (native)
```

Format is always `"decimalAmount:tokenTagId:frequency"`, where `tokenTagId` is `Token.tagId`:

- BTC Lightning → `"BTC"` (3 segments: `amount:BTC:frequency`)
- On-chain tokens → `"chainId:address"` (4 segments: `amount:chainId:address:frequency`)

**A listing can advertise multiple price tags** (it already supports `List<Price>`), enabling dual-denomination: e.g. "50,000 sats/night **or** 50 USDT/night". Clients display whichever denomination the user prefers.

#### Parsing logic (ListingTagRead)

`Price.fromTag(tag)` splits on `:` and dispatches:

1. 3 segments → `[amount, "BTC", frequency]` → `Token.btcLightning`
2. 4 segments → `[amount, chainId, address, frequency]` → `Token(chainId, address)`
3. Anything else → reject

### 1.4 Reservation Amount

**Current content field (deleted):**

```json
{ "amount": { "value": "0.00050000", "currency": "BTC" } }
```

**New content field — always a `TokenAmount`:**

```json
{ "amount": { "value": "50.000000", "token": "30:0xdAC17..." } }
```

For BTC Lightning:

```json
{ "amount": { "value": "0.00050000", "token": "BTC" } }
```

The `token` field is the `Token.tagId` string. The `CommitTerms` hash (which locks `{start, end, quantity, amount, recipient}`) includes the full `token` tag ID so both parties commit to the exact denomination and contract address.

### 1.5 Escrow Service Advertisement

**Current model (kind 30303) — deleted:**

```
feeBase:    int      # flat fee in sats      ← removed
feePercent: double   # percentage fee         ← kept (token-agnostic)
minAmount:  int      # min escrow in sats     ← removed
maxAmount:  int?     # max escrow in sats     ← removed
```

These are BTC-only. The escrow service must advertise **per-token capabilities** — which tokens it accepts and the fee/limit schedule for each.

**New model — per-token fee/limit schedule replaces top-level fields:**

The top-level `feeBase`/`minAmount`/`maxAmount` are removed. Everything is expressed per-token via repeated `["token", ...]` tags. `feePercent` remains top-level since it's naturally token-agnostic.

```
feePercent: double                          # proportional fee (e.g. 1.5 = 1.5%), applies to all tokens

# Per-token capabilities:
["token", "BTC",           "feeBase:500",    "min:10000",    "max:10000000"]
["token", "30:0xdAC17...", "feeBase:100000", "min:1000000", "max:100000000000"]
["token", "30:0x0000...0", "feeBase:500",    "min:10000",    "max:"]
```

Each `["token", ...]` tag contains:

1. Token tag ID (`Token.tagId` — `"BTC"` for Lightning, `"chainId:address"` for on-chain)
2. Fee/limit parameters for that token (amounts in the token's smallest unit)

The absence of a `["token", ...]` tag for a given asset means the escrow service does **not** support that token. Clients filter escrow services by checking which token tags are present.

The `contractAddress` and `contractBytecodeHash` fields continue to point to the updated MultiEscrow contract (same contract, now with ERC20 support).

### 1.6 PaymentProof (EscrowProof)

**Current:** `EscrowProof` contains a `txHash` (string). This is sufficient — the tx hash points to the on-chain transaction regardless of whether it moved RBTC or an ERC20. No model change needed, but consumers resolving proof on-chain need to know which token to check for `Transfer` events.

**Change:** Include `token` as a required field in `EscrowProof`:

```json
{
  "txHash": "0xabc...",
  "escrowService": "...",
  "token": "30:0xdAC17..." // Token.tagId — required
}
```

### 1.7 GiftWraps / Sealed Messages

No changes needed. Gift wraps (NIP-59) are a transport/encryption layer. The `Reservation` events they carry will naturally contain the new token-aware amount fields.

### 1.8 Delete `BitcoinAmount`

`BitcoinAmount` is deleted. `TokenAmount` (defined in 1.2) replaces it everywhere — in `SwapInOperation`, `EscrowFundOperation`, `MultiEscrowWrapper`, `RifRelay`, `GasEstimate`, and all fee calculation code.

Every place that currently does `BitcoinAmount.fromAmount(amount)` becomes just `amount` (since `amount` is already a `TokenAmount`). Every place that does `bitcoinAmount.toAmount()` is also eliminated — there is no conversion step, just one type throughout the stack.

---

## 2. Logic (hostr_sdk)

### 2.1 Boltz Client Changes

The `BoltzClient` currently hardcodes `from: 'BTC', to: 'RBTC'` for reverse swaps. Changes needed:

#### a) Token-aware pair fetching

```dart
// Current
Future<ReversePair> getReversePair() → fetches BTC/RBTC pair

// New
Future<ReversePair> getReversePair({required String from, required String to})
// e.g. getReversePair(from: 'BTC', to: 'USDT')
```

The Boltz API already returns pairs keyed by strings like `"BTC/USDT"`, `"BTC/RBTC"`. We just need to parameterize the lookup.

#### b) Token-aware swap creation

```dart
// Current
Future<ReverseSwap> reverseSubmarine({
  required int invoiceAmount,
  required String preimageHash,
  required String claimAddress,
}) → always sends from: 'BTC', to: 'RBTC'

// New
Future<ReverseSwap> reverseSubmarine({
  required String from,         // 'BTC'
  required String to,           // 'RBTC', 'USDT', etc.
  required int invoiceAmount,
  required String preimageHash,
  required String claimAddress,
})
```

#### c) Contract address resolution

```dart
// Current: boltz.rbtcContracts() → returns only EtherSwap address
// New: also resolve ERC20Swap address and token addresses

Future<BoltzContracts> getContracts() → {
  etherSwap: EthereumAddress,
  erc20Swap: EthereumAddress,
  tokens: Map<String, EthereumAddress>,  // {"USDT": "0x...", ...}
}
```

The Boltz API's `GET /chain/contracts` already returns `swapContracts.eRC20Swap` and `tokens` — we just need to stop ignoring them.

### 2.2 Rootstock Chain Configuration

`Rootstock` (the only `EvmChain` impl) needs:

```dart
// Current
Future<EtherSwap> getEtherSwapContract()

// New
Future<EtherSwap> getEtherSwapContract()          // unchanged
Future<ERC20Swap> getERC20SwapContract()           // new
Future<EthereumAddress?> getTokenAddress(String symbol)  // new — from Boltz contracts endpoint
```

The `getSupportedEscrowContract()` method returns the updated `MultiEscrowWrapper` which now handles both native and ERC20 trades. No versioning needed — the contract is updated in-place.

### 2.3 Swap-In Operation (Lightning → ERC20)

The current `SwapInOperation` (919-line state machine) does:

1. Create reverse swap (BTC → RBTC) via Boltz
2. Pay Lightning invoice
3. Wait for on-chain lockup on `EtherSwap`
4. Claim RBTC from `EtherSwap`

For ERC20, the flow changes at steps 1, 3, and 4:

| Step           | RBTC (current)                              | ERC20 (new)                                                   |
| -------------- | ------------------------------------------- | ------------------------------------------------------------- |
| 1. Create swap | `reverseSubmarine(from: 'BTC', to: 'RBTC')` | `reverseSubmarine(from: 'BTC', to: 'USDT')`                   |
| 2. Pay invoice | Same                                        | Same                                                          |
| 3. Wait lockup | Listen for `EtherSwap.Lockup` event         | Listen for `ERC20Swap.Lockup` event (includes `tokenAddress`) |
| 4. Claim       | `EtherSwap.claim(preimage, amount, ...)`    | `ERC20Swap.claim(preimage, amount, tokenAddress, ...)`        |

**Key code changes in `SwapInOperation`:**

- `_scanForLockupEvent()` currently scans `EtherSwap` — needs to branch on token type to scan `ERC20Swap` instead.
- `_verifyLockup()` currently checks `msg.value` equivalence — for ERC20 it checks the `amount` and `tokenAddress` fields in the `Lockup` event.
- `_claimSwap()` / `_buildClaimArgs()` must build `ERC20Swap.claim` args (which include `tokenAddress`) instead of `EtherSwap.claim` args.
- `SwapInParams` gets a required `Token targetToken` field. The operation branches on `targetToken.isNative` vs `targetToken.isERC20` to choose the `EtherSwap` or `ERC20Swap` claim path.

**Cooperative claim signing (EIP-712):** The current EIP-712 `TYPEHASH_CLAIM` is specific to `EtherSwap`. For ERC20, Boltz may use a different typehash that includes `tokenAddress`. This needs to be verified against the Boltz ERC20 swap documentation.

### 2.4 Atomic Claim-and-Fund (ERC20 path)

Today, `claimSwapAndFund` on `MultiEscrow.sol` atomically claims RBTC from `EtherSwap` and deposits it. For ERC20:

1. **Claim** from `ERC20Swap` → contract receives ERC20 tokens
2. **Approve** `MultiEscrow` to spend those tokens (or use Permit2)
3. **Fund** escrow with the ERC20 tokens

This is a multi-step flow that cannot be as cleanly atomic in a single call without a router contract. Two approaches:

**Option A: BoltzRouter integration**
The `BoltzRouter` contract (bindings already generated) has `claimERC20Call` — claim from `ERC20Swap` and call an arbitrary contract. We could:

1. `BoltzRouter.claimERC20Call(claim, callee=MultiEscrow, callData=fund(...))` — but this requires the MultiEscrow to accept ERC20 `transferFrom` in its `fund()`.

**Option B: New `claimERC20SwapAndFund` on MultiEscrow**
Add a dedicated function to the updated MultiEscrow that:

1. Calls `ERC20Swap.claim()` (tokens land in MultiEscrow)
2. Records the trade with the token amount
3. All in one transaction

Option B is preferred for auditability and control. See section 3.

### 2.5 Fee Estimation

`EscrowFundFees` is rewritten to use `TokenAmount` throughout, naturally handling mixed-denomination fees:

```dart
class EscrowFundFees {
  final TokenAmount swapFee;     // BTC Lightning (Boltz charges in the invoice)
  final TokenAmount gasFee;      // RBTC (EVM gas — always native)
  final TokenAmount escrowFee;   // in the trade token (e.g. USDT)
  final TokenAmount tradeAmount; // in the trade token
}
```

Since each `TokenAmount` carries its `Token`, the UI can format each fee in its correct denomination without any special-case logic. The old `BitcoinAmount`-only model is gone.

### 2.6 Token Registry & Metadata Resolution

A new `TokenRegistry` service in hostr_sdk:

```dart
class TokenRegistry {
  // Static known tokens (bundled with app)
  Map<(int chainId, String address), TokenMetadata> knownTokens;

  // Resolve from chain if not known
  Future<TokenMetadata> resolve(int chainId, String address);

  // Tokens supported by Boltz (fetched from API)
  Future<List<Token>> boltzSupportedTokens();

  // Tokens supported by a specific escrow service
  List<Token> escrowSupportedTokens(EscrowService service);
}
```

This is queried when displaying prices, validating listings, and populating currency pickers.

### 2.7 ERC20 Approval Flow

Before depositing ERC20 tokens into any contract (`ERC20Swap.lock` or `MultiEscrow.fund`), the user must `approve()` the contract to spend their tokens. This introduces a new transaction step:

1. Check current allowance via `token.allowance(owner, spender)`
2. If insufficient, prompt `token.approve(spender, amount)` — a separate on-chain tx
3. Proceed with the deposit

For gasless/RIF Relay flows, the approval can be batched. Alternatively, **Permit2** (already referenced in the `BoltzRouter` bindings) enables signature-based approvals without a separate tx.

---

## 3. Multi-Escrow.sol

### 3.1 Current Contract Limitations

The current `MultiEscrow.sol` is **native-RBTC only**:

- `fund()` is `payable` — deposits come from `msg.value`
- `claimSwapAndFund()` claims from `IEtherSwap` (native ETH/RBTC swaps only)
- `_settleTrade()` sends funds via low-level `.call{value: amount}("")`
- The `Trade` struct has no token address field
- Escrow fee is denominated in the same native currency

### 3.2 Required Changes

#### a) Trade Struct — add token identity

```solidity
struct Trade {
    address buyer;
    address seller;
    address arbiter;
    uint256 amount;
    uint256 escrowFee;
    uint256 unlockAt;
    address token;     // NEW: ERC20 token address, or address(0) for native RBTC
}
```

#### b) Unified `fund` function

Replace the old `fund() payable` with a single function that handles both native and ERC20:

```solidity
function fund(
    bytes32 tradeId, address buyer, address seller,
    address arbiter, uint256 unlockAt, uint256 escrowFee,
    address token, uint256 amount
) external payable {
    if (token == address(0)) {
        // Native RBTC — amount comes from msg.value
        require(msg.value > 0, "MustSendFunds");
        _createTrade(tradeId, buyer, seller, arbiter, msg.value, escrowFee, unlockAt, address(0));
    } else {
        // ERC20 — validate allowlist, pull tokens via transferFrom
        require(allowedTokens[token], "TokenNotAllowed");
        require(msg.value == 0, "NativeNotExpected");
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 received = IERC20(token).balanceOf(address(this)) - balanceBefore;
        _createTrade(tradeId, buyer, seller, arbiter, received, escrowFee, unlockAt, token);
    }
}
```

The old no-token `fund()` signature is removed. All callers pass `token` and `amount` explicitly. For native RBTC, callers pass `token = address(0)` and send `msg.value`. For ERC20, callers `approve()` first and pass the token address + amount.

#### c) Settlement — token-aware transfers

```solidity
function _settleTrade(...) internal {
    Trade storage trade = trades[tradeId];
    address token = trade.token;

    // ... remove from active set, delete trade ...

    if (token == address(0)) {
        // Native RBTC (current logic)
        _transferNative(arbiter, escrowFee);
        _transferNative(recipient1, amount1);
        // ...
    } else {
        // ERC20
        IERC20(token).transfer(arbiter, escrowFee);
        IERC20(token).transfer(recipient1, amount1);
        // ...
    }
}
```

Use OpenZeppelin's `SafeERC20` for `safeTransfer`/`safeTransferFrom` to handle non-standard ERC20s (like USDT which doesn't return `bool`).

#### d) Atomic claim-and-fund for ERC20 swaps

```solidity
// New interface for ERC20 swap contracts
interface IERC20Swap {
    function claim(
        bytes32 preimage, uint256 amount, address tokenAddress,
        address refundAddress, uint256 timelock,
        uint8 v, bytes32 r, bytes32 s
    ) external returns (address);
}

function claimERC20SwapAndFund(
    ClaimArgs[] calldata claimArgs,
    address erc20SwapContract,     // Boltz ERC20Swap address
    address token,                 // ERC20 token being claimed
    FundArgs calldata fundArgs
) external {
    // Validate erc20SwapContract is a known Boltz contract (see 3.2e)

    uint256 balanceBefore = IERC20(token).balanceOf(address(this));

    // Claim from each swap (tokens land in this contract)
    for (uint i = 0; i < claimArgs.length; i++) {
        IERC20Swap(erc20SwapContract).claim(
            claimArgs[i].preimage,
            claimArgs[i].amount,
            token,
            claimArgs[i].refundAddress,
            claimArgs[i].timelock,
            claimArgs[i].v,
            claimArgs[i].r,
            claimArgs[i].s
        );
    }

    uint256 received = IERC20(token).balanceOf(address(this)) - balanceBefore;
    require(received >= fundArgs.amount, "InsufficientClaimAmount");

    _createTrade(
        fundArgs.tradeId, fundArgs.buyer, fundArgs.seller,
        fundArgs.arbiter, fundArgs.amount, fundArgs.escrowFee,
        fundArgs.unlockAt, token
    );
}
```

> **Note:** Unlike the native `claimSwapAndFund` where the claim return value is ETH sent to the contract via the claim function's own transfer, for ERC20 the tokens arrive via `transfer` inside the `ERC20Swap.claim` function. The MultiEscrow checks its balance delta to confirm receipt.

#### e) Token allowlist

To prevent locking arbitrary (potentially malicious) ERC20 tokens:

```solidity
mapping(address => bool) public allowedTokens;
address public owner;  // or use a governance mechanism

function setTokenAllowed(address token, bool allowed) external onlyOwner {
    allowedTokens[token] = allowed;
    emit TokenAllowlistUpdated(token, allowed);
}
```

This is critical: only tokens vetted by the escrow operator should be accepted. The allowlist is managed off-chain by the escrow service operator.

#### f) EIP-712 Typed Data Updates

The `ReleaseAuthorization` and `ClaimAuthorization` EIP-712 types must include the token address to prevent cross-token replay:

```solidity
bytes32 constant RELEASE_AUTHORIZATION_TYPEHASH = keccak256(
    "ReleaseAuthorization(bytes32 tradeId,address token,uint256 relayFee,address relayFeeReceiver,uint256 expiry)"
);

bytes32 constant CLAIM_AUTHORIZATION_TYPEHASH = keccak256(
    "ClaimAuthorization(bytes32 tradeId,address token,uint256 relayFee,address relayFeeReceiver,uint256 expiry)"
);
```

#### g) Events — add token field

```solidity
event TradeCreated(bytes32 indexed tradeId, address indexed token, ...);
event Claimed(bytes32 indexed tradeId, address indexed token, ...);
event ReleasedToCounterparty(bytes32 indexed tradeId, address indexed token, ...);
event Arbitrated(bytes32 indexed tradeId, address indexed token, ...);
```

#### h) Relay Fee Token

For gasless/meta-tx flows, the relay fee is currently deducted from the escrowed RBTC. With ERC20 trades, the relay fee could be:

- Deducted from the escrowed ERC20 tokens (simplest — relay gets paid in USDT), or
- Paid separately in native RBTC (requires `msg.value` alongside the ERC20 flow)

Option 1 (deduct from escrowed tokens) is recommended for simplicity — the RIF Relay server would need to accept ERC20 tokens as payment, or the relay fee can be settled off-band.

### 3.3 Contract Deployment Strategy

- **Redeploy the updated `MultiEscrow`** to a new address (same contract name, new bytecode with ERC20 support)
- Drain or settle any active trades on the old contract before cutover
- Escrow operators publish an updated `EscrowService` event (kind 30303) with the new contract address and `contractBytecodeHash`
- The Hardhat deploy task writes the new address to the deployed-addresses registry, overwriting the old entry
- No proxy, no V2 naming — it's just `MultiEscrow` with ERC20 support baked in

### 3.4 Security Considerations

| Risk                                          | Mitigation                                                                 |
| --------------------------------------------- | -------------------------------------------------------------------------- |
| Malicious ERC20 with reentrancy in `transfer` | Use `ReentrancyGuard` (OpenZeppelin); checks-effects-interactions pattern  |
| Fee-on-transfer tokens (deflationary)         | Check balance delta after `transferFrom`, not the `amount` parameter       |
| Tokens with blocklists (USDC)                 | The allowlist + balance-delta check handles this; blocked transfers revert |
| Non-standard ERC20 (no return value)          | Use `SafeERC20.safeTransfer` / `safeTransferFrom`                          |
| Infinite approval exploit                     | Users approve exact amounts per trade, not unlimited                       |
| Cross-token replay of EIP-712 signatures      | Include `token` in typed data hash (see 3.2f)                              |

---

## 4. UI

### 4.1 Token Display

#### Format Amount

`formatAmount(Amount)` is replaced by `formatTokenAmount(TokenAmount)`. Since `TokenAmount` always carries its `Token`, the formatter:

- Reads `token.decimals` directly (no registry lookup needed for formatting)
- Resolves symbol from `TokenRegistry` for display
- BTC Lightning: `"₿ 50,000"` (prefix, sats) — uses `Token.btcLightning`
- RBTC native: `"0.001 RBTC"` (suffix)
- ERC20: `"50.00 USDT"` or `"1,500.00 USDC"` (suffix, symbol from registry)
- Unknown tokens: `"50.00 0xdAC1...ec7"` (truncated address as fallback symbol)

#### Price Tags on Listings

Listings with multiple price denominations show the user's preferred currency first:

```
₿ 50,000 / night          ← user prefers BTC
  also: 50.00 USDT / night  ← secondary denomination (smaller, muted text)
```

Or if the user prefers USD stablecoins:

```
50.00 USDT / night
  also: ₿ 50,000 / night
```

### 4.2 Currency Picker

#### Listing Creation

Replace the hardcoded BTC assumption in `ListingPriceFieldController` with a token selector:

- Dropdown/segmented control: **BTC** | **USDT** | **USDC** | **Custom token**
- "Custom token" opens an address input field (advanced/power-user feature)
- When an ERC20 is selected, the input field switches to decimal mode with the correct precision (e.g. 6 decimals for USDT)
- Allow adding **multiple prices** in different denominations (the `List<Price>` model already supports this)

#### Reservation / Barter

The `AmountEditorBottomSheet` (barter pricing) needs a token selector if the listing supports multiple denominations. The negotiated amount must specify which token it's in.

### 4.3 Escrow Service Display

When browsing/selecting escrow services:

- Show which tokens the escrow supports (icons/badges for USDT, USDC, RBTC)
- Show fee schedule per token: "1.5% + 100 sats (BTC) · 1.5% + 0.10 USDT"
- Filter escrow services by supported token (only show services that can handle the reservation's token)

### 4.4 Payment Flow

The `EscrowFundWidget` flow changes:

1. **Token confirmation step**: Before funding, confirm the token and amount: "You are locking **50.00 USDT** in escrow"
2. **Approval step** (ERC20 only): "Approve MultiEscrow to spend 50.00 USDT" → tx confirmation → wait for receipt
3. **Fund step**: Proceed with `fund(token, amount)` or `claimERC20SwapAndFund`
4. **Fee breakdown**: Show fees in mixed denominations:
   - Swap fee: ₿ 500 (paid in Lightning invoice)
   - Gas fee: 0.0001 RBTC
   - Escrow fee: 0.50 USDT (deducted from escrowed amount)

### 4.5 User Preferences

Add a **preferred currency** setting:

- Default display currency for prices (BTC / USDT / USDC)
- Auto-conversion display (show equivalent in preferred currency using exchange rate)
- This is display-only — the on-chain settlement token is always explicit

### 4.6 Map Markers & Search

`PriceMarkerBuilder` for map pins currently shows the first price. With multi-denomination:

- Show price in user's preferred currency if available
- Fall back to first listed price
- Search filters: "Show listings priced in: [BTC] [USDT] [USDC] [Any]"

---

## Rollout Strategy

### Phase 1: Core Refactor (models + contract)

- [ ] Implement `Token` model and `TokenRegistry` with known-token list
- [ ] Replace `Currency` enum, `Amount`, and `BitcoinAmount` with `Token` + `TokenAmount` across the entire codebase
- [ ] Update all Nostr event serialization (listing tags, reservation content, escrow service tags)
- [ ] Update `MultiEscrow.sol` with ERC20 support (unified `fund`, `claimERC20SwapAndFund`, token allowlist, EIP-712 updates)
- [ ] Deploy updated MultiEscrow to regtest
- [ ] Write comprehensive contract tests (fund, claim, release, arbitrate — for both native and ERC20)
- [ ] Update `MultiEscrowWrapper` Dart bindings and regenerate ABIs

### Phase 2: SDK + Swap Integration

- [ ] Make `BoltzClient` token-aware (parameterized pairs, contract resolution, token address map)
- [ ] Add `getERC20SwapContract()` to `Rootstock`
- [ ] Parameterize `SwapInOperation` with `Token targetToken` — branch on native vs ERC20 paths
- [ ] Implement `claimERC20SwapAndFund` in `MultiEscrowWrapper`
- [ ] Implement ERC20 approval flow
- [ ] Rewrite `EscrowService` model with per-token `["token", ...]` tags
- [ ] Rewrite `EscrowFundOperation` and `EscrowFundFees` with `TokenAmount`
- [ ] Update `RifRelay` for ERC20 relay flows

### Phase 3: UI

- [ ] Replace `formatAmount` with `formatTokenAmount`
- [ ] Add token selector to listing creation (replace hardcoded BTC)
- [ ] Update all price display widgets (price tags, map markers, reservation details)
- [ ] Add token selector to barter/negotiation flow
- [ ] Update escrow service browser with token support badges and filtering
- [ ] Add ERC20 approval step to payment flow UI
- [ ] Add user preferred-token setting

### Phase 4: Mainnet

- [ ] Audit updated MultiEscrow contract
- [ ] Deploy to RSK mainnet
- [ ] Coordinate with Boltz for mainnet ERC20 swap pairs
- [ ] Populate known-token registry with mainnet token addresses
- [ ] Escrow operators republish service advertisements with new format
- [ ] All users republish listings in new tag format
