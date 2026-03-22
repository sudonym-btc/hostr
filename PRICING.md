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
