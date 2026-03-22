# Pricing & Payment Denomination Spec

> How prices are defined on listings, how hosters declare which payment forms they accept, and how guests verify that enough was deposited.

---

## Table of Contents

- [The Problem](#the-problem)
- [Separation of Concerns](#separation-of-concerns)
- [Layer 1 — Listing Price (What do I charge?)](#layer-1--listing-price-what-do-i-charge)
- [Layer 2 — Accepted Payment Forms (How can I be paid?)](#layer-2--accepted-payment-forms-how-can-i-be-paid)
- [Layer 3 — Escrow Capability (What can the escrow handle?)](#layer-3--escrow-capability-what-can-the-escrow-handle)
- [How the Layers Compose](#how-the-layers-compose)
- [Verification — Proving Enough Was Deposited](#verification--proving-enough-was-deposited)
- [Design Rationale & Alternatives Considered](#design-rationale--alternatives-considered)
- [Examples](#examples)

---

## The Problem

A hoster wants to price a listing at **100,000 sats/night** or **50 USD/night**. But the _denomination_ of a price and the _form_ that payment takes are two different things:

| Concept                | Example                                                       |
| ---------------------- | ------------------------------------------------------------- |
| **Price denomination** | "50 USD per night"                                            |
| **Payment form**       | USDC on Rootstock, USDT on Arbitrum, native BTC on Rootstock… |

A hoster who prices in USD is probably happy to accept _any_ credible USD stablecoin on _any_ chain they trust — they shouldn't need to enumerate every `(chainId, contractAddress)` pair on every listing. Conversely, a hoster who prices in BTC might accept native RBTC on Rootstock _or_ tBTC on Arbitrum.

If we mix these concerns into the listing price tag, the hoster either has to:

1. Publish a separate price tag for every `(token, chain)` combination — explosion of tags, poor UX, and every new chain/token forces a listing update.
2. Pick a single canonical token per listing — loses flexibility and fragments liquidity.

Neither is good. We need to **separate the denomination from the payment rail**.

---

## Separation of Concerns

The system splits pricing into **three independent layers**, each owned by a different Nostr event:

| Layer                         | Event                      | Owner             | Answers                                                  |
| ----------------------------- | -------------------------- | ----------------- | -------------------------------------------------------- |
| **1. Listing Price**          | Listing (kind 32121)       | Hoster            | _"What do I charge, in what denomination?"_              |
| **2. Accepted Payment Forms** | EscrowMethod (kind 30301)  | Hoster (per-user) | _"What concrete tokens/chains am I willing to receive?"_ |
| **3. Escrow Capability**      | EscrowService (kind 30303) | Escrow operator   | _"What tokens can I custody and settle?"_                |

A valid payment path requires all three layers to **intersect**: the guest pays in a token that satisfies the listing's price denomination, that the hoster has declared they accept, and that the chosen escrow can handle.

---

## Layer 1 — Listing Price (What do I charge?)

The listing defines prices in **abstract denominations** — a human-meaningful unit of account, not a specific on-chain token.

### Price tag format

```
["price", "<amount>:<denomination>:<frequency>"]
```

Where `<denomination>` is a **unit of account** identifier:

| Denomination | Meaning                                     | Example tag                         |
| ------------ | ------------------------------------------- | ----------------------------------- |
| `BTC`        | Bitcoin (sats internally, displayed as BTC) | `["price", "0.00100000:BTC:daily"]` |
| `USD`        | US Dollar                                   | `["price", "50.00:USD:daily"]`      |

A listing can have **multiple price tags** in different denominations:

```
["price", "0.00100000:BTC:daily"]
["price", "50.00:USD:daily"]
```

This means: _"I charge 100,000 sats/night **or** 50 USD/night."_ The guest picks whichever denomination works for them, then settles in a concrete token the hoster accepts for that denomination.

### What a denomination is NOT

A denomination is **not** a contract address. `USD` doesn't imply USDC, USDT, or any specific token. `BTC` doesn't imply Lightning, RBTC, or tBTC. The denomination is the unit of account — the concrete payment token is resolved at booking time from the hoster's accepted payment forms (Layer 2).

### Denomination registry

Initially only two denominations exist: `BTC` and `USD`. If needed, new denominations can be added (e.g. `EUR`, `ARS`). Denominations are short uppercase strings, ideally ISO 4217 codes for fiat, and `BTC` for bitcoin.

---

## Layer 2 — Accepted Payment Forms (How can I be paid?)

This is the key new concept. The hoster publishes — **once, per-user, not per-listing** — a signed declaration of which concrete tokens they are willing to receive for each denomination.

### Where it lives: EscrowMethod (kind 30301)

The existing EscrowMethod event (kind 30301, parameterized replaceable, NIP-51 list) already declares the user's escrow capabilities (`t=EVM`, `c=MultiEscrow`). We extend it with **`a` (accepted) tags** that map denominations to concrete tokens:

```
["t", "EVM"]
["c", "MultiEscrow"]

["a", "BTC", "30:0x0000000000000000000000000000000000000000"]
["a", "BTC", "42161:0x1234..."]

["a", "USD", "30:0xdAC17F958D2ee523a2206206994597C13D831ec7"]
["a", "USD", "30:0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]
["a", "USD", "42161:0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"]
```

### Tag schema

```
["a", "<denomination>", "<chainId>:<contractAddress>"]
```

| Field             | Description                                                                     |
| ----------------- | ------------------------------------------------------------------------------- |
| `denomination`    | The unit of account this token satisfies (`BTC`, `USD`, etc.)                   |
| `chainId`         | EVM chain ID where the token lives                                              |
| `contractAddress` | ERC-20 contract address (checksummed EIP-55), or `0x000...000` for native asset |

### Reading the above example

> _"I accept payment for BTC-denominated prices via:_
>
> - _Native RBTC on Rootstock (chain 30)_
> - _tBTC contract `0x1234...` on Arbitrum (chain 42161)_
>
> _I accept payment for USD-denominated prices via:_
>
> - _USDT contract `0xdAC1...` on Rootstock (chain 30)_
> - _USDC contract `0xA0b8...` on Rootstock (chain 30)_
> - _USDT contract `0xFd08...` on Arbitrum (chain 42161)"_

### Why on EscrowMethod, not on the listing?

1. **Publish once, applies to all listings.** A hoster with 20 listings doesn't repeat the same token acceptance map 20 times.
2. **Signed by the hoster's key.** The event is a Nostr event with a valid signature — verifiable proof that the hoster agreed to accept these payment forms.
3. **Already embedded in payment proofs.** The EscrowMethod event is already included in `EscrowProof` and verified by `EscrowVerification.verify()`. Adding `a` tags means the verification can now also prove _"the hoster signed that they accept this specific token for this denomination."_
4. **Independently updatable.** When a new chain or token becomes available, the hoster updates their single EscrowMethod event — no listing edits needed.

### Equivalence and exchange rates

When a listing is priced in `BTC` and the guest pays with RBTC (native BTC on Rootstock), the token _is_ the denomination — no conversion needed. 1 BTC = 1 RBTC by definition (bridged/pegged).

When a listing is priced in `USD` and the guest pays with USDC, the client treats 1 USDC = 1 USD (stablecoin peg). No oracle is required for stablecoin-to-fiat equivalence — the hoster opted into this when they added the `["a", "USD", ...]` tag for that stablecoin.

Cross-denomination payments (e.g. paying a BTC-denominated price with USDC) require an exchange rate. This is out of scope for this spec — the initial implementation requires the guest to pay in a token that matches the listing's denomination.

---

## Layer 3 — Escrow Capability (What can the escrow handle?)

The EscrowService advertisement (kind 30303) declares which tokens the escrow operator supports, with per-token fee schedules.

### Token tags on EscrowService

```
["token", "BTC",                                                 "feeBase:500",    "min:10000",    "max:10000000"]
["token", "30:0xdAC17F958D2ee523a2206206994597C13D831ec7",       "feeBase:100000", "min:1000000",  "max:100000000000"]
["token", "30:0x0000000000000000000000000000000000000000",        "feeBase:500",    "min:10000",    "max:"]
```

Each `["token", ...]` tag declares:

| Position | Value              | Description                                             |
| -------- | ------------------ | ------------------------------------------------------- |
| 1        | Token tag ID       | `"BTC"` for Lightning; `"chainId:address"` for on-chain |
| 2        | `feeBase:<amount>` | Flat fee per trade, in token's smallest unit            |
| 3        | `min:<amount>`     | Minimum escrow amount                                   |
| 4        | `max:<amount>`     | Maximum escrow amount (empty = unlimited)               |

The absence of a `["token", ...]` tag for a given asset means the escrow **does not support** that token. This lets clients filter escrow services by token compatibility.

The `feePercent` field remains top-level on the escrow service (it's token-agnostic — a percentage applies uniformly).

### On-chain allowlist

The `MultiEscrow` smart contract independently maintains an `allowedTokens` mapping. The `["token", ...]` tags in the Nostr event are the _advertisement_; the contract's allowlist is the _enforcement_. Both must agree — the escrow operator is responsible for keeping them in sync.

---

## How the Layers Compose

When a guest wants to book a listing, the client resolves a valid payment path:

```
┌─────────────────────────────────────┐
│  1. Listing Price                   │
│     denomination: USD               │
│     amount: 50.00 / night           │
│     total: 150.00 (3 nights)        │
└──────────────┬──────────────────────┘
               │ "Which tokens satisfy USD?"
               ▼
┌─────────────────────────────────────┐
│  2. Hoster's EscrowMethod           │
│     ["a", "USD", "30:0xdAC17..."]   │  ← USDT on Rootstock
│     ["a", "USD", "30:0xA0b8..."]    │  ← USDC on Rootstock
│     ["a", "USD", "42161:0xFd08..."] │  ← USDT on Arbitrum
└──────────────┬──────────────────────┘
               │ "Which of these can the escrow handle?"
               ▼
┌─────────────────────────────────────┐
│  3. Mutual Escrow's token tags      │
│     ["token", "30:0xdAC17..."]  ✅  │  ← escrow supports USDT on RSK
│     ["token", "30:0xA0b8..."]   ✅  │  ← escrow supports USDC on RSK
│     (no 42161 tags)             ❌  │  ← escrow doesn't support Arbitrum
└──────────────┬──────────────────────┘
               │ intersection
               ▼
┌─────────────────────────────────────┐
│  Valid payment options:             │
│     • 150.00 USDT on Rootstock      │
│     • 150.00 USDC on Rootstock      │
└─────────────────────────────────────┘
```

The client presents only the valid options. The guest picks one and deposits into the escrow contract.

### Resolution algorithm

```
resolve_payment_options(listing, hoster_escrow_method, escrow_service):

  for each price in listing.prices:
    denomination = price.denomination          # e.g. "USD"

    # tokens the hoster accepts for this denomination
    hoster_tokens = hoster_escrow_method
      .tags_where(key='a', denomination=denomination)
      .map(tag => tag.token_id)                # e.g. ["30:0xdAC17...", "30:0xA0b8..."]

    # tokens the escrow can handle
    escrow_tokens = escrow_service
      .tags_where(key='token')
      .map(tag => tag.token_id)                # e.g. ["30:0xdAC17...", "30:0xA0b8...", "BTC"]

    # valid options = intersection
    valid_tokens = hoster_tokens ∩ escrow_tokens

    for each token in valid_tokens:
      emit PaymentOption(
        denomination: denomination,
        amount: price.total_for_stay,
        token: token,
        escrow_fee: escrow_service.fee_for(token),
      )
```

---

## Verification — Proving Enough Was Deposited

After the guest deposits funds, **any party** (the hoster, the guest, a third-party verifier) must be able to confirm that the escrow contract holds sufficient funds to cover the agreed price.

### What gets committed

At the `commit` stage of a reservation, both parties sign a `commitHash` over:

```
hash(start, end, quantity, amount, token, recipient)
```

Where:

- `amount` is the agreed `TokenAmount` (e.g. `150000000` = 150 USDT in smallest unit)
- `token` is the `Token.tagId` (e.g. `30:0xdAC17...`) — the exact contract and chain

Both buyer and seller signatures over this hash constitute **mutual agreement** on the exact denomination, token, and amount.

### On-chain verification

The escrow contract emits a `TradeCreated` event:

```solidity
event TradeCreated(
    bytes32 indexed tradeId,
    address indexed token,     // ERC-20 address or address(0) for native
    address buyer,
    address seller,
    address arbiter,
    uint256 amount,
    uint256 escrowFee,
    uint256 unlockAt
);
```

A verifier checks:

1. **Trade exists on-chain** — query `trades[tradeId]` on the escrow contract, or find the `TradeCreated` event by `tradeId`.
2. **Token matches** — `trade.token` matches the `token` from the signed commit terms.
3. **Amount is sufficient** — `trade.amount >= committed_amount`. (The deposited amount may be slightly higher due to rounding or overpayment; it must not be lower.)
4. **Parties match** — `trade.buyer`, `trade.seller`, `trade.arbiter` match the reservation participants and the chosen escrow service's EVM address.
5. **Contract is legitimate** — the escrow contract address and bytecode hash match those advertised in the `EscrowService` event (kind 30303), and the hoster's `EscrowTrust` (kind 30300) includes the escrow operator's pubkey.

### Proof bundle (EscrowProof)

The `EscrowProof` attached to a reservation contains everything needed for offline verification:

```json
{
  "txHash": "0xabc...",
  "token": "30:0xdAC17...",
  "escrowService": {
    /* signed kind 30303 event */
  },
  "hostsEscrowMethods": {
    /* signed kind 30301 event — includes 'a' tags */
  },
  "hostsTrustedEscrows": {
    /* signed kind 30300 event — includes 'p' tags */
  }
}
```

Verification steps:

| Check                                                                 | Source                                           | Proves                                                         |
| --------------------------------------------------------------------- | ------------------------------------------------ | -------------------------------------------------------------- |
| Hoster signed EscrowMethod containing `["a", "USD", "30:0xdAC17..."]` | `hostsEscrowMethods` event signature             | Hoster consented to receive USDT on RSK for USD prices         |
| Hoster signed EscrowTrust containing `["p", "<escrow_pubkey>"]`       | `hostsTrustedEscrows` event signature            | Hoster trusts this escrow operator                             |
| On-chain trade has correct token, amount, parties                     | `txHash` + contract query                        | Funds are actually locked                                      |
| Contract bytecode matches advertised hash                             | `escrowService.contractBytecodeHash` vs on-chain | Contract is the known audited code, not a malicious substitute |

---

## Design Rationale & Alternatives Considered

### Why not put accepted tokens on the listing?

Considered and rejected. A hoster's willingness to accept USDC on Rootstock is a property of the _hoster_, not of a specific listing. Putting it on listings means:

- Updating 20 listings when you add Arbitrum support
- Duplicated data across every listing
- Larger listing events for no benefit

The listing should say _what_ you charge. The EscrowMethod should say _how_ you can be paid.

### Why not a separate event kind for accepted payment forms?

Considered. A new kind (e.g. 30304) for "AcceptedPaymentTokens" would work, but adds a new event type to fetch, cache, embed in proofs, and verify. The EscrowMethod event already serves the purpose of "how I interact with escrow" — extending it with `a` tags is a natural fit and avoids a new fetch/verify step.

### Why not define accepted tokens on the escrow service alone?

The escrow knows what it _can_ handle, but not what the hoster _wants_ to receive. A hoster might trust an escrow that supports 50 tokens but only want to accept 3 of them. The hoster's intent must be signed by the hoster's key.

### Why not use an oracle for cross-denomination payments?

Out of scope for now. Stablecoin-to-fiat equivalence (1 USDC ≈ 1 USD) is a reasonable assumption the hoster opts into. True cross-denomination payments (pay BTC for a USD listing) require rate locking, oracle trust, and slippage tolerance — complex enough to warrant a separate spec.

### What about Lightning payments?

Lightning BTC is represented as `Token.btcLightning` (chainId: 0, address: "lightning"). A hoster who prices in BTC and accepts Lightning would include:

```
["a", "BTC", "0:lightning"]
```

Lightning payments bypass the escrow contract (they use Boltz swaps or direct zaps) and are verified via the existing `ZapProof` mechanism, not `EscrowProof`. The `a` tag still serves as the hoster's signed consent to accept that payment form.

---

## Examples

### Example 1: BTC-native hoster on Rootstock

**Listing price:**

```
["price", "0.00100000:BTC:daily"]
```

**Hoster's EscrowMethod (kind 30301):**

```
["t", "EVM"]
["c", "MultiEscrow"]
["a", "BTC", "30:0x0000000000000000000000000000000000000000"]
["a", "BTC", "0:lightning"]
```

_"I charge 100k sats/night. Pay me in native RBTC on Rootstock or via Lightning."_

### Example 2: USD-denominated hoster, multiple stablecoins

**Listing price:**

```
["price", "75.00:USD:daily"]
```

**Hoster's EscrowMethod (kind 30301):**

```
["t", "EVM"]
["c", "MultiEscrow"]
["a", "USD", "30:0xdAC17F958D2ee523a2206206994597C13D831ec7"]
["a", "USD", "30:0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]
```

_"I charge $75/night. Pay me in USDT or USDC on Rootstock."_

### Example 3: Dual-denomination hoster

**Listing price:**

```
["price", "0.00100000:BTC:daily"]
["price", "50.00:USD:daily"]
```

**Hoster's EscrowMethod (kind 30301):**

```
["t", "EVM"]
["c", "MultiEscrow"]
["a", "BTC", "30:0x0000000000000000000000000000000000000000"]
["a", "BTC", "0:lightning"]
["a", "USD", "30:0xdAC17F958D2ee523a2206206994597C13D831ec7"]
["a", "USD", "30:0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]
```

_"I charge 100k sats or $50/night. For BTC, pay me native RBTC or Lightning. For USD, USDT or USDC on Rootstock."_

### Example 4: Verifying a deposit

Guest books Example 2 for 3 nights. Commit terms:

```
amount: 225000000   (225 USDT = 225 × 10⁶ in 6-decimal smallest unit)
token:  30:0xdAC17F958D2ee523a2206206994597C13D831ec7
```

On-chain `TradeCreated` event:

```
tradeId: 0x7f3a...
token:   0xdAC17F958D2ee523a2206206994597C13D831ec7  ← matches
amount:  225000000                                     ← matches
buyer:   0xBuyer...
seller:  0xSeller...
arbiter: 0xEscrow...
```

Verifier confirms:

- ✅ Token matches commit terms
- ✅ Amount ≥ committed amount
- ✅ Hoster's EscrowMethod has `["a", "USD", "30:0xdAC17..."]`
- ✅ Hoster's EscrowTrust includes the escrow operator
- ✅ Contract bytecode matches advertised hash

Booking is valid.

---

## Appendix: Optimal Data Structure — Decoupling Listings, Capabilities & Contracts

> **Status**: Design notes. The protocol is not live; no backward compatibility required. All Nostr models can be altered freely.

The three-layer model above is structurally sound. This appendix proposes concrete refinements to make the schema as lean as possible, driven by three observations:

1. **Listings are amounts.** They never reference tokens, chains, or escrows.
2. **Payment capabilities are per-user, not per-listing.** Three independent signed declarations.
3. **Contract identity is bytecode, not a name or chain-address.** A bytecode hash is the only chain-independent way to say "I know how to read this contract."

### A.1 — One Event, Three Declarations

Every participant (buyer or seller) publishes exactly **one Nostr event** — the **EscrowMethod (kind 30301)** — containing **three orthogonal declaration sets** via three tag families:

| Declaration              | Tag family | Answers                                                                          |
| ------------------------ | ---------- | -------------------------------------------------------------------------------- |
| **1. Escrow Trust**      | `p` tags   | "Which escrow operator pubkeys do I trust as arbiters?"                          |
| **2. Contract Literacy** | `c` tags   | "Which escrow contract bytecodes can my client software read and interact with?" |
| **3. Token Acceptance**  | `a` tags   | "Which concrete tokens do I accept, mapped to which denomination?"               |

All three live on the same event because they're all "my escrow preferences" — they share an update cadence (rarely changed), a single signature, and a single relay query. The `p`, `c`, and `a` tag families are logically independent within the event: a user can trust an arbiter (`p`) without accepting any specific token (`a`), and vice versa.

This eliminates the separate EscrowTrust event (kind 30300) entirely. One event per user, one fetch per counterparty.

### A.2 — Contract Identification: Bytecode Hash, Not Name

The current `["c", "MultiEscrow"]` tag uses a human-readable string. Replace it with the **keccak256 hash of the contract's deployed runtime bytecode**:

```
["c", "0x<keccak256(runtime_bytecode)>"]
```

Why this is strictly better:

| Property            | Name (`"MultiEscrow"`)                        | Bytecode hash (`"0xabc1..."`)        |
| ------------------- | --------------------------------------------- | ------------------------------------ |
| Chain-independent   | ✅                                            | ✅                                   |
| Version-precise     | ❌ (v3 vs v4?)                                | ✅ (different code → different hash) |
| Verifiable on-chain | ❌                                            | ✅ (`keccak256(eth_getCode(addr))`)  |
| Collision-free      | ❌ (anyone can name a contract "MultiEscrow") | ✅ (cryptographic)                   |

A user declaring `["c", "0xabc1..."]` means: _"My client software can encode calls to, decode events from, and verify the state of any contract whose runtime bytecode hashes to `0xabc1...`, on any EVM chain."_

This also **eliminates the `["t", "EVM"]` tag**. If you declare a bytecode hash, you implicitly operate on EVM chains. Non-EVM escrow types (if ever needed) would be an entirely different tag family.

### A.3 — The ERC20 → Denomination Mapping

**The problem**: A listing says `50.00:USD:daily`. A token lives at `30:0xdAC17...`. How does the protocol know that token counts as `USD`?

**The answer**: The `["a", ...]` tag **IS** the mapping. No global denomination registry is needed for payment resolution.

```
["a", "USD", "30:0xdAC17F958D2ee523a2206206994597C13D831ec7"]
```

This single tag simultaneously asserts three things:

1. **Acceptance**: "I will receive token `30:0xdAC17...`"
2. **Equivalence**: "I consider it equivalent to the `USD` denomination"
3. **Scope**: "This applies to all my `USD`-priced listings"

The mapping is **per-user and opt-in**. A hoster who doesn't trust USDT simply omits it. The protocol never globally asserts "USDT = USD" — the hoster's cryptographic signature on the `a` tag is the assertion.

#### Native tokens follow the same pattern

| Token type       | `a` tag                          | What it says                                  |
| ---------------- | -------------------------------- | --------------------------------------------- |
| ERC20 stablecoin | `["a", "USD", "30:0xdAC17..."]`  | "USDT on RSK counts as USD for my listings"   |
| Native RBTC      | `["a", "BTC", "30:0x0000…0000"]` | "Native RBTC counts as BTC for my listings"   |
| Lightning BTC    | `["a", "BTC", "0:lightning"]`    | "Lightning sats count as BTC for my listings" |

The zero-address sentinel for native tokens mirrors Solidity's `address(0)` convention and is what the `MultiEscrow` contract already uses. No format special-casing.

#### Token metadata registry (display-only, not protocol)

Separately from payment resolution, the **client app** needs display metadata (symbol, name, decimals, icon) for UX. This is a client-side `TokenRegistry` — a hardcoded table of well-known tokens with an on-chain fallback (`ERC20.symbol()`, `.decimals()`):

```dart
// Client-side only. Not a Nostr event. Not part of payment resolution.
class TokenRegistry {
  static const knownTokens = {
    (30, '0xdAC17...'): (symbol: 'USDT', denomination: 'USD', decimals: 6),
    (30, '0xA0b8...' ): (symbol: 'USDC', denomination: 'USD', decimals: 6),
    (30, '0x0000…0'  ): (symbol: 'RBTC', denomination: 'BTC', decimals: 18),
  };

  // Falls back to on-chain ERC20.name() / .symbol() / .decimals()
  Future<TokenMetadata> resolve(int chainId, String address);
}
```

The registry helps **pre-populate** the hoster's acceptance form ("Suggest: USDT → USD") and **display** friendly names in the booking UI ("Pay 150 USDT on Rootstock"). It has no protocol role.

### A.4 — Revised Event Schemas

#### Listing (kind 32121) — unchanged

```
["price", "50.00:USD:daily"]
["price", "0.00100000:BTC:daily"]
```

Pure denomination + amount. No tokens, no chains, no contracts.

#### EscrowTrust (kind 30300) — eliminated

Merged into EscrowMethod. No separate event needed.

#### EscrowMethod (kind 30301) — the single user event

```
tags: [
  ["d", "escrow-method"],

  // Trusted escrow arbiters (replaces kind 30300)
  ["p", "<escrow_pubkey_1>"],
  ["p", "<escrow_pubkey_2>"],

  // Contract literacy: bytecode hashes I can interact with (chain-independent)
  ["c", "0x<bytecodeHash_MultiEscrow_v3>"],

  // Token acceptance: denomination → concrete token
  ["a", "USD", "30:0xdAC17..."],            // USDT on Rootstock
  ["a", "USD", "30:0xA0b8..."],             // USDC on Rootstock
  ["a", "USD", "42161:0xFd08..."],          // USDT on Arbitrum
  ["a", "BTC", "30:0x0000...0"],            // Native RBTC
  ["a", "BTC", "0:lightning"],              // Lightning
]
```

**Removed**: `["t", "EVM"]` — implied by the presence of a bytecode-hash `c` tag.

**Removed**: kind 30300 (EscrowTrust) — `p` tags now live here. One event carries trust, literacy, and acceptance.

**Changed**: `["c", "MultiEscrow"]` → `["c", "0x<hash>"]` — verifiable, version-precise, chain-independent.

#### EscrowService (kind 30303) — multi-chain

The single biggest structural change. Currently an `EscrowService` has one `chainId` and one `contractAddress`, so an operator running on 3 chains needs 3 events. With bytecode-hash identity, **one event covers all deployments**:

```json
{
  "pubkey": "<escrow_nostr_pubkey>",
  "evmAddress": "<escrow_evm_signer_address>",
  "contractBytecodeHash": "0x<keccak256_of_runtime_bytecode>",
  "feePercent": 1.5,
  "maxDuration": 31536000
}
```

```
tags: [
  // Parameterized replaceable: one event per operator per contract version
  ["d", "<escrow_pubkey>:<bytecodeHash>"],

  // Deployments: where this bytecode is live
  ["deploy", "30",    "0xContractAddrOnRSK"],
  ["deploy", "42161", "0xContractAddrOnArb"],

  // Supported tokens with per-token fees (amounts in token's smallest unit)
  ["token", "30:0xdAC17...",   "feeBase:100000", "min:1000000",  "max:100000000000"],
  ["token", "30:0xA0b8...",    "feeBase:100000", "min:1000000",  "max:100000000000"],
  ["token", "30:0x0000...0",   "feeBase:500",    "min:10000",    "max:10000000"],
  ["token", "42161:0xFd08...", "feeBase:100000", "min:1000000",  "max:100000000000"],
  ["token", "BTC",             "feeBase:500",    "min:10000",    "max:10000000"],
]
```

**Key changes**:

- `chainId` and `contractAddress` **removed from JSON content** — replaced by `deploy` tags
- Each `["deploy", chainId, address]` tag declares one chain where this bytecode is deployed
- `contractBytecodeHash` is **the** identity of the escrow service, not the contract address
- An operator on 5 chains publishes **1 event** instead of 5

The on-chain allowlist enforcement is unchanged: each deployment independently maintains its `allowedTokens` mapping and must agree with the `token` tags.

### A.5 — Revised Intersection Algorithm

```
resolve_payment_options(listing, seller_method, buyer_method):

  # ── Step 0: Mutual trust ──────────────────────────────────────
  # Both events carry p tags — intersect to find mutually trusted arbiters
  seller_trusted = seller_method.p_tags                         # {"pubA", "pubB"}
  buyer_trusted  = buyer_method.p_tags                          # {"pubB", "pubC"}
  mutual_arbiters = seller_trusted ∩ buyer_trusted              # {"pubB"}

  # Fetch EscrowService events (kind 30303) authored by mutual arbiters
  mutual_escrow_services = fetch_escrow_services(mutual_arbiters)

  # ── Step 1: Denomination ──────────────────────────────────────
  # What denominations does the listing offer?
  denominations = listing.prices.map(p => p.denomination)       # {"USD"}

  # ── Step 2: Contract literacy intersection ────────────────────
  # What bytecodes can BOTH buyer and seller interact with?
  mutual_bytecodes = seller_method.c_tags ∩ buyer_method.c_tags # {"0xabc..."}

  # ── Step 3: Per-denomination token resolution ─────────────────
  for denomination in denominations:

    # What tokens does the seller accept for this denomination?
    seller_tokens = seller_method
      .a_tags_for(denomination)
      .map(tokenTagId)                        # {"30:0xdAC17...", "42161:0xFd08..."}

    # ── Step 4: Per-escrow filtering ──────────────────────────
    for escrow in mutual_escrow_services:

      # Does the escrow run a contract we both understand?
      if escrow.bytecodeHash ∉ mutual_bytecodes:
        continue

      # Which of the seller's accepted tokens does this escrow support?
      escrow_tokens = escrow.token_tags.map(tokenTagId)
      valid_tokens = seller_tokens ∩ escrow_tokens

      # Further filter: token must be on a chain where escrow is deployed
      escrow_chains = escrow.deploy_tags.map(chainId)  # {30, 42161}

      for token in valid_tokens:
        token_chain = token.split(':')[0]
        if token_chain ∈ escrow_chains:
          emit PaymentOption(
            denomination,
            amount: listing.total_for(denomination),
            token,
            escrow,
            deploymentAddress: escrow.deployment_for(token_chain),
            fee: escrow.fee_for(token),
          )
```

The entire resolution requires fetching exactly **two counterparty events** (one EscrowMethod per party) plus the EscrowService events for the mutually trusted arbiters. No separate trust-list fetch.

### A.6 — Efficiency Summary

| Metric                             | Current                               | Revised                | Improvement       |
| ---------------------------------- | ------------------------------------- | ---------------------- | ----------------- |
| **Events per user**                | 2 (Trust + Method)                    | **1** (Method only)    | −1 event, −1 kind |
| **Events per escrow operator**     | 1 per (chain × contract)              | 1 per contract version | ÷ N chains        |
| **Relay queries at booking**       | 4 (2 trusts + 2 methods)              | **2** (2 methods)      | −2 queries        |
| **Tags per EscrowMethod**          | `t` + `c` + `a` tags (+ separate `p`) | `p` + `c` + `a` tags   | Net −1 event      |
| **Separate denomination registry** | None needed                           | None needed            | —                 |
| **Contract version ambiguity**     | Possible (`"MultiEscrow"`)            | Impossible (hash)      | Eliminated        |

**Tag count for a typical hoster** trusting 2 escrow operators, accepting 4 tokens across 2 chains, with 1 contract type: 2 `p` tags + 1 `c` tag + 4 `a` tags = **7 tags** in a **single event**. Previously this was 2 `p` tags in one event + 1 `t` + 1 `c` + 4 `a` in another = 8 tags across 2 events — fewer tags, fewer events.

**Tag count for a typical escrow operator** on 3 chains supporting 6 tokens: 1 `d` tag + 3 `deploy` tags + 6 `token` tags = **10 tags** in a single event (vs. 3 events × ~3 tags each = 9 tags across 3 events in the current model — similar total tags but fewer events and fewer relay queries).

### A.7 — Worked Example: Full Payment Resolution

**Setup:**

Listing (kind 32121):

```
["price", "75.00:USD:daily"]
```

Seller's EscrowMethod (kind 30301):

```
["p", "<escrow_pubkey_B>"]                         // trusts escrow B as arbiter
["c", "0xabc123..."]                              // knows MultiEscrow v3
["a", "USD", "30:0xdAC17..."]                     // accepts USDT on RSK
["a", "USD", "42161:0xFd08..."]                   // accepts USDT on Arbitrum
```

Buyer's EscrowMethod (kind 30301):

```
["p", "<escrow_pubkey_B>"]                         // also trusts escrow B
["p", "<escrow_pubkey_C>"]                         // also trusts escrow C
["c", "0xabc123..."]                              // also knows MultiEscrow v3
["a", "BTC", "30:0x0000...0"]                     // (irrelevant — buyer's own acceptance)
```

Escrow B's EscrowService (kind 30303):

```json
{ "contractBytecodeHash": "0xabc123..." }
```

```
["deploy", "30",    "0xEscrowOnRSK"]
["deploy", "42161", "0xEscrowOnArb"]
["token",  "30:0xdAC17...",   "feeBase:100000", "min:1000000", "max:100000000000"]
["token",  "42161:0xFd08...", "feeBase:50000",  "min:500000",  "max:100000000000"]
```

**Resolution:**

1. Mutual arbiters: seller `p` tags `{B}` ∩ buyer `p` tags `{B, C}` = `{B}` → fetch escrow B
2. Denomination: `USD`
3. Mutual bytecodes: `{0xabc123...}` ← both parties' `c` tags intersect
4. Seller's USD tokens: `{30:0xdAC17..., 42161:0xFd08...}`
5. Escrow B's bytecode `0xabc123...` ∈ mutual → proceed
6. Escrow B's tokens: `{30:0xdAC17..., 42161:0xFd08...}`
7. Intersection: `{30:0xdAC17..., 42161:0xFd08...}` — both survive
8. Both tokens' chains (30, 42161) have escrow deployments → both viable

**Result — guest chooses from:**

- 225 USDT on Rootstock (escrow at `0xEscrowOnRSK`, fee: 100000 base + 1.5%)
- 225 USDT on Arbitrum (escrow at `0xEscrowOnArb`, fee: 50000 base + 1.5%)
