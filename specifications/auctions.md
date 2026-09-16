NIP-XX
======

Marketplace Auctions
--------------------

`draft` `optional`

This NIP defines auction events for marketplace listings. A listing describes
what is being sold. An auction describes how that listing is being sold for a
limited period of time.

The auction event is intentionally separate from the listing event. This allows
the same listing to be sold fixed-price, auctioned, re-auctioned, or auctioned
through different coordinators without mutating the canonical listing.

## Design Goals

- Keep marketplace listings as normal `kind:30402` classified listing events.
- Attach auctions to listings with a separate addressable event.
- Reuse the marketplace payment lifecycle for bid collateral and payment proof.
- Require exactly one auction arbiter/coordinator per auction.
- Allow the arbiter to support multiple payment methods, such as Cashu and EVM,
  without making the auction event method-specific.
- Avoid split-brain auctions where different arbiters observe different bid
  sets, clocks, or winner state.

## Event Kinds

The following kind numbers are proposal values.

| Kind | Name | Description |
| --- | --- | --- |
| `30421` | Marketplace auction | Addressable auction attached to a listing |
| `1023` | Auction bid | Bid intent authored by the bidder's temporary trade key |
| `1024` | Auction complete | Final auction result and winner declaration |

This NIP also reuses the marketplace payment lifecycle:

| Kind | Name | Description |
| --- | --- | --- |
| `32123` | Marketplace payment | Payment proof or locked bid collateral |
| `32124` | Marketplace payment ack | Arbiter accepts the payment-backed bid |
| `32127` | Marketplace payment nack | Arbiter rejects the payment-backed bid |
| `32125` | Marketplace payment settlement | Release, payout, or refund action |

## The One-Arbiter Rule

Each auction MUST declare exactly one auction arbiter. Only this arbiter can
accept bids, reject bids, compute the effective close, refund losing bids,
promote the winning bid-chain payments into order escrow, and publish the final
auction complete event.

This is required because auctions have global state:

- current high bid
- valid bid set
- anti-sniping window
- reserve satisfaction
- winner
- loser refunds

If two arbiters independently accept bids, they can observe different payment
methods, different clocks, and different bid histories. That creates two
parallel auctions instead of one auction.

Seller arbitration methods and trusted arbiters are used for discovery before an
auction is created. Once an auction is published, the auction event pins one
arbiter pubkey for that auction.

## Marketplace Auction Event

A marketplace auction is a parameterized replaceable event of kind `30421`.

The auction event MUST include:

- a `d` tag identifying the auction
- an `a` tag referencing the listing being auctioned
- exactly one `p` tag with marker `auction-arbiter`
- a currency and decimal precision
- timing rules
- bid amount rules

The auction event SHOULD NOT be tied to one concrete payment method unless the
auction is intentionally single-method. Bidders choose a method from the
intersection of:

- the seller's advertised arbitration/payment methods
- the auction arbiter's advertised capabilities
- the auction currency
- the bidder's wallet capabilities

### Example

```jsonc
{
  "kind": 30421,
  "pubkey": "<seller-pubkey>",
  "created_at": 1766200000,
  "tags": [
    ["d", "auction-123"],
    ["a", "30402:<seller-pubkey>:listing-456", "", "listing"],
    ["p", "<arbiter-pubkey>", "", "auction-arbiter"],

    ["currency", "USD"],
    ["decimals", "2"],

    ["auction_type", "english"],
    ["start_at", "1766202000"],
    ["end_at", "1766288400"],
    ["max_end_at", "1766289000"],
    ["settlement_grace", "3600"],

    ["starting_bid", "10000"],
    ["min_increment", "500"],
    ["reserve", "25000"]
  ],
  "content": ""
}
```

### Required Tags

#### `d`

Unique auction identifier.

```json
["d", "<auction-id>"]
```

#### `a` listing reference

Addressable reference to the listing being auctioned.

```json
["a", "30402:<seller-pubkey>:<listing-d-tag>", "", "listing"]
```

The listing remains the canonical product or service description. The auction
event only describes the sale mechanism.

#### `p` auction arbiter

The auction arbiter pubkey.

```json
["p", "<arbiter-pubkey>", "", "auction-arbiter"]
```

Clients MUST ignore bid acknowledgments, bid rejections, and auction complete
events that are not authored by this pubkey, unless a future extension defines
delegated arbiter signing.

#### Currency

```json
["currency", "USD"]
["decimals", "2"]
```

All bid amounts are integers in the currency's minor unit. For example, with
`USD` and `decimals=2`, `12500` means USD 125.00.

For sat-denominated auctions:

```json
["currency", "SAT"]
["decimals", "0"]
```

#### Timing

```json
["start_at", "<unix-seconds>"]
["end_at", "<unix-seconds>"]
["max_end_at", "<unix-seconds>"]
["settlement_grace", "<seconds>"]
```

`start_at` is when bids may begin.

`end_at` is the nominal close time.

`max_end_at` is the hard cutoff after which no new bid can be accepted.

`settlement_grace` is the time after `max_end_at` during which the arbiter and
payment methods have to settle or release funds before bidder refund paths may
open.

Implementations SHOULD make `max_end_at` explicit even when no anti-sniping
window is used. In that case:

```text
max_end_at = end_at
```

#### Bid Rules

```json
["auction_type", "english"]
["starting_bid", "10000"]
["min_increment", "500"]
["reserve", "25000"]
```

`auction_type=english` means an ascending auction where the highest accepted
bid wins.

`reserve` MAY be `0`, meaning no reserve.

### Optional Anti-Sniping Tags

Auctions MAY define anti-sniping behavior. Only bids accepted by the declared
auction arbiter can affect anti-sniping state.

One recommended approach is a fixed hard cutoff with a rising minimum bid floor:

```json
["min_bid_curve", "none:1.0"]
["min_bid_curve", "linear:5.0"]
["min_bid_curve", "exponential:5.0"]
```

The curve applies after `end_at` and before `max_end_at`.

Another approach is an extension rule:

```json
["extension_rule", "anti_sniping:<window_seconds>:<extension_seconds>"]
```

When using an extension rule, the effective end time is computed only from
accepted bids and MUST NOT exceed `max_end_at`.

## Payment Methods

The auction event MAY omit concrete payment method tags. The arbiter's service
announcement defines which methods it can validate for auctions.

For example, the same arbiter may support:

- Cashu bid collateral
- EVM escrow deposits
- future payment profiles

A bidder may choose any method that satisfies all of:

- the auction currency
- the seller's supported arbitration/payment methods
- the auction arbiter's supported methods
- the bidder's own wallet capabilities

The chosen method is expressed in the linked `kind:32123` payment event, not in
the auction bid event.

## Auction Bid Event

An auction bid is a regular event of kind `1023`.

The bid event represents bidder intent. It is not an order. It is authored by
the bidder's temporary trade key, derived using the same local seed/account
index mechanism used for private marketplace orders.

The bid's `d` tag is the marketplace trade ID for that individual bid payment.
There is no separate bid identifier field, and bid events MUST NOT include a
`trade` tag. If a bid chain wins, the promoted order uses the `bid_chain` id as
its trade ID when present. This lets multiple bid increments, each with its own
payment trade ID and recovery material, roll up into one promoted order group.
If no `bid_chain` tag exists, the winning bid's trade ID is used as the
promoted order trade ID.

Bid events SHOULD include a `bid_chain` tag. The `bid_chain` tag gives every
increase by the same local bidder in the same auction a stable public chain
identifier even when each bid uses a new temporary pubkey and trade ID. Clients
can use this tag to group bid increments without waiting to reconstruct a
`prev_bid` chain.

The linked marketplace payment event proves the bid is funded or
collateralized. The payment event links to the bid; the bid does not need to
predict the payment event id.

The bid itself is not accepted merely because it exists. A bid counts only when
the auction arbiter publishes a valid `kind:32124` payment acknowledgment for
the linked payment and bid.

### Example

```jsonc
{
  "kind": 1023,
  "pubkey": "<temporary-bidder-trade-pubkey>",
  "created_at": 1766203000,
  "tags": [
    ["a", "30421:<seller-pubkey>:auction-123", "", "auction"],
    ["a", "30402:<seller-pubkey>:listing-456", "", "listing"],

    ["d", "<trade-id>"],
    ["bid_chain", "<bid-chain-id>"],

    ["p", "<temporary-bidder-trade-pubkey>", "", "buyer"],
    ["p", "<seller-pubkey>", "", "seller"],
    ["p", "<arbiter-pubkey>", "", "arbiter"],

    ["amount", "12500", "USD", "2"],
    ["currency", "USD"],
    ["decimals", "2"]
  ],
  "content": "{\"type\":\"auction_bid\",\"targetOrder\":{\"quantity\":1}}"
}
```

### Required Bid Tags

#### Auction Reference

```json
["a", "30421:<seller-pubkey>:<auction-d-tag>", "", "auction"]
```

#### Listing Reference

```json
["a", "30402:<seller-pubkey>:<listing-d-tag>", "", "listing"]
```

#### Trade Identifier

```json
["d", "<trade-id>"]
```

`d` identifies the bid's marketplace trade and SHOULD match the payment lock's
settlement identifier. Bid events MUST NOT include a `trade` tag; the `d` tag is
the trade ID for auction bids.

#### Bid Chain Identifier

```json
["bid_chain", "<bid-chain-id>"]
```

`bid_chain` identifies one bidder's bid chain for one auction. When using the
marketplace seed derivation model, clients SHOULD derive:

```text
bid-chain-id = sha256(<marketplace-seed> + <auction-anchor>)
```

The value MUST be a lowercase 64-character hexadecimal string. It MUST be stable
for the same bidder and auction, and SHOULD differ across auctions. A bid chain
identifier is not a payment proof and does not make a bid accepted; it is a
client and relay indexing hint for grouping bid increments.

#### Amount

```json
["amount", "<integer-minor-unit-amount>", "<currency>", "<decimals>"]
["currency", "<currency>"]
["decimals", "<decimals>"]
```

The currency MUST match the auction currency.

#### Participants

```json
["p", "<temporary-bidder-trade-pubkey>", "", "buyer"]
["p", "<seller-pubkey>", "", "seller"]
["p", "<arbiter-pubkey>", "", "arbiter"]
```

The bid author MUST be the buyer participant. The arbiter participant MUST be
the arbiter declared on the auction event.

### Target Order Parameters

The bid content MAY include `targetOrder`. These are the order parameters the
arbiter will use if this bid wins and the bid payment is promoted into a normal
marketplace order.

Example:

```json
{
  "type": "auction_bid",
  "targetOrder": {
    "quantity": 1,
    "start": "2026-07-01T00:00:00.000Z",
    "end": "2026-07-05T00:00:00.000Z"
  }
}
```

Versioned `participant_proof` and `participant_proof_key` tags MAY be attached
to the bid. Public participant proofs deliberately reveal the bidder's real
pubkey to display a public bid profile chip; sealed proofs are readable only by
their wrapped recipients. If the bid wins, the arbiter SHOULD copy these
participant proofs onto the promoted order event.

## Marketplace Payment Event for Bids

Auction bids reuse `kind:32123` marketplace payment events.

The payment event SHOULD include:

- an `a` tag for the auction
- an `a` tag for the listing
- a `d` tag and a `trade` tag, both equal to the bid's trade ID
- an `e` tag with marker `auction-bid` referencing the bid event
- participant `p` tags matching the bid
- an `amount` content field that is either a public `{ value, denomination,
  decimals }` object or a sealed payment amount envelope
- `payment_amount_key` tags for seller, arbiter, and self when the amount is
  sealed
- a public driver-specific payment proof in content, or a sealed payment proof
  envelope plus `payment_proof_key` tags for seller, arbiter, and self

The public payment proof MUST include exactly one opaque `driver` identifier
for the driver that created the proof, plus public `terms` or sealed
`sealedTerms`, plus driver-defined `params`. `terms` is the
application-independent statement of the locked funds, controls, and possible
settlement paths. `params` is the method-specific evidence the driver needs to
verify that the lock really conforms to those terms. Payment proofs MUST NOT
embed a payment subject, human-readable payment method, listing event, or
product metadata. Validators select the driver directly from the proof:

```ts
const driver = drivers[paymentProof.driver]
```

The payment event amount is an unproven claim until driver validation. When the
amount is sealed, a recipient resolves it with the matching `payment_amount_key`
tag using the same disclosure-key pattern as sealed participant proofs and
sealed payment proofs. An arbiter MUST publish `kind:32124` only when the
driver-verified amount exactly matches the resolved payment event amount. If the
arbiter cannot resolve a sealed amount, it MUST NOT acknowledge the payment. If
the driver proves a different amount, the payment is invalid for acknowledgment
even if the proof otherwise exists.

### EVM Payment Example

```jsonc
{
  "kind": 32123,
  "pubkey": "<bidder-pubkey>",
  "created_at": 1766202990,
  "tags": [
    ["a", "30421:<seller-pubkey>:auction-123", "", "auction"],
    ["a", "30402:<seller-pubkey>:listing-456", "", "listing"],
    ["d", "<trade-id>"],
    ["trade", "<trade-id>"],
    ["e", "<bid-event-id>", "", "auction-bid"],
    ["p", "<temporary-bidder-trade-pubkey>", "", "buyer"],
    ["p", "<seller-pubkey>", "", "seller"],
    ["p", "<arbiter-pubkey>", "", "arbiter"]
  ],
  "content": "{\"amount\":{\"value\":\"12500\",\"denomination\":\"USD\",\"decimals\":2},\"proof\":{\"paymentProof\":{\"driver\":\"<opaque-evm-driver-id>\",\"terms\":{\"version\":1,\"asset\":{\"value\":\"12500\",\"denomination\":\"USD\",\"decimals\":2},\"parties\":[{\"role\":\"buyer\",\"id\":\"<buyer-payment-identity>\"},{\"role\":\"seller\",\"id\":\"<seller-payment-identity>\"},{\"role\":\"arbiter\",\"id\":\"<arbiter-payment-identity>\"}],\"lock\":{\"id\":\"<bid-lock-id>\",\"policyId\":\"<opaque-evm-driver-id>\",\"kind\":\"contract\",\"amount\":{\"value\":\"12500\",\"denomination\":\"USD\",\"decimals\":2},\"controls\":[{\"role\":\"buyer\",\"id\":\"<buyer-payment-identity>\"},{\"role\":\"seller\",\"id\":\"<seller-payment-identity>\"},{\"role\":\"arbiter\",\"id\":\"<arbiter-payment-identity>\"}],\"conditions\":{\"arbitration\":{\"type\":\"continuous\",\"denominator\":\"1000\"}},\"paths\":[]}},\"params\":{\"txHash\":\"0x...\"}}}}"
}
```

### Cashu Payment Example

```jsonc
{
  "kind": 32123,
  "pubkey": "<bidder-pubkey>",
  "created_at": 1766202990,
  "tags": [
    ["a", "30421:<seller-pubkey>:auction-123", "", "auction"],
    ["a", "30402:<seller-pubkey>:listing-456", "", "listing"],
    ["d", "<trade-id>"],
    ["trade", "<trade-id>"],
    ["e", "<bid-event-id>", "", "auction-bid"]
  ],
  "content": "{\"amount\":{\"value\":\"12500\",\"denomination\":\"USD\",\"decimals\":2},\"proof\":{\"paymentProof\":{\"driver\":\"<opaque-cashu-driver-id>\",\"terms\":{\"version\":1,\"asset\":{\"value\":\"12500\",\"denomination\":\"USD\",\"decimals\":2},\"parties\":[{\"role\":\"buyer\",\"id\":\"<buyer-cashu-pubkey>\"},{\"role\":\"seller\",\"id\":\"<seller-cashu-pubkey>\"},{\"role\":\"arbiter\",\"id\":\"<arbiter-cashu-pubkey>\"}],\"lock\":{\"id\":\"<bid-lock-id>\",\"policyId\":\"<opaque-cashu-driver-id>\",\"kind\":\"threshold\",\"amount\":{\"value\":\"12500\",\"denomination\":\"USD\",\"decimals\":2},\"controls\":[{\"role\":\"buyer\",\"id\":\"<buyer-cashu-pubkey>\"},{\"role\":\"seller\",\"id\":\"<seller-cashu-pubkey>\"},{\"role\":\"arbiter\",\"id\":\"<arbiter-cashu-pubkey>\"}],\"paths\":[]}},\"params\":{\"commitment\":\"<hash>\",\"mint\":\"https://mint.example\"}}}}"
}
```

### Sealed Amount and Payment Proof Example

```jsonc
{
  "kind": 32123,
  "pubkey": "<bidder-pubkey>",
  "created_at": 1766202990,
  "tags": [
    ["a", "30421:<seller-pubkey>:auction-123", "", "auction"],
    ["a", "30402:<seller-pubkey>:listing-456", "", "listing"],
    ["d", "<trade-id>"],
    ["trade", "<trade-id>"],
    ["e", "<bid-event-id>", "", "auction-bid"],
    ["p", "<temporary-bidder-trade-pubkey>", "", "buyer"],
    ["p", "<seller-pubkey>", "", "seller"],
    ["p", "<arbiter-pubkey>", "", "arbiter"],
    ["payment_amount_key", "1", "<amount-id>", "<seller-pubkey>", "<temporary-bidder-trade-pubkey>", "nip44", "<encrypted-disclosure-key>"],
    ["payment_amount_key", "1", "<amount-id>", "<arbiter-pubkey>", "<temporary-bidder-trade-pubkey>", "nip44", "<encrypted-disclosure-key>"],
    ["payment_amount_key", "1", "<amount-id>", "<temporary-bidder-trade-pubkey>", "<temporary-bidder-trade-pubkey>", "nip44", "<encrypted-disclosure-key>"],
    ["payment_proof_key", "1", "<proof-id>", "<seller-pubkey>", "<temporary-bidder-trade-pubkey>", "nip44", "<encrypted-disclosure-key>"],
    ["payment_proof_key", "1", "<proof-id>", "<arbiter-pubkey>", "<temporary-bidder-trade-pubkey>", "nip44", "<encrypted-disclosure-key>"],
    ["payment_proof_key", "1", "<proof-id>", "<temporary-bidder-trade-pubkey>", "<temporary-bidder-trade-pubkey>", "nip44", "<encrypted-disclosure-key>"]
  ],
  "content": "{\"amount\":{\"version\":1,\"mode\":\"sealed:v1\",\"proofId\":\"<amount-id>\",\"payload\":\"<sealed-payment-amount-payload>\"},\"proof\":{\"version\":1,\"mode\":\"sealed:v1\",\"proofId\":\"<proof-id>\",\"payload\":\"<sealed-payment-proof-payload>\"}}"
}
```

The sealed amount payload decrypts to the same public amount object used by the
EVM and Cashu examples. The sealed payment proof payload decrypts to the same
public payment proof object used by those examples. The wider public can see the
funded bid lifecycle, but only wrapped recipients can inspect the amount claim
or driver-specific payment proof.

Implementations MAY also seal only `paymentProof.terms` by replacing `terms`
with:

```json
{
  "sealedTerms": {
    "version": 1,
    "mode": "sealed:v1",
    "proofId": "<sha256-of-canonical-clear-terms>",
    "payload": "<sealed-payment-terms-payload>"
  }
}
```

This hides the lock amount and settlement paths while keeping the driver and
params visible. Recipients decrypt sealed terms with `payment_proof_key` tags
using the sealed terms `proofId` as the key id.

Cashu bearer tokens, proofs, serialized inputs, output secrets, swap previews,
or pre-signatures MUST NOT be published in plaintext on public relays. The
complete Cashu payment proof MUST be sealed, and its disclosure key MUST be
wrapped only for the participants that need to validate or spend it.

## Payment Acknowledgment and Rejection

The auction arbiter accepts or rejects a bid by acknowledging or rejecting the
linked payment event.

An acknowledgment MUST be authored by the auction arbiter.
An acknowledgment MUST NOT be published until the arbiter has validated the
payment proof with the indicated driver and confirmed that the driver-verified
amount equals the resolved payment event amount.

### Accepted Bid

```jsonc
{
  "kind": 32124,
  "pubkey": "<arbiter-pubkey>",
  "created_at": 1766203010,
  "tags": [
    ["a", "30421:<seller-pubkey>:auction-123", "", "auction"],
    ["a", "30402:<seller-pubkey>:listing-456", "", "listing"],
    ["e", "<payment-event-id>", "", "payment"],
    ["e", "<bid-event-id>", "", "auction-bid"]
  ],
  "content": "{\"status\":\"accepted\"}"
}
```

Only accepted bids participate in:

- current high bid calculation
- anti-sniping extension or bid-floor state
- reserve calculation
- final winner selection

### Rejected Bid

```jsonc
{
  "kind": 32127,
  "pubkey": "<arbiter-pubkey>",
  "created_at": 1766203010,
  "tags": [
    ["a", "30421:<seller-pubkey>:auction-123", "", "auction"],
    ["e", "<payment-event-id>", "", "payment"],
    ["e", "<bid-event-id>", "", "auction-bid"],
    ["reason", "below_min_bid"]
  ],
  "content": "{\"status\":\"rejected\",\"message\":\"below minimum bid\"}"
}
```

Rejected bids do not participate in auction state.

An accepted bid that later loses is not rejected. It remains a valid bid and is
settled or refunded after the auction closes.

## Auction Complete Event

The auction complete event is a regular event of kind `1024`.

It declares the final auction result. It MUST be authored by the auction arbiter.
It is not the buyer's order. If there is a winner, the arbiter also promotes the
winning bid payment into the normal marketplace order/payment lifecycle.

### Example

```jsonc
{
  "kind": 1024,
  "pubkey": "<arbiter-pubkey>",
  "created_at": 1766289010,
  "tags": [
    ["a", "30421:<seller-pubkey>:auction-123", "", "auction"],
    ["a", "30402:<seller-pubkey>:listing-456", "", "listing"],

    ["e", "<winning-bid-event-id>", "", "winning-bid"],
    ["e", "<winning-payment-event-id>", "", "winning-payment"],
    ["e", "<promotion-settlement-event-id>", "", "auction-promote"],

    ["status", "closed"],
    ["winner", "<temporary-winner-trade-pubkey>"],
    ["final_amount", "22500", "USD", "2"],
    ["currency", "USD"]
  ],
  "content": "{\"type\":\"auction_complete\",\"status\":\"closed\"}"
}
```

If the reserve is not met:

```json
["status", "reserve_not_met"]
```

If the auction is cancelled before any accepted bid:

```json
["status", "cancelled"]
```

Cancellation after the first accepted bid SHOULD be forbidden unless the auction
event explicitly defines a cancellation policy.

## Settlement and Refunds

When settling an auction, the arbiter validates all bid/payment pairs for the
auction. Accepted bid chains are ordered by total accepted chain value, not only
by the head bid event amount. Invalid bids and non-winning valid bids MUST be
refunded or released with the existing marketplace payment settlement event
`kind:32125` using `action=auction_refund`. If the method has an explicit refund
percentage, it MUST be the integer `100`; a smaller or caller-selectable
percentage is invalid.

Winning bid-chain payments MUST NOT be paid directly to the seller merely
because the auction ended. Instead every accepted payment in the winning chain
is promoted or recycled into normal marketplace order escrow using
`action=auction_promote`.

Settlement events SHOULD reference:

- the auction event
- the bid event
- the payment event
- the auction complete event

Example tags:

```json
[
  ["a", "30421:<seller-pubkey>:auction-123", "", "auction"],
  ["e", "<bid-event-id>", "", "auction-bid"],
  ["e", "<payment-event-id>", "", "payment"],
  ["e", "<auction-complete-event-id>", "", "auction-complete"]
]
```

The driver-returned settlement proof MAY contain spend authority and therefore
MUST be treated as confidential by default. A `kind:32125` settlement carrying
such a proof MUST put the complete payment proof object in a `sealed:v1`
envelope in the top-level `proof` content field and attach matching
`payment_proof_key` tags. For `auction_refund`, disclosure MUST be limited to
the refunding arbiter and the bid buyer. The public `data` object MAY contain a
SHA-256 proof commitment and a non-secret operation receipt, but MUST NOT
contain clear proof params, Cashu proofs, swap output secrets, or recovery
material.

Financial refund/promotion operations and their durable operation receipts MUST
complete before settlement publication. A retry MUST reuse the same operation
identifier and the exact previously signed events.

### Winner Promotion into an Order

For the selected winning chain, the arbiter MUST:

1. Call the driver-specific refund operation for each non-winning bid payment
   and the driver-specific promotion/recycle operation for each winning-chain
   payment.
2. Publish `kind:32125` payment settlement events for each bid payment,
   including `action=auction_refund` for losers and one `action=auction_promote`
   event for each promoted winning-chain payment.
3. Publish a normal `kind:32122` marketplace order authored by the arbiter,
   with `recipient` set to the winner's temporary buyer trade pubkey and
   `trade` set to the winning `bid_chain` id when present, otherwise the winning
   bid trade ID.
4. Publish a new `kind:32123` marketplace payment event for each promoted
   winning-chain payment, each carrying its evolved payment proof and linking to
   the promoted order, the auction complete event, and the matching
   `auction_promote` settlement.
5. Publish a `kind:32124` payment acknowledgment for each promoted order
   payment.
6. Publish the terminal `kind:1024` auction complete event only after every
   required settlement, promoted order, payment, and acknowledgment above has
   been durably published. Implementations MAY sign and journal this event
   earlier so dependent events can reference its id, but MUST publish it last.

The promoted order SHOULD copy participant proofs from the winning bid-chain
head. Promoted order payments SHOULD preserve their own payment amounts, and
the promoted order amount SHOULD equal the total accepted winning bid-chain
value.

## Cashu Arbiter-Canonical Profile

In a Cashu-backed auction, the arbiter is also the oracle for:

- whether the auction is active
- whether the bid meets the current auction rules
- whether the Cashu collateral is valid
- whether the bid should be accepted
- which bid wins

The arbiter publishes `kind:32124` for accepted bids and `kind:32127` for
rejected bids.

Cashu tokens or proofs MUST NOT be included in public bid events. They are sent
to the arbiter through a private transport. Public payment events carry only
commitments and non-secret driver metadata; buyer signatures, witnesses,
serialized proofs, and swap previews remain inside the whole-proof seal.

For auction bids, the Cashu payment profile SHOULD support a bidder refund path
and a pre-authorized promotion path. If the bid wins, the arbiter uses the
bidder's public v1 authorization to move the locked bid funds into a normal
order escrow condition. If the bid loses or is invalid, the arbiter publishes an
`auction_refund` settlement proof.

An auction-capable mint MUST advertise NUT-11 and NUT-09. Before accepting a
bid, the implementation MUST also have an explicit operator policy committing
one output keyset id to remain active through a stated Unix timestamp. It MUST
verify that keyset is currently active and that the committed timestamp covers
the bid locktime. NUT-02 `final_expiry` is a final redemption deadline, not an
active-through promise; a missing or null value MUST NOT be promoted into one.
The exact keyset id and operator horizon are buyer-signed in both settlement
paths and MUST be rechecked immediately before the mint request.

The promotion `recycleArgs.source` object MUST contain:

```json
{
  "tradeId": "<bid-trade-id>",
  "settlementId": "<bid-settlement-id>",
  "policyType": "cashu:p2pk-auction-v1",
  "mint": "https://mint.example",
  "unit": "sat",
  "outputKeysetId": "<pre-authorized-output-keyset-id>",
  "outputKeysetActiveUntil": 1800000000
}
```

Those fields are part of the canonical buyer-signed promotion message together
with the exact target and swap. The mint/unit, active keyset, operator horizon,
source proofs, target policy, amounts, and `SIG_ALL` output commitment MUST all
match before promotion.

### Cashu 100% Refund Authorization

A Cashu auction bid that supports an arbiter-executed refund MUST include the
following `refundArgs` inside its confidential payment-proof params:

```jsonc
{
  "version": 1,
  "type": "cashu:p2pk-auction-refund-v1",
  "refundPercent": 100,
  "source": {
    "tradeId": "<bid-trade-id>",
    "settlementId": "<bid-settlement-id>",
    "policyType": "cashu:p2pk-auction-v1",
    "mint": "https://mint.example",
    "unit": "sat",
    "sourceValue": "<funded-input-value>",
    "inputFee": "<mint-input-fee>",
    "keysetId": "<output-keyset-id>",
    "keysetActiveUntil": 1800000000
  },
  "target": {
    "policyType": "cashu:p2pk-refund-v1",
    "buyerPubkey": "<buyer-cashu-pubkey>",
    "buyerOutputValue": "<recoverable-value>"
  },
  "message": "<canonical-json-below>",
  "messageHash": "0x<sha256-of-message>",
  "signerPubkey": "<buyer-cashu-pubkey>",
  "signature": "<buyer-bip340-signature-over-messageHash>",
  "swap": {
    "version": 1,
    "amount": "<recoverable-value>",
    "fees": "<mint-input-fee>",
    "keysetId": "<output-keyset-id>",
    "inputs": ["<serialized-source-proof>"],
    "sendOutputs": [{ "...": "<serialized-buyer-output-data>" }],
    "keepOutputs": [],
    "unselectedProofs": []
  }
}
```

`message` MUST be the UTF-8 JSON serialization, in the field order shown, of
exactly `{version,type,refundPercent,source,target,swap}` with no whitespace or
additional fields. `messageHash` MUST be SHA-256 of those exact bytes and the
BIP-340 signature MUST verify against both `signerPubkey` and
`target.buyerPubkey`. The serialized swap inputs MUST also contain the buyer's
valid Cashu `SIG_ALL` witness over the exact authorized output set.

Before any mint request, the refunding driver MUST verify the outer signature,
the `SIG_ALL` witness, source proof equality, mint, unit, keyset, policy tags,
buyer target, configured active-through horizon, and these value equations:

```text
sourceValue = buyerOutputValue + inputFee
swap.amount = buyerOutputValue
swap.fees = inputFee
```

The refund output MUST be an independently spendable buyer-only P2PK proof with
policy `cashu:p2pk-refund-v1` and tags binding the original trade and settlement.
On retry after ambiguous mint completion, the driver MUST use the same durable
operation identifier and restore the exact pre-authorized outputs through
NUT-09; it MUST NOT generate replacement secrets or a different output set.
The returned proof MUST be whole-proof sealed in the `auction_refund`
settlement event as specified above. Public receipt evidence SHOULD expose only
`sourceValue`, `inputFee`, `buyerOutputValue`, and the source message hash.

## EVM Arbiter-Canonical Profile

In a mixed-method auction, an EVM contract SHOULD be treated as a lockbox, not
as the global auction brain.

The EVM deposit transaction proves that a bidder locked funds for:

- this auction
- this bid
- this arbiter
- a bidder refund timeout
- optional recycle parameters authorizing promotion into normal order escrow

The auction arbiter still decides whether the EVM-backed bid is accepted into
the global auction state. This lets EVM bids and Cashu bids compete in the same
currency under one arbiter.

The EVM contract SHOULD expose enough information in logs or calldata for the
arbiter and clients to verify:

- auction identifier
- bid identifier or payment identifier
- bidder
- selected arbiter
- amount
- currency or asset
- refund conditions
- recycle authorization and timeout

The arbiter publishes `kind:32124` when the deposit is valid and high enough,
or `kind:32127` when it is invalid or below the current minimum bid.

If a bid-chain wins, the arbiter calls the contract's recycle/promote method
for every accepted payment in the winning chain using each payment's
pre-authorized recycle arguments. The resulting proofs are published in the
matching `auction_promote` settlement events and then in the promoted order
payment events.

## EVM Contract-Canonical Profile

Some auctions may choose to make a single EVM contract the canonical auction
state machine. In this profile:

- all bids MUST be placed through the same contract
- mixed Cashu/EVM bids are not valid unless mirrored into the contract
- the contract enforces bid validity, timing, and winner selection

The Nostr auction complete event MUST include proof that the contract picked the
winner.

Example complete proof tags:

```json
[
  ["settlement_profile", "evm_contract_canonical_v1"],
  ["chain", "eip155:11155111"],
  ["contract", "0x..."],
  ["contract_auction_id", "0x..."],
  ["tx", "0xcloseAuctionTxHash"],
  ["log", "WinnerPicked", "3"]
]
```

The auction complete event content SHOULD include structured proof data:

```json
{
  "type": "auction_complete",
  "proof": {
    "method": "evm",
    "event": "WinnerPicked",
    "txHash": "0x...",
    "logIndex": 3,
    "auctionId": "0x..."
  }
}
```

This profile is simpler for EVM-only auctions, but it does not solve mixed
payment method coordination unless every non-EVM bid is also represented in the
contract.

## Winner Selection

For `auction_type=english`, the winner is the highest accepted bid chain after
the auction closes. The chain value is the sum of accepted payment-backed bid
increments in the chain.

Tie-break order:

1. Highest accepted bid-chain total wins.
2. If amounts are equal, the chain whose head bid has the smallest
   `created_at` wins.
3. If head-bid timestamps are equal, the lexicographically smallest lowercase
   hexadecimal head bid event id wins.

These rules are normative. Relay receipt order, payment-ack receipt order, and
local clocks MUST NOT be used as alternate tie-breakers. For example, equal
totals with `(created_at,id)` values `(100,"bb...")`, `(100,"aa...")`, and
`(101,"00...")` are ordered `aa...`, `bb...`, `00...`.

## Notes

This draft intentionally keeps payment method selection out of the auction bid
event. The payment event links to the bid event and carries the driver-specific
proof. The auction arbiter decides whether that payment-backed bid becomes part
of the auction's canonical state.

This avoids the main failure mode for multi-method auctions: different arbiters
accepting different bids and producing incompatible winners.
