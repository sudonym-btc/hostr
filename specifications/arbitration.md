# NIP-XX

## Arbitration Services

`draft` `optional`

This NIP defines a protocol for decentralized arbitration services on Nostr, enabling trust-minimized commerce between buyers and sellers. Arbiters advertise their services, buyers and sellers declare their trusted arbiters, accepted arbitration policies, and accepted payment forms, and the protocol coordinates on-chain escrow settlement with arbitration capabilities.

## Terms

- **Buyer** — Nostr user making a payment for a good or service.
- **Seller** — Nostr user providing a good or service.
- **Arbiter** — Nostr user operating an arbitration service that can verify escrow funding and arbitrate disputes.
- **Trade** — A single arbiter-backed transaction between a buyer and seller, mediated by an arbiter.

## Event Kinds

| Kind    | Name           | Type                      | Description                                                |
| ------- | -------------- | ------------------------- | ---------------------------------------------------------- |
| `17388` | Arbitration Methods | Replaceable               | User's accepted payment forms, trusted arbiters, and settlement address proofs |
| `30303` | Arbitration Service | Parameterized replaceable | Arbiter's service advertisement                    |

## Arbitration Service (`kind:30303`)

Published by arbiters to advertise their service. The `d` tag is a stable service identifier chosen by the arbiter and MUST remain stable across updates to the same advertised service.

### Content

JSON object:

```jsonc
{
  "pubkey": "<arbiter-nostr-pubkey>",
  "type": "EVM escrow",
  "policy": "evm:sha256:<sha256-of-runtime-bytecode>",
  "maxDuration": 31536000,
  "fee": {
    "ppm": 10000,
    "base": "0",
    "min": "0",
    "max": "0",
    "assetOverrides": {
      "native": {
        "ppm": 10000,
        "base": "0",
        "min": "0",
        "max": "0",
      },
      "0xdAC17F958D2ee523a2206206994597C13D831ec7": {
        "ppm": 10000,
        "base": "50000",
        "min": "10000",
        "max": "1000000",
      },
    },
  },
  "params": {
    "arbiterAddress": "<eip55-checksummed-address>",
    "contractAddress": "<deployed-escrow-contract-address>",
    "contractBytecodeHash": "<sha256-of-runtime-bytecode>",
    "chainId": 30,
  },
}
```

| Field                  | Type    | Description                                                                                                                                         |
| ---------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pubkey`               | string  | The arbiter's Nostr hex public key.                                                                                                         |
| `type`                 | string  | Human-readable service type label only. Clients MUST NOT use this as the driver or trust matching key. |
| `policy`               | string  | Canonical arbitration policy hash. This is the machine-readable value used to select a driver and to match seller `arbitrationMethods`. |
| `maxDuration`          | integer | Maximum escrow lock duration in seconds.                                                                                                            |
| `fee`                  | object  | Arbitration service fee policy.                                                                                                                      |
| `params`               | object  | Policy-driver specific parameters. For an EVM escrow policy, see below.                                                                              |

Each `kind:30303` arbitration service event advertises exactly one `policy`.
If the same arbiter supports multiple contracts, scripts, or settlement rules,
the arbiter MUST publish one arbitration service event per policy.

Clients use `policy` to select the implementation driver, for example by
choosing the local driver whose advertised policy list contains the service
policy. For EVM escrow contracts, the policy SHOULD be derived from the runtime
bytecode hash. For Cashu escrow or auction policies, the policy SHOULD be
derived from the locking script or policy hash.

#### EVM Params

When `policy` identifies an EVM escrow contract, `params` contains:

| Field                  | Type    | Description                                                                                                                       |
| ---------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `arbiterAddress`       | string  | The operator's EVM address (EIP-55 checksum).                                                                                     |
| `contractAddress`      | string  | Deployed escrow smart contract address.                                                                                           |
| `contractBytecodeHash` | string  | SHA-256 hash of the contract's runtime bytecode. This value MUST match the EVM bytecode hash represented by `policy`. |
| `chainId`              | integer | EVM chain ID (e.g. `30` for Rootstock mainnet).                                                                                   |

#### Fee

The `fee` object contains:

| Field            | Type    | Description                                                                                              |
| ---------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| `ppm`            | integer | Proportional fee in parts per million. `10000` = 1%.                                                     |
| `base`           | string  | Flat base fee in the selected asset's smallest unit.                                                     |
| `min`            | string  | Minimum fee floor in the selected asset's smallest unit. `0` = no floor.                                 |
| `max`            | string  | Maximum fee cap in the selected asset's smallest unit. `0` = no maximum.                                 |
| `assetOverrides` | object  | Optional complete fee overrides keyed by asset contract address, or `"native"` for the chain's native asset. |

Each entry in `assetOverrides` is a complete `fee` object without its own `assetOverrides`. When no override exists for a selected asset, clients use the top-level fee.

**Fee calculation:** `fee = clamp(floor(amount × ppm / 1,000,000) + base, min, max)`

### Tags

```json
["d", "<service-id>"]
```

## Arbitration Methods (`kind:17388`)

Usually published by sellers to declare which arbitration services they trust, which arbitration policies they understand, which payment forms they accept, and which settlement addresses they control. When placing an order, buyers normally defer to the seller's arbitration methods event and choose from the seller's advertised arbiter, policy, and payment options.

Buyers MAY publish their own arbitration methods event to advertise preferred arbitration services, understood policies, or accepted payment forms. When a buyer pays through an arbitration service used with a seller, the buyer SHOULD adopt that arbiter pubkey and policy in their own arbitration methods event so future counterparties can discover that trust relationship.

This event is replaceable per pubkey. Implementations SHOULD publish at most one current arbitration methods event per user. The event content is empty.

### Tags

| Tag | Format                                                   | Description                                                                                                                            |
| --- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `p` | `["p", "<arbiter-pubkey>"]`                              | Trusted arbiter pubkey. Repeat for multiple.                                                                                           |
| `c` | `["c", "<policy>"]`                               | Accepted arbitration policy hash. Repeat for multiple. This MUST match an arbitration service's `policy` field exactly.               |
| `o` | `["o", "<denomination>", "<asset-id>", "<app-id?>"]` | Accepted payment form mapping a denomination to a concrete asset location. The optional fourth element scopes forms to an application. |
| `i` | `["i", "evm:address:<address>", "eip191:<signature>"]`   | EVM address ownership proof. Required when these arbitration methods are used for EVM escrow settlement.                                |

#### EVM Address Proof Tags

An arbitration methods event used for EVM escrow settlement MUST include an `i` tag proving that the event author controls the EVM address that will receive seller-side settlement funds:

```json
["i", "evm:address:0x1111111111111111111111111111111111111111", "eip191:0x..."]
```

The address SHOULD be EIP-55 checksummed. The proof is an EIP-191 personal-sign signature by that EVM address over the exact UTF-8 payload below, with no trailing newline:

```text
EVM address ownership proof
nostr:<arbitration-methods-event-pubkey>
evm:address:<eip55-address>
```

Implementations SHOULD publish at most one current `evm:address:` tag per arbitration methods event. If more than one is present, consumers SHOULD use the last valid proof and ignore earlier EVM address tags.

#### Payment Form Tags

The `o` tag maps a denomination code (e.g. `"BTC"`, `"USD"`) to a concrete asset identifier:

```json
["o", "BTC", "30:0x0000000000000000000000000000000000000000", "<app-id>"]
```

For EVM assets, the asset ID format is `<chainId>:<assetAddress>`. The zero address (`0x000...`) denotes the chain's native asset. Non-EVM payment rails MAY use their own asset IDs, such as `"BTC"` for Lightning-denominated BTC.

When present, `<app-id>` scopes the payment form to an application.

### Example

```jsonc
{
  "kind": 17388,
  "pubkey": "<seller-pubkey>",
  "tags": [
    ["p", "abc123..."],
    ["p", "def456..."],
    ["c", "evm:sha256:a1b2c3d4e5..."],
    ["i", "evm:address:0x1111111111111111111111111111111111111111", "eip191:0x..."],
    ["o", "BTC", "30:0x0000000000000000000000000000000000000000", "example"],
    ["o", "USD", "30:0xdAC17F958D2ee523a2206206994597C13D831ec7", "example"],
  ],
  "content": "",
  // ...
}
```

## Mutual Arbitration Resolution

When a buyer and seller wish to transact, their clients SHOULD automatically resolve a mutually trusted arbiter:

1. Query both parties' `kind:17388` (Arbitration Methods) events.
2. Find the intersection of trusted arbiter pubkeys (`p` tags).
3. Find the intersection of supported arbitration policies (`c` tags).
4. Query `kind:30303` (Arbitration Service) events from mutually trusted pubkeys whose `policy` field matches a mutually supported policy.
5. If no mutual match exists or the buyer doesn't have preferred arbiters, fall back to the seller's trusted arbiters.

## On-Chain Escrow Contract

The actual implementation of an escrow contract is irrelevant to this protocol, as long as both buyer and seller publish that they recognize and accept the arbitration policy. For an EVM escrow contract, that policy is normally derived from the contract's runtime bytecode hash. Once both parties advertise familiarity with a particular policy, clients can assume those parties know how to inspect, verify, and interact with contracts or scripts matching that policy.

The following EVM contract lifecycle describes one compatible escrow implementation.

The on-chain escrow contract manages funds with the following lifecycle:

### Trade Lifecycle

```
                ┌──── releaseToCounterparty ────┐
                │                                ▼
(empty) ── createTrade ──► funded ──► released / arbitrated / claimed
                │                        ▲
                │       ┌── arbitrate ───┘
                │       │
                └───────┼── claim (after unlockAt) ──► claimed
```

### Trade Structure

Each on-chain trade is identified by a `tradeId` (bytes32) and stores:

| Field       | Type    | Description                                                   |
| ----------- | ------- | ------------------------------------------------------------- |
| `buyer`     | address | The funding party.                                            |
| `seller`    | address | The counterparty receiving goods/services.                    |
| `arbiter`   | address | The arbiter's EVM address.                                    |
| `asset`     | address | ERC-20 asset address, or `address(0)` for native asset.       |
| `amount`    | uint256 | Total escrowed amount.                                        |
| `unlockAt`  | uint256 | Unix timestamp after which the seller can claim unilaterally. |
| `escrowFee` | uint256 | Flat fee in asset units, deducted at settlement.              |

For marketplace orders defined by the Orders NIP, the on-chain `tradeId` MUST be
the order group ID from the public `kind:32122` order's `d` tag, not the private
trade conversation id from the `trade` tag. This binds escrowed funds to the
final public participant tuple (buyer, seller, and arbiter) and prevents a proof
for one participant set from being replayed into another order group.

### Operations

| Operation               | Authorized Signer         | Description                                                                                            |
| ----------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------ |
| `createTrade`           | Buyer (msg.sender)        | Deposits funds. Native asset via `msg.value`; ERC-20 via `transferFrom`.                               |
| `releaseToCounterparty` | Buyer OR Seller (EIP-712) | Voluntarily sends funds to the other party. If the buyer signs, funds go to the seller and vice versa. |
| `claim`                 | Seller (EIP-712)          | Claims funds after `unlockAt` has passed.                                                              |
| `arbitrate`             | Arbiter (EIP-712)         | Splits funds: `factor/1000` to seller, remainder to buyer. `factor` is `0`–`1000` (0.1% precision).    |
| `withdraw`              | Beneficiary (EIP-712)     | Pulls settled funds using `Withdraw(token,destination,nonce)`; the contract consumes and increments the beneficiary nonce. |

All operations use EIP-712 typed-data signatures, enabling gas-sponsored relay
(anyone can broadcast the transaction). The current MultiEscrow profile uses
EIP-712 domain name `Nostr MultiEscrow` and domain version `7`. Withdraw
authorizations MUST include the contract-reported beneficiary nonce and MUST be
rejected after that nonce has been consumed.

### Settlement

All settlements credit a `balances[recipient][asset]` mapping (pull pattern) rather than performing direct transfers. This prevents reentrancy and enables batched withdrawals.

### Arbitration

When a dispute arises:

1. Either party messages the arbiter via Nostr DMs.
2. The arbiter reviews the trade context (order group ID, trade conversation id, role-tagged participants, the order's embedded listing snapshot, payment proof, on-chain state).
3. The operator submits an `arbitrate` transaction with a `factor` value:
   - `0` = full refund to buyer
   - `1000` = all funds to seller
   - `500` = 50/50 split
4. `amountAfterFee = amount - escrowFee`
5. `forwardAmount = (amountAfterFee × factor) / 1000` → credited to seller
6. `amountAfterFee - forwardAmount` → credited to buyer
7. `escrowFee` → credited to arbiter

## Arbitration Payment Proof Context

When an order is backed by an arbiter-mediated escrow, the Payment event
contains generic payment evidence plus arbitration-specific verification
context. The signed listing snapshot is carried by the linked Order event, not
inside the payment proof:

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
            "policyType": "evm:multi-escrow",
            "chainId": 33,
            "contractAddress": "<deployed-escrow-contract-address>",
            "contextHash": "<32-byte-context-hash>",
            "recycleCovenantHash": "<32-byte-recycle-covenant-hash>",
            "timeoutClaimantAddress": "<timeout-claimant-address>",
            "unlockAt": "1781067882",
            "escrowFee": {
              "value": "0",
              "denomination": "BTC",
              "decimals": 8,
              "assetId": "33:0x0000000000000000000000000000000000000000"
            },
            "arbitration": { "type": "continuous", "denominator": "1000" }
          },
          "paths": []
        }
      },
      "params": {
        "txHash": "<evm-transaction-hash>",
        "policyId": "evm:multi-escrow",
        "policyType": "evm:multi-escrow",
        "policyHash": "<sha256-of-runtime-bytecode>",
        "contractBytecodeHash": "<sha256-of-runtime-bytecode>",
        "chainId": 33,
        "contractAddress": "<deployed-escrow-contract-address>",
        "tradeId": "<order-group-id>",
        "buyerAddress": "<buyer-evm-address>",
        "sellerAddress": "<seller-evm-address>",
        "arbiterAddress": "<arbiter-evm-address>",
        "assetAddress": "<asset-address>",
        "value": "50000",
        "paymentAmount": "50000",
        "fundedValue": "50000",
        "bondAmount": "0",
        "escrowFee": "0",
        "unlockAt": "1781067882",
        "timeoutClaimantAddress": "<timeout-claimant-address>",
        "contextHash": "<32-byte-context-hash>",
        "recycleCovenantHash": "<32-byte-recycle-covenant-hash>",
        "denomination": "BTC",
        "decimals": 8
      }
    },
    "arbitration": {
      "arbitrationService": { "...": "ArbitrationService kind:30303 event JSON" },
      "paymentMethod": { "...": "seller ArbitrationMethods kind:17388 event JSON" }
    }
  }
}
```

`paymentProof.terms` is the application-independent lock statement: asset,
parties, controls, amounts, and possible settlement paths. `paymentProof.params`
is specific to the payment driver and carries the method-specific evidence
needed to verify that those terms are actually funded or locked. For EVM escrow
drivers, `params.txHash` is the transaction hash to verify. Clients MUST derive
the actual funding facts from the transaction receipt and decoded logs, then
compare them to the public or decrypted terms. `proof.arbitration.arbitrationService`
and `proof.arbitration.paymentMethod` are context for interpreting that generic
payment proof as satisfying the seller's selected arbitration methods; they are
not required for the payment proof to describe itself.

After payment proof validation, arbiters MUST reconcile the verified payment
terms against the linked Order event. The Order event SHOULD contain
`content.listing`, a full signed NIP-99 listing snapshot captured at purchase
time. The arbiter derives expected price and listing terms from that snapshot,
the order `quantity`, `start`, and `end`, then compares them to the sum of
accepted verified payment terms, including declared lock amount, asset,
participants, settlement paths or arbitration conditions, optional security
bond, optional escrow fee, and unlock/timeout terms.

The Payment event MAY carry a sealed payment proof envelope instead of public
proof content. In that case the arbiter MUST first resolve the matching
`payment_proof_key` tag for its pubkey, decrypt the sealed payload, verify that
the decrypted proof hash matches the envelope `proofId`, and then apply the
method-specific checks below.

Alternatively, the Payment event MAY leave `paymentProof.driver` visible and
encrypt only `paymentProof.params`:

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

In that mode the arbiter MUST resolve a `payment_proof_key` whose proof id
matches the encrypted params `proofId`, decrypt the params payload, verify the
clear params hash, and then validate the payment from the clear params.

The Payment event MAY also leave `paymentProof.driver` and `paymentProof.params`
visible while sealing only `paymentProof.terms`:

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

In that mode the arbiter MUST resolve a `payment_proof_key` whose proof id
matches the sealed terms `proofId`, decrypt the terms payload, verify the clear
terms hash, and then validate that params prove those terms.

### Verification

Clients and arbiters MUST verify arbitration-backed payment proofs independently
from linked order terms:

1. Validate the `arbitrationService` event signature and pubkey.
2. Verify the seller's `arbitrationMethods` event lists the arbiter pubkey in a `p` tag.
3. Verify the seller's `arbitrationMethods` event lists the service policy in a `c` tag.
4. Verify the seller's `arbitrationMethods` event includes a valid EVM address ownership proof in an `i` tag.
5. Resolve clear `paymentProof.terms` and `paymentProof.params`, decrypting sealed terms or params first when needed.
6. Query the transaction receipt for `paymentProof.params.txHash` and decode the matching `TradeCreated` event.
7. Verify the decoded `TradeCreated` fields match the self-contained payment terms.
8. Verify the on-chain seller address matches the EVM address proven by the seller's `arbitrationMethods`.
9. Verify the on-chain funded amount covers the declared lock amount and required settlement paths or arbitration condition in `paymentProof.terms` (accounting for asset denomination and decimals).
10. Verify the seller's `arbitrationMethods` accepts the on-chain asset for the payment denomination.
Steps 1-10 are the payment-proof validation surface. Payment Ack and Payment
Nack events MUST be based only on that surface and MUST NOT depend on the linked
order, bid, or listing snapshot.

Separately, clients and arbiters MAY verify the linked order terms:

1. Verify the linked Order event contains a valid signed embedded listing snapshot whose event address matches the order `a` tag.
2. Derive the expected order price and listing requirements from the embedded listing snapshot and compare them to the order amount and normalized verified payment terms.

## Related NIPs

- [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md) — Event structure and parameterized replaceable events.
- [NIP-17](https://github.com/nostr-protocol/nips/blob/master/17.md) — Private message rumor kind `14`.
- [NIP-44](https://github.com/nostr-protocol/nips/blob/master/44.md) — Encryption scheme.
- [NIP-59](https://github.com/nostr-protocol/nips/blob/master/59.md) — Gift wrap.
