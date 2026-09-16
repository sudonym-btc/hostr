# Cashu Escrow Design Research

This document preserves design research for accommodation/reservation escrow.
It is a nonnormative proposal, not the implemented protocol or a second set of
models. Its component diagrams and payload sketches describe ideas for review;
they must not be copied into Hostr application models.

The implemented contract is owned by NMDK:

- [Order and Payment events](dependencies/nmdk/dependencies/nips/order-nip/XX.md).
- [Cashu driver behavior and privacy](dependencies/nmdk/dependencies/marketplace-cashu-ts/README.md).
- [Shared driver interfaces](dependencies/nmdk/dependencies/marketplace-driver-interface-ts/README.md).

Current payment evidence uses linked `kind:32123` Payment events with generic
`driver`, `terms`, and `params` fields. Cashu drivers classify the complete proof
as secret, and the runtime seals it for authorized participants. The public
funding-package variants discussed below are research alternatives, not an
implemented or approved publication path. Proposals to expose proof material
require a separate security review and must not override the driver's privacy
requirement.

The research considers three separate Cashu components:

- `feeScript`: escrow/operator fee.
- `paymentScript`: the reservation payment amount.
- `securityDepositScript`: a separate security deposit amount.

In this document, "script" means the complete Cashu escrow component: funded
proofs, NUT-11 P2PK policy, settlement templates, buyer pre-authorizations,
hash commitments, and recovery metadata. The actual mint-enforced lock is the
NUT-11 P2PK `Secret`; the large settlement ladder lives beside that lock as
pre-signed `SIG_ALL` swap templates.

## Goals

- A seller can advertise Cashu mints and escrow pubkeys they trust.
- A buyer can fund a reservation with Cashu proofs locked under escrow terms.
- The escrow can forward or reverse funds without further buyer interaction.
- The escrow cannot redirect funds to itself or arbitrary third parties.
- Buyer and seller can collaboratively settle at any time.
- Seller can claim after a timelock.
- The security deposit can use the same mechanism as the payment amount.
- A reservation/order can carry a single payment proof that commits to all
  funded components.
- The funded Cashu escrow package can be published as a network-public event
  authored by the buyer's temporary trade key, so seller and escrow do not
  depend on private delivery for recovery.

## Cashu Constraints

This design relies on standard Cashu primitives:

- NUT-03 swaps: spend input proofs and receive new blinded output signatures.
- NUT-07 state checks: verify proofs are `UNSPENT`, `PENDING`, or `SPENT`.
- NUT-09 restore: recover signatures for known blinded outputs after an
  interrupted swap.
- NUT-11 P2PK: mint-enforced signatures, `SIG_ALL`, multisig, `locktime`, and
  refund-path keys.
- NUT-12 DLEQ proofs: local verification of mint signatures.

The important limitation: standard NUT-11 does not support output covenants.
It cannot express "escrow may create arbitrary outputs, but only if those
outputs are locked to buyer or seller". `SIG_ALL` can commit signatures to exact
outputs, but it cannot whitelist future arbitrary outputs.

Therefore, escrow discretion must be represented as a finite settlement ladder.
The buyer pre-authorizes each allowed outcome at funding time. Later, the
escrow chooses one pre-authorized outcome and adds its signature.

Cashu escrow funding proofs are not normal wallet proofs. Normal wallet/change
proofs MUST remain private. Escrow funding proofs MAY be published publicly only
when they are locked by the declared P2PK policy and are not spendable by a
network observer.

## Keys

Each trade needs Cashu P2PK keys separate from long-lived Nostr identity keys:

```text
buyerP2pk          buyer refund/settlement key
sellerP2pk         seller settlement key
escrowP2pk         escrow decision key
escrowFeeP2pk      optional escrow fee receive key
```

The seller and escrow advertise their Cashu P2PK keys in Nostr events. The buyer
can derive `buyerP2pk` from local wallet/marketplace seed material, or the Cashu
driver can generate it per trade and persist it with the operation state.

## Marketplace Advertisement

### Seller Escrow Method

The seller's `kind:17388` escrow method should gain Cashu payment forms and a
Cashu P2PK address proof.

Example tags:

```jsonc
[
  ["p", "<escrow-nostr-pubkey>"],
  ["o", "BTC", "cashu:sat:https://mint.example.com", "hostr"],
  ["o", "USD", "cashu:usd:https://mint.example.com", "hostr"],
  ["i", "cashu:p2pk:<seller-p2pk-pubkey>", "nostr:<seller-signature>"]
]
```

Suggested ownership message for `i` proof:

```text
Cashu P2PK ownership proof
nostr:<seller-nostr-pubkey>
cashu:p2pk:<seller-p2pk-pubkey>
```

### Escrow Service

Escrow operators advertise a `kind:30303` service with `type: "CASHU"`.

```jsonc
{
  "pubkey": "<escrow-nostr-pubkey>",
  "type": "CASHU",
  "maxDuration": 1209600,
  "fee": {
    "ppm": 10000,
    "base": "0",
    "min": "0",
    "max": "0"
  },
  "params": {
    "mints": [
      { "url": "https://mint.example.com", "units": ["sat", "usd"] }
    ],
    "escrowPubkey": "<escrow-p2pk-pubkey>",
    "feePubkey": "<escrow-fee-p2pk-pubkey>",
    "settlementRatios": [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
    "scriptVersion": 1,
    "requiredNuts": [3, 7, 9, 11, 12]
  }
}
```

The marketplace route is valid only when the buyer can find an intersection
between:

- seller accepted Cashu mints/units;
- escrow accepted Cashu mints/units;
- buyer wallet funds;
- listing/order denomination;
- security deposit denomination, if present.

## Component Scripts

The payment package contains up to three independently funded components.

### `feeScript`

The fee can be modeled in two ways.

#### Separate fee proofs

The buyer creates a separate proof bundle directly spendable by the escrow:

```jsonc
[
  "P2PK",
  {
    "nonce": "<random>",
    "data": "<escrow-fee-p2pk-pubkey>",
    "tags": [["sigflag", "SIG_INPUTS"]]
  }
]
```

This is simple and lets the escrow redeem the fee whenever it wants. It is not
atomic with `paymentScript` or `securityDepositScript`. The escrow can take this
fee even if the principal is later refunded.

This is suitable for a nonrefundable booking/handling fee.

#### Atomic fee output

If the escrow fee must be paid only when settlement happens, do not make it a
separate input. Instead, include escrow fee outputs inside every settlement
template for `paymentScript` and/or `securityDepositScript`.

For example, a `paymentScript` 70 percent seller settlement can output:

```text
escrow fee amount -> escrowFeeP2pk
net seller amount -> sellerP2pk
net buyer amount  -> buyerP2pk
```

This is atomic with that component because the fee is paid from the same locked
inputs in the same `SIG_ALL` swap.

Important: standard NUT-11 `SIG_ALL` requires compatible locked inputs. A
direct escrow fee input with a different P2PK policy cannot safely be mixed into
the same `SIG_ALL` swap as the principal escrow inputs. If the fee must be
atomic, prefer fee outputs inside each principal component.

### `paymentScript`

The buyer funds the reservation payment amount into proofs locked under a
2-of-3 active policy:

```jsonc
[
  "P2PK",
  {
    "nonce": "<random-per-proof>",
    "data": "<escrow-p2pk-pubkey>",
    "tags": [
      ["sigflag", "SIG_ALL"],
      ["pubkeys", "<buyer-p2pk-pubkey>", "<seller-p2pk-pubkey>"],
      ["n_sigs", "2"],
      ["locktime", "<seller-claim-unix-time>"],
      ["refund", "<seller-p2pk-pubkey>"],
      ["n_sigs_refund", "1"]
    ]
  }
]
```

Before locktime:

- escrow + buyer can spend;
- buyer + seller can spend;
- escrow alone cannot spend;
- seller alone cannot spend.

After locktime:

- seller can spend alone through the NUT-11 refund path.

The tag is named `refund` in NUT-11, but in this protocol it is the seller
timeout claim path.

### `securityDepositScript`

The security deposit uses the same structure as `paymentScript`, but it is a
separate component with its own amount, locktime, settlement ladder, and hashes.

The locktime may differ from the payment locktime. For accommodation flows, a
reasonable policy is:

- payment locktime: seller claim after check-in or after reservation start;
- security deposit locktime: seller claim after checkout plus dispute window.

If `paymentScript` and `securityDepositScript` have different locktimes, they
cannot be represented as one identical NUT-11 policy. Keep them as separate
components and settle them independently.

## Settlement Ladder

Because escrow cannot create arbitrary whitelisted outputs, each principal
component includes a pre-authorized ladder.

For each ratio in the escrow service's `settlementRatios`, the buyer creates an
exact `SIG_ALL` swap template:

```text
ratio 0:   seller 0%,   buyer 100%
ratio 10:  seller 10%,  buyer 90%
ratio 20:  seller 20%,  buyer 80%
...
ratio 90:  seller 90%,  buyer 10%
ratio 100: seller 100%, buyer 0%
```

Each template commits to:

- the exact input proofs for the component;
- exact output blinded messages;
- exact fee output, if the component pays an atomic escrow fee;
- exact buyer and seller payout amounts;
- the trade id and component id in the signed metadata.

The buyer signs each template with `SIG_ALL`. Later, the escrow chooses one
template, adds its own signature, and submits the swap.

Escrow cannot redirect the payment because changing any output invalidates the
buyer's pre-signature.

### Template Object

```jsonc
{
  "templateId": "payment:70",
  "component": "payment",
  "ratio": 70,
  "sellerAmount": "70000",
  "buyerAmount": "30000",
  "escrowFeeAmount": "1000",
  "inputsHash": "<sha256-canonical-inputs>",
  "outputsHash": "<sha256-canonical-outputs>",
  "sigAllMessageHash": "<sha256-nut11-sig-all-message>",
  "buyerSig": "<schnorr-signature>",
  "outputs": [
    {
      "role": "escrowFee",
      "amount": "1000",
      "B_": "<blinded-message>"
    },
    {
      "role": "seller",
      "amount": "70000",
      "B_": "<blinded-message>"
    },
    {
      "role": "buyer",
      "amount": "30000",
      "B_": "<blinded-message>"
    }
  ]
}
```

Amounts are in the Cashu unit's smallest denomination for the selected mint.

## Output Recovery

For non-interactive escrow, the settlement outputs must be recoverable by their
intended recipients after the escrow submits a swap.

There are two options.

### Buyer-generated recipient outputs

The buyer creates blinded outputs whose secrets are P2PK-locked to the intended
recipient, then includes recovery data encrypted to that recipient.

Benefits:

- seller does not need to be online during booking;
- escrow can settle later without asking for outputs;
- seller still controls final spend because outputs are locked to `sellerP2pk`.

Tradeoff:

- the buyer knows the output secrets and blinding data, although not the seller
  P2PK private key. This is acceptable for non-interactive flows but leaks more
  recovery metadata to the buyer than recipient-generated outputs.

### Recipient-generated outputs

Buyer and seller each provide blinded outputs for possible payouts. This gives
cleaner custody/privacy properties, because each recipient alone has their own
unblinding material.

Tradeoff:

- the buyer and seller need an interactive setup round, or the seller must
  pre-publish reusable output descriptors, which has privacy and replay issues.

For Hostr, the first implementation should probably use buyer-generated
P2PK-locked recipient outputs for non-interactive reservations, then support
recipient-generated outputs as an optional stronger mode later.

## Single Reservation Payment Proof

The reservation/order can attach one `paymentProof` that commits to all Cashu
components.

Public order proof:

```jsonc
{
  "listing": { "...": "listing event JSON" },
  "paymentProof": {
    "method": "cashu_escrow",
    "params": {
      "version": 1,
      "mint": "https://mint.example.com",
      "unit": "sat",
      "amount": "151000",
      "paymentAmount": "100000",
      "securityDepositAmount": "50000",
      "escrowFeeAmount": "1000",
      "fundingPackageEvent": "<public-cashu-escrow-funding-event-id>",
      "fundingPackageHash": "<sha256-canonical-package>",
      "fundingPackageMode": "public_plaintext",
      "components": [
        {
          "id": "fee",
          "kind": "fee",
          "amount": "1000",
          "proofSetHash": "<sha256-fee-proofs>",
          "policyHash": "<sha256-fee-policy>"
        },
        {
          "id": "payment",
          "kind": "payment",
          "amount": "100000",
          "proofSetHash": "<sha256-payment-proofs>",
          "policyHash": "<sha256-payment-policy>",
          "settlementLadderHash": "<sha256-payment-ladder>",
          "locktime": 1767225600
        },
        {
          "id": "securityDeposit",
          "kind": "securityDeposit",
          "amount": "50000",
          "proofSetHash": "<sha256-security-deposit-proofs>",
          "policyHash": "<sha256-security-deposit-policy>",
          "settlementLadderHash": "<sha256-security-deposit-ladder>",
          "locktime": 1767830400
        }
      ]
    }
  },
  "escrow": {
    "escrowService": "<kind:30303 CASHU event JSON>",
    "sellerEscrowMethod": "<kind:17388 event JSON>"
  }
}
```

The public proof intentionally contains hashes, amounts, mint, unit, escrow
context, and a funding event reference. The referenced funding event MAY expose
the full P2PK-locked funding package publicly, or MAY expose only encrypted
content while keeping the same public event id and package hash.

## Public Funding Event

The funding package should be carried by a network-public Nostr event authored
by the buyer's temporary trade key. This gives seller, escrow, and the buyer's
other devices a durable relay-addressable object to recover from.

The event is public, but the author pubkey is the trade temp-key rather than the
buyer's account identity.

This preserves account-level buyer privacy, not trade metadata privacy. Relays
can still see the listing anchor, trade id, mint, unit, escrow pubkey, and
amount commitments unless `public_encrypted` is used.

```jsonc
{
  "kind": "<cashu-escrow-funding-kind>",
  "pubkey": "<buyer-temp-trade-pubkey>",
  "tags": [
    ["d", "<trade-id>"],
    ["a", "<listing-anchor>"],
    ["p", "<seller-nostr-pubkey>", "", "seller"],
    ["p", "<escrow-nostr-pubkey>", "", "escrow"],
    ["method", "cashu_escrow"],
    ["mint", "https://mint.example.com"],
    ["unit", "sat"],
    ["package_hash", "<sha256-canonical-package>"],
    ["package_mode", "public_plaintext"]
  ],
  "content": "{...canonical funding package JSON...}"
}
```

The package has two supported content modes:

- `public_plaintext`: the content contains raw escrow-funded P2PK proofs,
  policies, settlement ladders, buyer pre-signatures, and public recovery
  commitments. This maximizes relay recovery and lets seller/escrow verify
  without private message history.
- `public_encrypted`: the event remains public and addressable, but the content
  is encrypted to seller and escrow. This improves trade privacy while keeping a
  public event id for the order proof.

`public_plaintext` MUST NOT contain ordinary wallet/change proofs. It may
contain only proofs locked by the declared escrow scripts, plus enough data for
seller and escrow to verify the package.

### Funding Package Content

```jsonc
{
  "version": 1,
  "method": "cashu_escrow",
  "tradeId": "<trade-id>",
  "listingAnchor": "<kind:pubkey:d-tag>",
  "mint": "https://mint.example.com",
  "unit": "sat",
    "participants": {
    "buyer": {
      "nostrPubkey": "<buyer-temp-trade-pubkey>",
      "cashuPubkey": "<buyer-p2pk-pubkey>"
    },
    "seller": {
      "nostrPubkey": "<seller-nostr-pubkey>",
      "cashuPubkey": "<seller-p2pk-pubkey>"
    },
    "escrow": {
      "nostrPubkey": "<escrow-nostr-pubkey>",
      "cashuPubkey": "<escrow-p2pk-pubkey>",
      "feePubkey": "<escrow-fee-p2pk-pubkey>"
    }
  },
  "components": [
    {
      "id": "fee",
      "kind": "fee",
      "amount": "1000",
      "proofs": ["<cashu-proof-json>"],
      "policy": {
        "type": "direct-p2pk",
        "recipient": "escrowFee"
      }
    },
    {
      "id": "payment",
      "kind": "payment",
      "amount": "100000",
      "proofs": ["<cashu-proof-json>"],
      "policy": {
        "type": "p2pk-escrow-v1",
        "active": {
          "keys": ["escrow", "buyer", "seller"],
          "nSigs": 2
        },
        "timeout": {
          "locktime": 1767225600,
          "claimant": "seller",
          "nSigs": 1
        },
        "sigflag": "SIG_ALL"
      },
      "settlementTemplates": ["<template objects>"]
    },
    {
      "id": "securityDeposit",
      "kind": "securityDeposit",
      "amount": "50000",
      "proofs": ["<cashu-proof-json>"],
      "policy": {
        "type": "p2pk-escrow-v1",
        "active": {
          "keys": ["escrow", "buyer", "seller"],
          "nSigs": 2
        },
        "timeout": {
          "locktime": 1767830400,
          "claimant": "seller",
          "nSigs": 1
        },
        "sigflag": "SIG_ALL"
      },
      "settlementTemplates": ["<template objects>"]
    }
  ]
}
```

The canonical JSON hash of this package is what the public order proof commits
to.

## Verification

Escrow verifies the package before accepting the reservation:

1. The seller's `kind:17388` accepts the selected mint/unit.
2. The escrow `kind:30303` accepts the selected mint/unit.
3. The selected mint advertises required NUT support.
4. Every proof verifies against mint keys and DLEQ data where available.
5. Every proof is currently `UNSPENT` by NUT-07 state check.
6. Proof amounts match the component amounts.
7. `paymentScript` amount matches the reservation amount.
8. `securityDepositScript` amount matches listing/order security deposit terms.
9. `feeScript` amount matches the escrow service fee policy.
10. Principal component P2PK policies exactly match `p2pk-escrow-v1`.
11. Each principal component has the required settlement ratios.
12. Every settlement template's `SIG_ALL` message hash is correct.
13. The buyer signature on every template is valid.
14. Settlement outputs pay only buyer, seller, and allowed escrow fee roles.
15. Public payment proof hashes match the public funding event content.
16. The funding event author is the expected buyer temporary trade key.
17. The buyer temporary trade key is authorized by the buyer participant proof
    or by the order's established temp-key authorization rules.

Seller verifies the package before treating the reservation as funded:

1. Escrow is trusted by the seller's current escrow method.
2. Mint/unit are accepted.
3. Security deposit and payment amounts match listing/order terms.
4. Seller timeout path and locktimes match agreed policy.
5. Seller can recover or receive all seller payout outputs after settlement.
6. Escrow has published or privately sent a signed funding acknowledgement.
7. The funding event author matches the buyer temp-key used in the order.

Public clients generally cannot fully verify raw Cashu proofs without seeing the
funding event content. If the funding event uses `public_plaintext`, observers
can verify more of the package directly. If it uses `public_encrypted`,
observers should rely on the escrow's signed order/commit confirmation or the
seller's accepted order state.

## Lifecycle

### 1. Route selection

The buyer resolves a route:

```text
listing -> seller escrow method -> CASHU escrow service -> mint/unit
```

The Cashu driver calculates:

```text
paymentAmount
securityDepositAmount
escrowFeeAmount
totalFundingAmount = payment + securityDeposit + fee
```

### 2. Funding

The buyer swaps wallet proofs into:

```text
feeScript proofs
paymentScript proofs
securityDepositScript proofs
```

The buyer persists all inputs, outputs, recovery data, and mint responses before
publishing anything.

### 3. Funding event publication

The buyer's temporary trade key publishes the public funding event, then the
buyer publishes the public order proof referencing that funding event. In
`public_plaintext` mode, seller and escrow can recover the package from relays.
In `public_encrypted` mode, the event remains public but the package content is
encrypted to seller and escrow.

### 4. Escrow acceptance

The escrow verifies the package. If valid, escrow publishes a commit/acceptance
order or sends an encrypted signed acknowledgement referencing:

```text
tradeId
fundingPackageHash
component hashes
accepted settlement ladder
```

### 5. Settlement by escrow

The escrow chooses a template for `paymentScript` and/or
`securityDepositScript`, adds the escrow signature, and submits the NUT-03 swap
to the mint.

The selected template may be:

```text
payment:100            full payment to seller
payment:0              full payment refund to buyer
payment:70             split payment
securityDeposit:0      full deposit refund to buyer
securityDeposit:100    full deposit to seller
securityDeposit:30     partial deposit claim
```

The escrow should publish or send a settlement record containing:

```jsonc
{
  "method": "cashu_escrow",
  "tradeId": "<trade-id>",
  "component": "securityDeposit",
  "templateId": "securityDeposit:30",
  "mint": "https://mint.example.com",
  "spentProofSetHash": "<hash>",
  "outputsHash": "<hash>",
  "settledAt": 1767830400
}
```

### 6. Buyer/seller collaborative settlement

Buyer and seller can bypass escrow at any time while the proofs are unspent.
They create a fresh `SIG_ALL` swap template and both sign it.

This is the only path that requires live interaction.

### 7. Seller timeout claim

After the component locktime, the seller can spend the component alone via the
NUT-11 refund path.

If the seller claims after timeout, the escrow cannot later reverse that same
component. Cashu proofs are spent by the first valid mint swap.

## Protocol Ownership

Any adoption of these component proposals belongs in the canonical NMDK NIPs,
shared schemas, and drivers linked above. Hostr must consume the resulting
models and operations rather than add app-owned Cashu wire types, event kinds,
or settlement logic.

The current Order/Payment NIP already defines Payment, Payment Ack/Nack, and
Payment Settlement events. This research does not allocate a separate funding
event kind or define an alternative `cashu_escrow` payment-proof format. Its
remaining payload examples are conceptual component sketches, not valid current
wire examples.

## Proposed Component Implementation Notes

- Store ordinary wallet proofs and change proofs only in encrypted local
  storage or encrypted wallet events.
- Public funding events may contain raw `feeScript`, `paymentScript`, and
  `securityDepositScript` proofs only when those proofs are already locked by
  the declared escrow P2PK policies.
- Do not put recipient unblinding secrets or any data that creates immediately
  spendable bearer proofs in public content unless the resulting proofs remain
  locked to the intended P2PK recipient.
- The public order proof is a commitment, not the full Cashu proof package.
- Startup recovery must check NUT-07 state for every component.
- If a swap was submitted and the response was lost, use NUT-09 restore with
  the stored blinded outputs.
- Settlement templates should be deterministic and canonicalized before hashing.
- The marketplace package should treat this as one payment proof with multiple
  components; the Cashu driver owns the proof mechanics.
- If the funding package is too large for one event, split it into chunks and
  commit to a manifest hash in the public order proof.

## Package Size

This method is intentionally large. With 10 percent settlement increments:

```text
paymentScript:          11 settlement templates
securityDepositScript:  11 settlement templates
feeScript:               0 or 1 simple proof bundle
```

Each template contains output commitments and at least one buyer
pre-authorization. If recipient recovery data is included for every ratio, the
funding package can become too large for comfortable relay handling.

The NIP should allow package chunking:

```jsonc
{
  "version": 1,
  "method": "cashu_escrow_package_manifest",
  "tradeId": "<trade-id>",
  "packageMode": "public_plaintext",
  "rootHash": "<sha256-full-package>",
  "chunks": [
    { "index": 0, "event": "<event-id>", "hash": "<chunk-hash>" },
    { "index": 1, "event": "<event-id>", "hash": "<chunk-hash>" }
  ]
}
```

The public order proof should commit to the manifest hash, not every chunk id.
That allows republishing failed chunks without changing the order proof, as long
as the reconstructed package hash is unchanged.

## Open Questions

- Ratio step size: 10 percent is simple, but services may want 5 percent or
  basis-point precision.
- Fee policy: separate nonrefundable fee, atomic fee outputs, or both.
- Output generation mode: buyer-generated P2PK-locked outputs first, optional
  recipient-generated outputs later.
- Funding event mode: default to `public_plaintext` for recovery, or default to
  `public_encrypted` for trade privacy.
- Settlement record visibility: public plaintext, public encrypted, or public
  hash plus private details.
- Whether the escrow acknowledgement should be an order event, an order
  transition event, or an optional private message.

## References

- Cashu NUT-03: swaps.
- Cashu NUT-07: proof state checks.
- Cashu NUT-09: restore.
- Cashu NUT-11: P2PK spending conditions.
- Cashu NUT-12: DLEQ proofs.
- NIP-60: Cashu wallet events.
- NIP-61: nutzaps.
