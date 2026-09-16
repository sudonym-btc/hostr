# Cashu Marketplace Notes

This file preserves the May 2026 Cashu mint-support research for Hostr
marketplace escrow work. These measurements are dated observations, not current
reachability guarantees. Design discussion lives in [CASHU_ESCROW.md](CASHU_ESCROW.md).

NMDK owns the Cashu drivers and payment models. The current contract is the
[canonical Order/Payment NIP](dependencies/nmdk/dependencies/nips/order-nip/XX.md)
and the [Cashu driver documentation](dependencies/nmdk/dependencies/marketplace-cashu-ts/README.md).
Hostr consumes those contracts; this research does not define a second protocol.

## Network Support Snapshot

Sweep date: 2026-05-25.

Discovery sources:

- NIP-87 Cashu mint announcements, `kind:38172`.
- NIP-87 mint recommendations, `kind:38000` with `k=38172`.
- NIP-60 Cashu wallet mint lists, `kind:10019`.
- Cashu.Live public mint status table.
- Live mint capability checks via `GET /v1/info`.

The sweep found 125 candidate mint URLs. Of those, 65 returned live mint info.
For the "mainnet-ish" subset, obvious `test`, `fake`, and `signet` URLs were
excluded, leaving 58 live mints.

These numbers are a live reachability snapshot, not a claim about every Cashu
mint on the internet. Mints can disappear, change software, or change advertised
capabilities, so marketplace clients must preflight the selected mint at order
time.

## Escrow-Relevant NUT Support

Mainnet-ish reachable mint support:

| NUT | Capability | Support |
| --- | --- | ---: |
| NUT-04 | Minting from a payment quote | 57/58, 98.3% |
| NUT-05 | Melting to Lightning | 58/58, 100% |
| NUT-07 | Proof state checks | 58/58, 100% |
| NUT-09 | Restore signatures for known outputs | 58/58, 100% |
| NUT-10 | Spending conditions | 58/58, 100% |
| NUT-11 | Pay-to-Pubkey (P2PK) | 58/58, 100% |
| NUT-12 | DLEQ proofs | 58/58, 100% |
| NUT-14 | HTLC spending conditions | 55/58, 94.8% |
| NUT-15 | Partial multi-path payments | 24/58, 41.4% |
| NUT-17 | WebSocket subscriptions | 54/58, 93.1% |
| NUT-19 | Cached responses | 16/58, 27.6% |
| NUT-20 | Signature on mint quote | 57/58, 98.3% |

The important conclusion: every live mainnet-ish mint in the sweep advertised
the core mint-enforced P2PK escrow pieces: NUT-10 and NUT-11. Every one also
advertised NUT-07, NUT-09, and NUT-12, which are important for state recovery
and proof verification.

However, the full buyer-funded flow also needs NUT-04 so the buyer can pay a
Lightning invoice and mint directly into the selected mint. That was one mint
short of universal in the live mainnet-ish sample.

Additional NUT-19 spot check on 2026-05-27: Cashu.Live exposed 76 clearnet mint
URLs; 48 returned usable `/v1/info`; 12 advertised NUT-19 for `POST /v1/swap`.
Only seven of those advertised a one-week TTL, while five advertised a 60 second
TTL. Treat NUT-19 as a helpful retry optimization, not as the base settlement
recovery primitive.

## Driver Requirements

The research recommends these mint capabilities for NMDK Cashu escrow
funding. The linked driver documentation defines the checks currently enforced:

- NUT-04: buyer can fund the mint by paying a Lightning quote.
- NUT-07: driver can check escrow proofs are still unspent or detect settlement.
- NUT-09: participants can restore blind signatures for known settlement
  outputs if the party submitting a swap withholds or loses the mint response.
- NUT-10: mint supports spending-condition secrets.
- NUT-11: mint enforces P2PK locks, signatures, locktimes, and refund paths.
- NUT-12: driver can verify mint signatures with DLEQ proofs.

Useful but not required for basic P2PK escrow:

- NUT-17: subscribe to quote/proof state instead of polling.
- NUT-19: safer retries/cached responses. Do not depend on it for settlement
  liveness because public support is limited and some TTLs are very short.
- NUT-20: signed mint quotes for better funding evidence.
- NUT-14: not part of the preferred non-interactive escrow path. HTLC
  cross-reveal does not fit buyer-funded, non-interactive reservation funding
  unless the seller has already supplied suitable preimage commitments.
- NUT-15: helpful for large or split Lightning payments, not needed for the
  base escrow lock mechanics.

## Direct Mint Into Escrow

The buyer does not need to mint normal wallet proofs and then perform a second
swap into escrow. NUT-04 `POST /v1/mint/bolt11` accepts wallet-supplied
`BlindedMessage` outputs. The Cashu driver should construct those outputs
directly from escrow P2PK secrets, wait for the quote to become `PAID`, and ask
the mint to sign the final escrow outputs.

Preferred funding flow:

1. Buyer requests a NUT-04 BOLT11 quote for the total escrow amount.
2. Buyer builds escrow-sliced blinded outputs, for example ten 10% slices.
3. Each slice secret is a NUT-10/NUT-11 spending condition with the agreed
   buyer, seller, arbiter, locktime, and `SIG_ALL` rules.
4. Buyer pays the quote.
5. Buyer calls `POST /v1/mint/bolt11` with the escrow outputs.
6. Mint returns blind signatures; buyer unblinds them into funded escrow proofs.
7. The Payment event commits to those funded escrow proofs and settlement
   templates.

This keeps the funding transaction non-interactive while still producing proofs
that are already locked under marketplace escrow policy.

## Settlement and Restore

NUT-19 is not the main answer for Cashu escrow settlement. It only replays the
exact same request body and only while the mint keeps the cached response. The
preferred liveness primitive is NUT-09 restore.

NUT-09 works only if a participant can reproduce the exact `BlindedMessage`
outputs that the mint signed. Therefore every possible settlement output must be
derived from a deterministic settlement transcript, or its recovery material
must be encrypted to the recipient and included in the order/payment package.

The deterministic transcript should include at least:

- domain: `hostr-cashu-settlement-output-v1`;
- mint URL, unit, and keyset id;
- order group id and payment event id;
- component, for example `payment` or `securityDeposit`;
- split, for example `6-of-10-to-seller`;
- recipient role and recipient P2PK pubkey;
- slice indexes, output amount, and output index.

From that transcript the driver derives the Cashu secret, blinding factor, and
`BlindedMessage`. The secret itself must be a P2PK secret locked to the intended
recipient. If the derivation is public, anyone can reconstruct the output proofs
after settlement, but only the recipient can spend them because they are P2PK
locked. If that privacy leak is unacceptable, the same recovery material should
be encrypted to the recipient instead of being publicly derivable.

Seller and arbiter validation at funding time:

1. Verify the selected mint supports NUT-04, NUT-07, NUT-09, NUT-10, NUT-11,
   and NUT-12.
2. Verify funded escrow slice proofs against the mint keyset and DLEQ where
   available.
3. Verify slice amounts sum to the expected payment amount.
4. Verify each slice secret has the expected P2PK policy, locktime, and
   `SIG_ALL` semantics.
5. For every allowed split, recompute the deterministic settlement outputs and
   compare them with the declared swap template.
6. Verify all slices are consumed exactly once in each template.
7. Verify outputs are locked to the declared buyer, seller, and fee recipients.
8. Verify buyer pre-authorizations sign the exact `SIG_ALL` hash for the exact
   inputs and outputs.

Collaborative close uses the same output construction. Buyer and seller choose
a split, build the exact `SIG_ALL` swap over the escrow slices and deterministic
recipient outputs, and both sign it. If one party submits the swap and hides the
mint response, the other party restores their own signed outputs through
NUT-09, unblinds the returned signatures, and receives spendable P2PK-locked
proofs.

Arbiter close is the same idea with different authorization. The arbiter selects
one of the buyer-preauthorized split templates and signs it. If the arbiter
submits the swap and withholds the response, buyer and seller restore their own
outputs with NUT-09 as long as the settlement template used deterministic or
recipient-recoverable outputs.

## Payment Evidence and Privacy

The current canonical protocol puts payment evidence in a linked `kind:32123`
Payment event. The order itself expresses terms; it does not prove funding.
NMDK owns the generic `driver`, `terms`, and `params` model and the Cashu-specific
validation of that evidence.

The Cashu driver marks the complete proof as secret because its proofs and
pre-authorized swap packets contain bearer value. The marketplace runtime seals
that proof for authorized participants. Hostr must not publish raw Cashu proof
fields or implement a separate order-embedded proof format.

Authorized participants can verify mint issuance, spending policy, and proof
state through NMDK. Recovery follows the committed settlement outputs and the
NMDK operation store; private material remains protected during relay transport.

## Plebeian Auctions Comparison

The Plebeian Market Auctions source inspected during this research uses Cashu
for bid-backed auctions, but it does not place raw Cashu proofs directly on the
public bid event.

Its public bid commitment is kind `1023`. The event includes tags such as
`amount`, `mint`, `commitment`, `locktime`, `refund_pubkey`, `child_pubkey`,
`path_issuer`, and `status=locked`. The `commitment` is a SHA-256 hash of the
encoded Cashu token, so public observers can correlate the bid to a private
token later, but cannot inspect or spend the token from the bid event alone.

The actual locked Cashu token is serialized with `getEncodedToken({ mint,
proofs })` after the wallet swaps selected proofs into new NUT-11 P2PK proofs.
That encoded token is sent to the auction path issuer through
`submit_bid_token`, along with the bid event id, mint, amount, locktime, refund
pubkey, child lock pubkey, bid nonce, and commitment. The issuer validates that
the token decodes, sums to the expected amount, and every proof is P2PK-locked
to the granted child pubkey.

After validation, Plebeian stores the token in a kind `30410` path registry
entry under `lockPayload`. That registry event is NIP-44 encrypted to the path
issuer's own pubkey. Settlement later reads the winner's token from that
private registry entry and releases the corresponding derivation path to the
seller.

The researched Plebeian design separates public commitment metadata from the
bearer token in the private issuer registry. NMDK likewise protects Cashu bearer
material, while its canonical Payment event and driver interfaces define how
authorized marketplace participants receive and validate payment evidence.

## Practical Implications

Do not treat Cashu support as a marketplace-wide constant. Treat it as a
property of the seller-selected mint and unit.

Before a buyer locks funds:

1. Fetch `GET /v1/info` from the selected mint.
2. Verify the required NUTs above are present and not disabled.
3. Request a NUT-04 BOLT11 mint quote.
4. Have the buyer pay that quote.
5. Poll or subscribe until the quote is `PAID`.
6. Mint P2PK escrow outputs, not normal wallet outputs.
7. Publish or otherwise retain enough deterministic recovery metadata in the
   Payment package for participants to reconstruct their own settlement outputs
   and use NUT-09 restore. Local storage can cache this material, but recovery
   should not depend on the same device still existing.

## Local Hostr Stack

`compose.cashu.yaml` adds SAT and USD Nutshell mints plus Redis to Hostr's
local/test stack. The SAT mint uses Hostr's existing LND node; the USD mint uses
the canonical Cashu stack's development `FakeWallet` backend. USD amounts are
cents, and neither mint is intended for real funds.

Both environments enable the `tools` profile. `write-config` runs NMDK's
canonical config generator, and `stack-ready` runs its SAT/USD capability and
relay readiness check. `scripts/start.sh` waits for that check and propagates a
failure. This overlay does not start NMDK's standalone Bitcoin/LND initializer
services.

The reverse proxy exposes `https://mint.hostr.development` and
`https://mint-usd.hostr.development` with development CA certificates. Direct
mint endpoints default to ports 19338 and 19339. Generated config lives in the
`cashu-config-data` volume and advertises Hostr's existing Bitcoin/LND endpoints.
Its buyer/payer endpoint is Boltz `lnd-1`, already connected to Hostr's mint LND
by bootstrap, so paying a mint quote does not require an LND self-payment.

The standalone [NMDK Cashu stack](dependencies/nmdk/dependencies/marketplace-cashu-stack/README.md)
remains available for independent driver integration tests with its own LND and
relay services. Hostr reuses its config generator and readiness checker.

References:

- Cashu NUT specifications: https://cashubtc.github.io/nuts/
- NUT-06 mint info: https://cashubtc.github.io/nuts/06/
- NIP-87 mint discovery: https://nips.nostr.com/87
- Cashu.Live mint status: https://cashu.live/
