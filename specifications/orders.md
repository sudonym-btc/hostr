NIP-XX
======

Orders
------------

`draft` `optional`

This NIP defines a protocol for creating, negotiating, funding, acknowledging, settling, cancelling, and reviewing orders against NIP-99 listings on Nostr. It introduces `kind:32122` order events, `kind:32123` payment events, `kind:32124` payment ack events, `kind:32125` payment settlement events, `kind:32126` order cancel events, `kind:32127` payment nack events, `kind:1327` private structured-message rumors, `kind:1328` commit authorization helper events, `kind:1329` temporary trade key (temp-key) authorization helper events, `kind:1330` encrypted marketplace seed events, and `kind:31555` reviews.

Negotiation is private. Signed order and arbitration-service-selection events are sent as child events inside encrypted structured-message rumors and delivered with NIP-59 gift wraps. Public lifecycle events are published to relays chosen by the implementation after funding or cancellation. Payment evidence is not embedded in the order event; it is carried by linked payment lifecycle events.

## Terms

- **Buyer** — Nostr user requesting an order.
- **Seller** — Nostr user who owns the listing receiving the order.
- **Arbiter** — Optional service participant that verifies funding and can arbitrate disputes.
- **Trade** — A single order negotiation and lifecycle, identified by a stable `trade` tag (trade ID). Private trade messages use this trade ID as their default `conversation` tag.
- **Order Group** — The public replaceable order-state slot for one immutable role-tagged participant tuple inside a trade.
- **Order Group ID** — A deterministic SHA-256 hash derived from the trade ID and the role-tagged public participant pubkeys in the order. `kind:32122` uses this value as its `d` tag.
- **Listing Anchor** — A NIP-99 listing address in the format `<listing-kind>:<seller-pubkey>:<listing-d-tag>`.
- **Temporary Trade Key (Temp-Key)** — A per-trade Nostr key that can publish buyer-side order events without revealing the buyer's long-lived account key on public relays. The buyer's account identity is bound to this temporary key through versioned `participant_proof` tags. Proofs can be public when deliberate disclosure is desired, or sealed with recipient `participant_proof_key` wraps when only selected participants should read them.

## Event Kinds

| Kind    | Name                    | Type                      | Description |
| ------- | ----------------------- | ------------------------- | ----------- |
| `32122` | Order                   | Parameterized replaceable | Terms, listing anchor, trade id, and immutable public participant tuple for an order group. |
| `32123` | Payment                 | Parameterized replaceable | Payment proof or payment lock linked to an order. |
| `32124` | Payment Ack             | Parameterized replaceable | Buyer, seller, or arbiter acceptance of a payment event. |
| `32125` | Payment Settlement      | Parameterized replaceable | Settlement, release, refund, split, or claim packet linked to a payment event. |
| `32126` | Order Cancel            | Parameterized replaceable | Cancellation request or cancellation notice linked to an order or payment event. |
| `32127` | Payment Nack            | Parameterized replaceable | Buyer, seller, or arbiter rejection of a payment event. |
| `1327`  | Structured Message      | Regular private rumor     | Private structured-message rumor whose content is a signed child event JSON string. |
| `1328`  | Commit Authorization    | Regular helper event      | Seller authorization over exact negotiated commit terms. |
| `1329`  | Temp-Key Authorization  | Regular helper event      | Identity-key authorization binding a real participant pubkey to a temporary trade key (temp-key) participant pubkey. |
| `1330`  | Marketplace Seed        | Regular encrypted event   | Encrypted recovery seed used to derive trade ids and temporary trade keys. |
| `31555` | Review                  | Parameterized replaceable | Post-trade marketplace review. |

## Order (`kind:32122`)

An order event represents the terms and public participant tuple for one order group. It does not prove funding, acceptance, rejection, settlement, or cancellation by itself. Funding is represented by a linked `kind:32123` Payment event, acceptances by linked `kind:32124` Payment Ack events, rejections by linked `kind:32127` Payment Nack events, settlement by linked `kind:32125` Payment Settlement events, and cancellation by a linked `kind:32126` Order Cancel event.

Negotiation orders are usually sent privately as structured-message child events. A public order becomes meaningful for marketplace availability only when the order group also contains valid payment lifecycle events.

### Tags

```json
[
  ["d", "<order-group-id>"],
  ["trade", "<trade-id>"],
  ["a", "<listing-anchor>"],
  ["p", "<participant-pubkey>", "<relay-hint>", "<role>"],
  ["participant_proof", "1", "<role>", "<participant-pubkey>", "<proof-id>", "<public-or-sealed-mode>", "<payload>"],
  ["participant_proof_key", "1", "<proof-id>", "<recipient-pubkey>", "<sender-pubkey>", "nip44", "<encrypted-disclosure-key>"],
  ["published_at", "<unix-seconds>"]
]
```

| Tag | Required | Description |
| --- | -------- | ----------- |
| `d` | Yes | Order group ID. This is the parameterized replaceable key for a participant's current public order state. It MUST be derived from the `trade` tag and the order's role-tagged participant `p` tags as described in the Order Group section. |
| `trade` | Yes | Trade identifier. Stable across the negotiation and lifecycle. Private trade messages SHOULD repeat this value in a `conversation` tag on the enclosing rumor. |
| `a` | Yes | Listing anchor (`<listing-kind>:<seller-pubkey>:<listing-d-tag>`). The referenced event MUST be a NIP-99 listing. |
| `p` | Yes | Role-tagged participant pubkey. Use `["p", pubkey, relayHint, role]` where role is `buyer`, `seller`, or `arbiter`. Every order MUST include exactly one `buyer` and exactly one `seller` participant. Escrow-backed public order groups MUST also include exactly one `arbiter` participant. Private negotiation orders before arbitration service selection MAY omit the `arbiter` participant. The event author MUST appear in exactly one participant `p` tag, and that tag's role is the author's order role. Use privacy-preserving temporary trade keys (temp-keys) as participant pubkeys when possible; bind temp-keys to real pubkeys with `participant_proof` tags. The arbitration service pubkey MUST be included as the arbiter participant for escrow-backed public orders so arbiter daemons can subscribe to their own trades. |
| `participant_proof` | No | Versioned proof binding a temporary trade key (temp-key) participant pubkey to a real identity pubkey. Required when `participantPubkey != identityPubkey` and reusable on orders, auction bids, and reviews. |
| `participant_proof_key` | No | NIP-44 key wrap that lets a recipient decrypt a sealed `participant_proof`. Required for each intended recipient when a proof uses `sealed:v1` mode. |
| `published_at` | No | First publication timestamp. Publishers SHOULD preserve this across replacements. |

### Participant Proofs

Participant proofs bind temporary trade key (temp-key) participant pubkeys to real participant identity pubkeys without forcing the buyer to disclose their long-lived account key publicly.

`participant_proof` tag format:

```json
[
  "participant_proof",
  "1",
  "<role>",
  "<participant-pubkey>",
  "<proof-id>",
  "public",
  "<signed-kind-1329-event-json>"
]
```

For private disclosure, use the same tag with `sealed:v1` mode:

```json
[
  "participant_proof",
  "1",
  "<role>",
  "<participant-pubkey>",
  "<proof-id>",
  "sealed:v1",
  "<sealed-authorization-payload>"
]
```

The plaintext authorization payload is a JSON-encoded signed `kind:1329`
Temp-Key Authorization event. `proof-id` is the event id of that signed
authorization. A public proof places the signed authorization JSON directly in
the tag payload. A sealed proof encrypts that JSON with a random disclosure key.
The disclosure key is then wrapped to each intended recipient:

```json
[
  "participant_proof_key",
  "1",
  "<proof-id>",
  "<recipient-pubkey>",
  "<sender-pubkey>",
  "nip44",
  "<nip44-encrypted-disclosure-key>"
]
```

The `participant_proof` and `participant_proof_key` tag formats are shared by
orders, auction bids, and reviews. Clients MUST NOT use legacy
`review_proof`, `participant_proof_enc`, or unversioned participant proof tag
formats.

#### Temp-Key Authorization (`kind:1329`)

The `kind:1329` event is signed by the real identity pubkey and authorizes one participant pubkey for a trade role.

Tags:

```json
[
  ["a", "<listing-anchor>"],
  ["trade", "<trade-id>"],
  ["d", "<order-group-id>"]
]
```

Content:

```jsonc
{
  "version": 1,
  "role": "buyer",
  "participantPubkey": "<temp-key-or-real-participant-pubkey>"
}
```

A verifier accepts a public or successfully decrypted participant proof only when:

1. the authorization event id equals the `participant_proof` proof id;
2. the authorization event is validly signed by the identity pubkey;
3. the authorization `a` tag matches the listing anchor;
4. the authorization `trade` tag matches the order trade id;
5. the authorization `d` tag matches the order group ID when the order group ID is known;
6. the authorization content role and participant pubkey match the `participant_proof` tag.

### Content

Order content is JSON:

```jsonc
{
  "start": "2026-05-01T00:00:00.000Z",
  "end": "2026-05-05T00:00:00.000Z",
  "quantity": 1,
  "amount": {
    "value": "0.00500000",
    "denomination": "BTC",
    "decimals": 8
  },
  "listing": { "...": "signed NIP-99 listing event JSON" },
  "recipient": "<recipient-or-trade-pubkey>",
  "commitAuthorization": null
}
```

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `start` | string | No | Order start date/time in ISO 8601 UTC. This field MUST be omitted when no start is set. Date-only order UIs SHOULD encode calendar dates as midnight UTC. |
| `end` | string | No | Order end date/time in ISO 8601 UTC. This field MUST be omitted when no end is set. |
| `quantity` | integer | No | Number of units. Default `1`. |
| `amount` | object | No | Agreed or proposed price. `value` is a decimal string, `denomination` is the unit of account, and `decimals` is precision. |
| `listing` | object | Public purchase orders: Yes. Private negotiation proposals: SHOULD. | Full signed NIP-99 listing event JSON captured at order creation time. This snapshot lets validators derive price and listing terms from the order itself without fetching mutable relay state. |
| `recipient` | string | No | Intended payment/trade recipient pubkey. |
| `commitAuthorization` | object | No | Full signed `kind:1328` event JSON authorizing negotiated terms. |

When present, `listing` MUST be a valid signed NIP-99 listing event. Its event
address MUST equal the order `a` tag, and the seller participant SHOULD match
the listing event author. Public purchase orders that omit the listing snapshot
cannot be fully verified without external relay lookups and SHOULD be treated as
unverifiable by self-contained validators.

### Commit Terms

The order commitment hash locks exactly these fields:

```json
["start", "end", "quantity", "amount", "recipient"]
```

Implementations MUST canonicalize those fields before hashing. Payment lifecycle events and participant proof tags are not part of the commit terms.

#### Commit Authorization (`kind:1328`)

When the seller accepts off-list or negotiated terms, the seller signs a `kind:1328` event authorizing the order commit hash.

Tags:

```json
[
  ["a", "<listing-anchor>"],
  ["trade", "<trade-id>"],
  ["d", "<order-group-id>"]
]
```

Content:

```jsonc
{
  "version": 1,
  "commitHash": "<order-commit-hash>",
  "role": "seller"
}
```

The order is authorized only if the commit authorization was signed by the listing owner, references the same listing anchor, trade id, and order group ID, and contains the order's commit hash. If the authorization is produced during private negotiation before the arbiter participant is chosen, it MAY omit the `d` order group tag; in that case it authorizes only the trade ID and listing anchor and MUST be bound to the final order group by the committed order that embeds it.

## Negotiation Semantics

Negotiation is an append-only private thread of valid order and cancel child
events sharing the same trade id in the `trade` tag. The enclosing
structured-message rumor SHOULD use
`["conversation", "<trade-id>"]` so the buyer and seller can continue the same
private thread before and after arbitration service selection.

The current negotiation state is the newest valid order child event in the
private thread, unless the newest valid child event is an Order Cancel event for
that thread. Clients SHOULD order private child events the same way
NIP-17 direct-message clients order messages in a chat room after unwrapping and
decrypting them: use the decrypted inner event's `created_at`, not the
randomized seal or gift-wrap `created_at` values. If two valid items have the
same timestamp, clients SHOULD use a deterministic tie-break such as event id.

A valid negotiation item MUST:

1. reference the same listing anchor and trade id;
2. contain exactly one role-tagged buyer `p` tag and exactly one role-tagged
   seller `p` tag;
3. be authored by one of the participant pubkeys listed in the order's `p`
   tags, using that tag's role as the author role;
4. be delivered in the private thread for the resolved participants of that
   order;
5. have valid order content and valid participant proofs when temporary trade
   keys are used.

When the seller responds to an offer, the seller MUST send a signed order child
event containing a signed `commitAuthorization` that authorizes the response
order's commit hash. A seller counteroffer without `commitAuthorization` is only
an unsigned proposal and MUST NOT be treated as accepted.

In the negotiation phase, an accept action is indicated by either:

- the seller sending back a valid signed order containing a valid
  `commitAuthorization`; or
- the buyer executing payment and publishing a public order anchor plus linked
  Payment event.

## Accepted Live Orders

A trade is an accepted live order when one of the following is true after
validating the relevant private thread and public order group:

1. the latest payable terms have a seller-signed `commitAuthorization`;
2. the seller has accepted the linked Payment event with a Payment Ack;
3. the embedded listing snapshot has `autoAccept=true` and the buyer has
   published a Payment event with valid payment proof whose validated terms
   satisfy the order amount and listing-derived requirements, even without
   explicit seller acknowledgement.

An accepted live order is not necessarily final financial settlement. Escrow
confirmation, dispute resolution, payment release, or cancellation policies may
still apply.

## Private Structured Messages (`kind:1327`)

Private structured trade messages use `kind:1327` as the inner rumor kind. The rumor `content` is the JSON string of a signed child event, usually a `kind:32122` order or `kind:30302` arbitration-service selection.

The rumor includes `p` tags for the recipients and SHOULD include `["conversation", "<trade-id>"]` for trade-related messages. The `conversation` tag is the private-message grouping mechanism and remains the stable trade id before and after arbitration service selection. Local inbox implementations MAY group gift wraps by the sorted set of rumor author plus rumor `p` tags, combined with the `conversation` tag; that local conversation id is not the order group id and MUST NOT be used for order validity. The rumor MAY include `alt` tags. It is sealed and wrapped with NIP-59. The sender broadcasts one `kind:1059` gift wrap for every recipient and one for self.

Private trade DMs MUST be sent between the resolved participant pubkeys of the
order. A resolved participant pubkey is the participant identity pubkey when a
temporary trade key is authorized by `participant_proof`, otherwise it is the
participant order pubkey. Buyer/seller negotiation messages SHOULD include the
resolved buyer and seller participants. If a committed order is disputed, the
participants SHOULD add the arbitration service pubkey to the same participant
thread, keep the same `conversation` trade id, and message the buyer, seller,
and arbiter together. Implementations SHOULD NOT create an arbiter-only side
conversation for disputes about a committed order.

Plain text private messages use standard private message rumor kind `14`.

## Verification

Clients verify orders for two primary reasons:

1. to determine availability for the referenced NIP-99 listing;
2. to verify that reviews are attached to a real trade.

Availability verification is based on public order groups after applying the validity and precedence rules in the Order Group section. Review verification proves that the reviewer participated in a structurally valid order group that reached confirmed commitment.

Order verification is a separate step from payment proof verification:

1. Verify the Payment proof using the selected driver and the self-proclaimed
   `paymentProof.terms` (or decrypted `paymentProof.sealedTerms`) plus
   driver-specific `paymentProof.params`.
2. The driver MUST confirm that the method-specific proof locks the funds in
   exactly the way described by those payment terms. Once accepted, higher-level
   order and auction logic consumes the verified terms and does not need to
   inspect driver-specific proof internals.
3. Verify the Order using the signed embedded listing snapshot. The validator
   derives the expected price from the listing snapshot, `quantity`, `start`,
   and `end`; compares the order amount to that derived price; and compares the
   sum of accepted verified payment terms to the order requirements.

Payment proof validation MUST NOT require the order or listing. Order
validation MAY consume the verified public terms returned by one or more
successful payment proof validations.

## Payment Lifecycle Events

The order group lifecycle is represented by events that all carry the same `d`
tag as the order group ID. They MUST also carry the same `trade` and `a` tags as
the order. Implementations SHOULD repeat the role-tagged `p` tags from the order
anchor on every lifecycle event so clients can subscribe by participant pubkey.

After the initial order anchor defines the order group participant tuple, every
payment, payment ack, payment nack, payment settlement, and cancel event for
that order group MUST be authored by one of those participant pubkeys. Clients
MUST ignore lifecycle events whose author is not in the order group's
role-tagged participant set, or whose `d`, `trade`, or `a` tag does not match
the order anchor.

Lifecycle events link to the event they evaluate with `e` tags:

```json
["e", "<event-id>", "<relay-hint>", "<marker>"]
```

Defined markers are:

| Marker | Description |
| ------ | ----------- |
| `order` | Referenced order anchor. Required on Payment events. |
| `payment` | Referenced Payment event. Required on Payment Ack, Payment Nack, and Payment Settlement events. |
| `payment-ack` | Referenced Payment Ack event. Optional on Payment Settlement events. |
| `payment-nack` | Referenced Payment Nack event. Optional on later lifecycle events. |
| `settlement` | Referenced Payment Settlement event. Optional on later lifecycle events. |
| `cancel` | Referenced Order Cancel event. Optional on later lifecycle events. |

### Payment (`kind:32123`)

A Payment event contains the generic payment evidence or payment lock for an
order. It MUST include `["e", "<order-event-id>", "<relay-hint>", "order"]`.
Public payment proofs are the default. If the payer wants to hide the payment
proof from public relays, the Payment event MAY instead carry a sealed payment
proof envelope and `payment_proof_key` tags for the seller, arbiter, and payer's
own trade key.

Public payment content is JSON:

```jsonc
{
  "proof": {
    "paymentProof": {
      "driver": "evm:multi-escrow",
      "terms": {
        "version": 1,
        "asset": {
          "value": "50000",
          "denomination": "BTC",
          "decimals": 8,
          "assetId": "33:0x0000000000000000000000000000000000000000"
        },
        "parties": [
          { "role": "buyer", "id": "<buyer-payment-identity>" },
          { "role": "seller", "id": "<seller-payment-identity>" },
          { "role": "arbiter", "id": "<arbiter-payment-identity>" }
        ],
        "lock": {
          "id": "<driver-lock-id>",
          "policyId": "evm:multi-escrow",
          "kind": "contract",
          "amount": {
            "value": "50000",
            "denomination": "BTC",
            "decimals": 8,
            "assetId": "33:0x0000000000000000000000000000000000000000"
          },
          "controls": [
            { "role": "buyer", "id": "<buyer-payment-identity>" },
            { "role": "seller", "id": "<seller-payment-identity>" },
            { "role": "arbiter", "id": "<arbiter-payment-identity>" }
          ],
          "conditions": {
            "arbitration": { "type": "continuous", "denominator": "1000" }
          },
          "paths": []
        }
      },
      "params": {
        "txHash": "<evm-transaction-hash>",
        "chainId": 33,
        "tradeId": "<order-group-id>",
        "sellerAddress": "<seller-evm-address>",
        "arbiterAddress": "<arbiter-evm-address>",
        "assetAddress": "<asset-address>",
        "paymentAmount": "50000",
        "bondAmount": "0",
        "escrowFee": "0",
        "unlockAt": "1781067882",
        "denomination": "BTC",
        "decimals": 8
      }
    },
    "arbitration": {
      "arbitrationService": { "...": "ArbitrationService kind:30303 event JSON" },
      "paymentMethod": { "...": "seller payment method kind:17388 event JSON" }
    }
  },
  "purpose": "order_payment"
}
```

The `proof.paymentProof` object is keyed by the payment driver and carries:

- `driver`: the opaque driver/policy identifier;
- `terms`: the public, application-independent statement of what is locked; or
- `sealedTerms`: a sealed `terms` envelope when the public should not see the
  lock amounts or paths; and
- `params`: method-specific evidence, transaction ids, signatures, proofs,
  calldata, or encrypted params needed by the driver.

Payment params and terms MUST be self-contained verifier inputs: validators
MUST NOT require the referenced order, auction bid, or listing event to
determine whether the payment proof itself is valid. Order/bid/listing data MAY
still be used by higher-level marketplace logic after proof validation.
Arbitration-specific context, when needed, is attached beside the generic
payment proof under `proof.arbitration`.

The driver validates the proof by checking that `params` lock spendable funds
according to the declared `terms`. A Payment Ack/Nack is a statement about that
payment proof and its declared terms only. It is not a statement that those
terms satisfy a particular order, bid, listing, reserve, or auction rule.

Payment terms are recursive and driver-neutral. The top-level `lock` describes
the currently locked funds. Each `path` describes one possible outcome. A path
can terminate into role-addressed outputs, or into a new lock whose own paths
describe later outcomes. This lets Cashu express discrete presigned split
chunks while EVM or Liquid drivers can expose continuous settlement conditions.

The entire `paymentProof.params` object MAY be encrypted while leaving the
driver visible:

```jsonc
{
  "paymentProof": {
    "driver": "evm:multi-escrow",
    "params": {
      "encrypted": true,
      "version": 1,
      "scheme": "nip44",
      "proofId": "<sha256-of-canonical-clear-params>",
      "payload": "<sealed-payment-proof-params-payload>"
    }
  }
}
```

When params are encrypted, the plaintext is the JSON-encoded clear params
object. `proofId` is the SHA-256 hash of that canonical clear params object.
The payer MUST add `payment_proof_key` tags for recipients that should decrypt
the params, using the encrypted params `proofId` as the key id. This is separate
from sealing the whole `proof` field; implementations MAY use either privacy
mode, but validators must receive clear params or a decryptor before reading
driver-specific fields.

The `paymentProof.terms` object MAY also be sealed independently while keeping
`driver` and `params` visible:

```jsonc
{
  "paymentProof": {
    "driver": "evm:multi-escrow",
    "sealedTerms": {
      "version": 1,
      "mode": "sealed:v1",
      "proofId": "<sha256-of-canonical-clear-terms>",
      "payload": "<sealed-payment-terms-payload>"
    },
    "params": {
      "txHash": "<evm-transaction-hash>"
    }
  }
}
```

When terms are sealed, the plaintext is the JSON-encoded clear terms object.
`proofId` is the SHA-256 hash of that canonical terms object. The payer MUST
add `payment_proof_key` tags for recipients that should decrypt the terms,
using the sealed terms `proofId` as the key id. Implementations MAY seal params,
terms, or the whole proof, depending on which public metadata should remain
visible.

Sealed payment content uses the same `proof` field, but the value is a sealed
envelope:

```jsonc
{
  "proof": {
    "version": 1,
    "mode": "sealed:v1",
    "proofId": "<sha256-of-canonical-public-payment-proof>",
    "payload": "<sealed-payment-proof-payload>"
  },
  "purpose": "order_payment"
}
```

When `mode` is `sealed:v1`, the plaintext is the JSON-encoded public payment
proof object shown above. `proofId` is the SHA-256 hash of the canonical public
payment proof. The payload is encrypted with a random disclosure key. The payer
MUST add one `payment_proof_key` tag for every participant that should decrypt
the payment proof:

```json
[
  "payment_proof_key",
  "1",
  "<proof-id>",
  "<recipient-pubkey>",
  "<sender-pubkey>",
  "nip44",
  "<nip44-encrypted-disclosure-key>"
]
```

For arbiter-backed payments, clients SHOULD wrap the disclosure key to the
seller participant, the arbiter participant, and the payer's own trade pubkey.
The wider public can still see that a payment event exists and can reduce the
order group structurally, but cannot inspect the method-specific payment proof
unless a recipient discloses it.

Defined payment drivers include `"zap"` for NIP-57 zap receipts and concrete
EVM/Cashu driver ids such as `"evm:multi-escrow"` or
`"cashu:p2pk-escrow-v1"`. Arbitration service types MAY map to payment
drivers; for example, an EVM arbitration service uses an EVM escrow driver.

### Zap Proof

```jsonc
{
  "paymentProof": {
    "driver": "zap",
    "terms": {
      "version": 1,
      "asset": { "value": "50000", "denomination": "SAT", "decimals": 0 },
      "parties": [],
      "lock": {
        "id": "<zap-receipt-id>",
        "policyId": "zap",
        "kind": "direct",
        "amount": { "value": "50000", "denomination": "SAT", "decimals": 0 },
        "controls": [],
        "paths": []
      }
    },
    "params": {
      "receipt": { "...": "zap receipt event JSON" },
      "recipientProfile": { "...": "seller profile metadata event JSON" }
    }
  }
}
```

For zap proofs, `recipientProfile` is required so clients can verify that the
zap receipt LNURL matches the seller's signed current payment address.

### Arbitration Proof

```jsonc
{
  "paymentProof": {
    "driver": "evm:multi-escrow",
    "terms": { "...": "driver-neutral lock terms as above" },
    "params": {
      "txHash": "<evm-transaction-hash>",
      "chainId": 33,
      "tradeId": "<order-group-id>",
      "sellerAddress": "<seller-evm-address>",
      "arbiterAddress": "<arbiter-evm-address>",
      "assetAddress": "<asset-address>",
      "paymentAmount": "50000",
      "bondAmount": "0",
      "escrowFee": "0",
      "unlockAt": "1781067882",
      "denomination": "BTC",
      "decimals": 8
    }
  },
  "arbitration": {
    "arbitrationService": { "...": "ArbitrationService kind:30303 event JSON" },
    "paymentMethod": { "...": "seller payment method kind:17388 event JSON" }
  }
}
```

For EVM escrow-backed orders, `paymentProof.driver` identifies the concrete EVM
driver and `paymentProof.params.txHash` is the transaction hash to verify.
`params` MUST include the method-specific evidence needed to find and decode the
funding action. The public or decrypted `terms` MUST include the asset, parties,
lock amount, controls, and settlement paths or continuous arbitration condition
that the EVM proof is claiming. Contract address and bytecode hash MAY be
omitted from params when the verifier has the driver configuration needed to
locate the escrow contract, but the driver MUST still verify that the decoded
contract state conforms to the supplied terms. The `arbitration` context is
required only to interpret that EVM payment proof as satisfying a selected
payment method.
`paymentMethod` MUST include the seller's `["i", "evm:address:<address>",
"eip191:<signature>"]` ownership proof. See the Arbitration Services NIP for the
exact proof payload and payment verification requirements.

### Payment Ack (`kind:32124`)

A Payment Ack event records a participant's acceptance of a Payment event. It
MUST include `["e", "<payment-event-id>", "<relay-hint>", "payment"]`.

Content:

```jsonc
{
  "status": "accepted",
  "message": "Payment proof verified"
}
```

`status` MUST be `accepted`. A Payment Ack means the referenced Payment event's
payment proof validated as a self-contained payment proof. It MUST NOT depend
on the linked order, bid, listing snapshot, or any order/bid term reconciliation.
Buyer, seller, and arbitration-service acknowledgements are payment lifecycle
signals only; higher-level order validators MAY separately decide whether the
validated payment terms satisfy the linked order.

### Payment Nack (`kind:32127`)

A Payment Nack event records a participant's rejection of a Payment event. It
MUST include `["e", "<payment-event-id>", "<relay-hint>", "payment"]`.

Content:

```jsonc
{
  "status": "rejected",
  "message": "Payment proof did not satisfy the selected policy"
}
```

`status` MUST be `rejected`. A Payment Nack means the referenced Payment event's
payment proof failed payment-proof validation. It MUST NOT be used for failures
that depend on the linked order, bid, listing snapshot, or order/bid term
reconciliation. Payment Nack events do not cancel an order by themselves. If the
trade is cancelled, an Order Cancel event is still required.

### Payment Settlement (`kind:32125`)

A Payment Settlement event records the post-deposit outcome for escrowed
payments and bids. It MUST include `["e", "<payment-event-id>", "<relay-hint>",
"payment"]` and SHOULD include `payment-ack` references for the acknowledgements
or authorizations it consumes. If its result proof is confidential or conveys
spend authority, it MUST also include a top-level sealed proof envelope and one
`payment_proof_key` tag for each authorized recipient.

Content:

```jsonc
{
  "method": "cashu",
  "action": "split",
  "inputs": [
    { "y": "<cashu-proof-y>", "amount": "1000" }
  ],
  "outputs": [
    { "role": "buyer", "pubkey": "<buyer-pubkey>", "amount": "500" },
    { "role": "seller", "pubkey": "<seller-pubkey>", "amount": "500" }
  ],
  "proof": {
    "version": 1,
    "mode": "sealed:v1",
    "proofId": "<sha256-of-canonical-clear-proof>",
    "payload": "<sealed-complete-settlement-proof>"
  },
  "data": {
    "proofCommitment": "<sha256-of-driver-result-proof>",
    "receipt": { "status": "completed", "operationId": "<durable-operation-id>" }
  }
}
```

`method` and `action` are extensible. A Payment Settlement event is atomic: if
it exists, it MUST contain proof that settlement already happened or enough
witness data for the relevant participants to claim their settlement outputs
without any further event. For Cashu, settlement events can carry a signed claim
packet, deterministic restore metadata, or a fully authorized collaborative swap
template only inside the complete sealed proof. Cashu proofs, serialized inputs,
output secrets, witnesses, and recovery material MUST NOT appear in cleartext
content or tags. Public `inputs`, `outputs`, and `data` MUST be limited to
non-secret commitments, allocations, and completed-operation receipt evidence.
For EVM, settlement events usually reference on-chain settlement transactions
and are advisory because refunds, releases, and losing bids can be independently
verified on chain.

The sealed proof decrypts to the same generic `{paymentProof:{driver,terms or
sealedTerms,params}}` object used by a Payment event. Its `proofId` and
`payment_proof_key` tags use the same hashing and disclosure-key rules defined
above. An auction refund SHOULD wrap the key only for the refunding arbiter and
the bid buyer. A promoted payment SHOULD wrap it for the resulting order's
participants. Implementations MUST verify the clear proof hash after decryption.

Each Payment Settlement event settles exactly one Payment event. When one
order, promoted auction order, or other payment group contains multiple Payment
events, arbitration MAY calculate the desired split across the group as a whole,
but it MUST publish one Payment Settlement event per Payment. The settlement
outputs on each event are that payment's proportional allocation of the group
decision, unless the payment terms define a different exact allocation rule.
For example, if a group contains accepted payments of `15000` and `10000` and
the arbiter settles the group 50/50 between seller and buyer, the first
settlement outputs `7500` and `7500`, and the second outputs `5000` and
`5000`.

### Order Cancel (`kind:32126`)

An Order Cancel event records cancellation intent for an order group. It MUST
include either an `order` reference or a `payment` reference.

Content:

```jsonc
{
  "reason": "cancelled by buyer"
}
```

Cancellation does not prove that funds moved. If a funded order is cancelled,
the refund/release/split MUST be represented by a Payment Settlement event.

### Seller-Published Proofless Orders

Seller proofless orders no longer rely on `order.pubkey == listing.pubkey`.
Clients MUST use the role-tagged seller participant and, when a temporary trade
key is used, a valid public or sealed `participant_proof` authorization to reconcile the
seller participant with the listing owner. A seller-authored order can block
inventory only after that role proof is valid or application policy explicitly
allows an unproven seller reservation.

## Order Group

All public order lifecycle events with the same order group ID form an order
group. The order group ID is the `d` tag on `kind:32122`, `kind:32123`,
`kind:32124`, `kind:32125`, `kind:32126`, and `kind:32127`. It is derived from
the stable trade ID plus the public, non-decrypted, role-tagged participant
pubkeys in the order anchor's `p` tags.

The participant tuple is role-aware. It is not sufficient to hash only a sorted
list of pubkeys because the same pubkeys in different roles would otherwise
produce the same replaceable event slot.

The order group ID MUST be derived from the trade ID and canonical participant
entries:

```text
sha256(json([
  tradeId,
  sorted([
    {"role":"buyer","pubkey":"<buyer-participant-pubkey>"},
    {"role":"seller","pubkey":"<seller-participant-pubkey>"},
    {"role":"arbiter","pubkey":"<arbiter-participant-pubkey>"}
  ])
]))
```

`json(...)` is the UTF-8 encoding of deterministic JSON with no insignificant
whitespace. Object keys are sorted lexicographically (`pubkey` before `role`),
and participant objects are sorted first by `role` and then by `pubkey`. SHA-256
is applied to those UTF-8 bytes and encoded as 64 lowercase hexadecimal
characters. Implementations MUST NOT substitute tuple entries or ordinary
insertion-order JSON.

Golden vector:

```text
tradeId = "trade-vector-1"
participants = [
  {"role":"seller","pubkey":"2222222222222222222222222222222222222222222222222222222222222222"},
  {"role":"buyer","pubkey":"1111111111111111111111111111111111111111111111111111111111111111"},
  {"role":"arbiter","pubkey":"3333333333333333333333333333333333333333333333333333333333333333"}
]
orderGroupId = "0a71706f343b3cd9d1e80727c838de01f381fc44408a232873bd65dd62734851"
```

Private negotiation orders before arbitration service selection use the same derivation with
the available buyer and seller participant entries. When an arbiter is selected,
the escrow-backed order group has a different order group ID because the
participant tuple now includes the `arbiter` entry. The `trade` tag remains the
same, so private messages can continue in the same trade conversation.

Public arbiter-backed order groups MUST include exactly one `buyer`, exactly one
`seller`, and exactly one `arbiter` participant `p` tag on the order anchor.
Public non-arbiter order groups MUST include exactly one `buyer` and exactly one
`seller` participant `p` tag. Events with missing required roles, duplicate
roles, or a computed order group ID that does not equal the `d` tag are invalid
for the normal order group pipeline.

The author role is determined only from the author pubkey's matching
role-tagged `p` tag. Clients MUST NOT infer the author role from the listing
anchor or from an undecrypted `participant_proof`. The listing anchor remains a
validation constraint: the seller participant SHOULD be the listing owner, or a
temporary trade key whose real identity is authorized by a valid
`participant_proof` signed by the listing owner. Implementations MAY reject
public order groups whose seller participant cannot be reconciled with the
listing owner.

Role-marked `p` tags define the public participant tuple and routing hints. They
do not reveal real identities when temporary trade keys are used. Participant
pubkeys SHOULD be temporary trade keys when privacy can be preserved; real
pubkeys are carried in public `participant_proof` payloads only when deliberate
disclosure is desired, or in sealed `participant_proof` payloads when only
selected participants should resolve them.

Clients MUST ignore lifecycle events from outsiders whose author pubkey is not
one of the role-tagged participant pubkeys in the initial order anchor. Clients
MUST also ignore events whose listing anchor, trade ID, or order group ID does
not match the order group they are reducing. Such events form another order
group if their computed order group ID differs; they do not create ambiguity
inside an existing order group.

### Group Reduction

Clients query and subscribe to all public order group event kinds:

```json
{
  "kinds": [32122, 32123, 32124, 32125, 32126, 32127],
  "#d": ["<order-group-id>"]
}
```

When multiple events of the same role and kind are available, clients SHOULD use
the latest valid event by highest `created_at`, with lexicographic event id as a
deterministic tie-break.

The group stage is derived from valid linked lifecycle events:

- `cancel` if a valid Order Cancel event exists and applies to the order or payment;
- `settled` if a valid Payment Settlement event exists and applies to the payment;
- `commit` if the latest Payment event validates by the relevant payment policy, or if both buyer and seller have accepted it with Payment Ack events;
- `negotiate` otherwise.

A group is **confirmed committed** if any of the following hold after validation:

- the payment event validates by the relevant payment policy;
- both buyer and seller have accepted the payment event;
- a valid payment settlement exists.

Later cancellation MUST NOT by itself erase the fact that a trade reached
confirmed commitment. Cancellation changes marketplace availability only when it
is valid for the current order group and application policy says the order is
still cancellable; funded cancellations still require a Payment Settlement event
to explain the refund/release/split.

## Review (`kind:31555`)

After a completed or confirmed committed trade, a participant MAY publish a review. Reviews use the GammaMarkets product review shape: the review body is raw human-readable text in `content`, and the primary rating is a `rating` tag with a normalized score from 0 to 1 and the `thumb` label.

### Tags

```json
[
  ["d", "<order-group-id>"],
  ["trade", "<trade-id>"],
  ["a", "<listing-anchor>"],
  ["rating", "<0-to-1-score>", "thumb"],
  ["r", "<order-anchor>"],
  ["participant_proof", "1", "<role>", "<participant-pubkey>", "<proof-id>", "public", "<signed-kind-1329-event-json>"]
]
```

The `d` tag contains the order group ID. Reviews are parameterized replaceable events, so a participant replaces their review for the same order group by publishing a newer review with the same `d` tag. The `trade` tag contains the stable private trade id for clients that want to correlate a review with a private trade thread.

The `a` tag contains the listing anchor (`<kind>:<pubkey>:<d-tag>`) for the listing being reviewed.

The `rating` tag contains the primary rating. The third element MUST be `thumb`. The score is normalized from 0 to 1, where 0 is negative and 1 is positive. Five-star clients SHOULD map stars to this value by dividing by 5.

The `r` tag contains an order anchor (`<kind>:<pubkey>:<d-tag>`) linking the review to a specific trade participant event.

The `participant_proof` tag is marketplace-specific and MAY be omitted when the review is signed directly by an order participant pubkey. Clients SHOULD include a public `participant_proof` when the review is signed by an identity key but the public order participant is a temporary trade key. Generic Gamma-compatible clients can ignore this tag. Implementations MUST NOT publish or parse legacy `review_proof` tags.

### Content

```text
Clear terms, smooth payment, and accurate listing.
```

The content field is raw review text. Structured data belongs in tags.

### Review Validity

A review is valid only if:

1. the `d` tag identifies an order group and the `a` tag references an existing listing;
2. the primary `rating` tag is present as `["rating", "<0-to-1-score>", "thumb"]`;
3. the referenced order group validates structurally;
4. the order group is confirmed committed;
5. either:
   - the review pubkey appears as an order participant pubkey in the referenced order group; or
   - a public `participant_proof` tag contains a signed `kind:1329` authorization event whose event id equals the tag proof id, whose identity pubkey is the review author, and whose role, participant pubkey, listing anchor, trade id, and order group ID match the referenced order group.

This NIP does not define a canonical on-chain or block-time proof that the review was written after the order ended. Clients MAY additionally require the order end time to be in the past or a terminal payment event to exist, but those timing rules are application policy unless standardized separately.

## Protocol Flow

### 1. Buyer Initiates Negotiation

1. Buyer discovers a NIP-99 listing.
2. Buyer allocates a trade id and temporary trade key (temp-key). Deterministic derivation is optional and described in the addendum below.
3. Buyer creates a `kind:32122` order signed by the temporary trade key (temp-key), carrying `["trade", "<trade-id>"]` and a `d` tag derived from the buyer/seller participant tuple.
4. Buyer includes role-marked `buyer` and `seller` participant `p` tags and public or sealed `participant_proof` tags as needed.
5. Buyer sends the order as a child event inside a private `kind:1327` rumor tagged `["conversation", "<trade-id>"]`, delivered with NIP-59 gift wraps to the resolved seller participant and self.

### 2. Negotiation

6. Seller reviews the request. If counter-offering, seller creates a new order with changed terms and embeds a signed `kind:1328` commit authorization for those terms.
7. If the seller accepts the current terms, the seller replies with an order for those terms and embeds a signed `kind:1328` commit authorization.
8. Counteroffers continue privately until terms are accepted or cancelled.

### 3. Arbitration Service Selection and Payment

9. If escrow-backed, buyer selects an arbitration service, computes the escrow-backed order group ID from the same trade id plus buyer/seller/arbiter participant tuple, and sends a private `kind:30302` Arbitration Service Selected child event inside a `kind:1327` rumor tagged `["conversation", "<trade-id>"]`.
10. Buyer funds escrow directly or via a Lightning-to-on-chain swap.

### 4. Commitment

11. Once payment proof exists, the buyer or temporary trade key (temp-key) publishes a public `kind:32122` order anchor with `d=<order-group-id>`, `trade=<trade-id>`, canonical participant `p` tags for buyer, seller, and arbiter when escrow-backed, and the full signed listing snapshot in `content.listing`.
12. Buyer publishes a linked `kind:32123` Payment event with `d=<order-group-id>` and `["e", "<order-event-id>", "<relay-hint>", "order"]`. The payment proof is public by default; if sealed, the buyer includes `payment_proof_key` tags for seller, arbiter, and self.

13. Buyer and seller SHOULD publish `kind:32124` Payment Ack events that reference the Payment event. Arbiter MAY publish a Payment Ack after validation or a `kind:32127` Payment Nack when the proof is inadequate.
14. Release, refund, split, or claim data is published as a `kind:32125` Payment Settlement event that references the Payment event and any consumed Payment Ack events.

### 5. Cancellation

Either party MAY cancel a private negotiation with a private Order Cancel child
event for the same trade id and participant tuple. Public cancellation publishes
a `kind:32126` Order Cancel event for the same order group ID. A funded
cancellation MUST be followed by a Payment Settlement event that explains the
refund, release, or split.

## Availability

Clients MUST only consider public order groups after applying the Order Group validity ordering when computing listing availability. Negotiation orders are exchanged only between buyer and seller via gift-wrapped private structured messages, so they are not part of public listing availability calculations.

Order clients SHOULD verify that the embedded listing snapshot is an active
NIP-99 listing whose event address matches the order `a` tag before displaying
or accepting an order. Clients MAY use the `a` tag to fetch the latest listing
for UI context, but self-contained order validation MUST use the embedded
snapshot captured in the signed order.

## Addendum: How to Choose Temporary Keys

Temporary trade keys (temp-keys) exist to preserve privacy by separating a buyer's public account identity from public order events. This NIP does not require deterministic values for trade ids or temporary keys. A client MAY generate a fresh random trade id and random temporary key for each trade and store the resulting private state locally.

A Nostr user MAY instead publish encrypted SEED events (`kind:1330`) globally. A SEED event content is a NIP-44 encrypted payload from the user's identity key to itself, for example:

```jsonc
{
  "v": 1,
  "seed": "<32-byte-hex-seed>"
}
```

SEED events MUST use a regular, non-replaceable event kind. Clients MUST NOT use a replaceable event kind for seed backups, because replacing a seed can make older deterministic trade ids and temporary trade keys unrecoverable. If a client accidentally publishes another seed, the older event remains available on relays because the kind is not replaceable.

On startup, a client that uses deterministic marketplace seeds SHOULD query a
bounded candidate set of the user's `kind:1330` events (`limit: 50` is the
recommended interoperability profile). It MUST discard events with the wrong
author or kind, invalid signatures, empty content, and duplicate event ids.
Candidates are ordered by descending `created_at`; equal timestamps are ordered
by descending event id. The first candidate that decrypts and parses as a valid
version-1 seed payload is authoritative. Relay order and relay duplication MUST
NOT affect the result. If signed candidates exist but none decrypt and parse,
startup/recovery MUST fail rather than create a replacement seed. A client MAY
create and publish a seed only when no valid signed candidates exist.

Equal-time selection vector: for two otherwise valid candidates at
`created_at=1712678401` with ids
`68c062f9d712eeb64296754b3d2111887a6a865db9371001399801d0eff2c944` and
`2e444bafa4d167a8e0f1d11beabc204823694845a4eaf2c8aa0f56575c56222e`,
the `68c0…c944` event is selected regardless of relay or array ordering.

Clients that can decrypt a SEED event can derive arbitrary trade ids and temporary trade keys from the seed, avoiding dependence on one device's local storage of encrypted gift wraps for each individual trade. This is a convenience and recovery mechanism, not a consensus requirement: clients MUST accept valid orders and participant proofs regardless of whether their trade ids and temporary keys were random, locally stored, or derived from a published SEED event.

Clients that implement deterministic derivation SHOULD domain-separate trade ids from temporary keys and SHOULD include an account-controlled index or nonce so the same seed never produces the same public key for two unrelated trades.

## Related NIPs

- [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md) — Event structure and parameterized replaceable events.
- [NIP-99](https://github.com/nostr-protocol/nips/blob/master/99.md) — Classified listings.
- [NIP-17](https://github.com/nostr-protocol/nips/blob/master/17.md) — Private message rumor kind `14`.
- [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) — `naddr` encoding for anchors.
- [NIP-44](https://github.com/nostr-protocol/nips/blob/master/44.md) — Encryption scheme.
- [NIP-57](https://github.com/nostr-protocol/nips/blob/master/57.md) — Zaps.
- [NIP-59](https://github.com/nostr-protocol/nips/blob/master/59.md) — Gift wrap.
