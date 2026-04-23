# Reservation Pubkey Proofs

Hostr reservations may use disposable trade pubkeys so public reservation events
do not reveal a buyer's durable identity. When a participant chooses to disclose
their durable pubkey to authorized parties, the reservation can carry encrypted
pubkey proof capsules.

## Tag

The tag is intentionally role-generic so future participant proofs can reuse the
same mechanism.

```json
["pubkey_proof", "<role>", "<recipient-pubkey>", "nip44-v1", "<ciphertext>"]
```

Current roles:

- `buyer`: proves the durable buyer pubkey for the reservation trade id.
- `seller`: reserved for a future durable seller proof.

For `buyer`, clients encrypt one capsule to the seller and one to the escrow
service when an escrow pubkey is known.

## Encryption

`nip44-v1` means the ciphertext is NIP-44 encrypted by the reservation event
author key to the recipient pubkey in the tag.

Recipients decrypt with:

- their own private key
- the reservation event `pubKey` as the sender pubkey
- the ciphertext from the tag addressed to their pubkey

This keeps the durable buyer pubkey out of public tags. The reservation author
is usually the disposable trade pubkey, so the durable buyer pubkey is only
revealed inside the encrypted payload.

## Payload

The decrypted plaintext is compact:

```text
v1:<durable-pubkey>:<schnorr-signature>
```

The signature is made by `<durable-pubkey>` over the trade id only. If the trade
id is a 32-byte hex string, that value is signed directly. Otherwise clients sign
`sha256(utf8(tradeId))`.

Verification:

1. Resolve the reservation trade id from the `d` tag.
2. Decrypt the capsule addressed to the local pubkey.
3. Parse `v1:<durable-pubkey>:<signature>`.
4. Verify the Schnorr signature against the trade id message.

Looking up the trade id gives the listing, seller, escrow, and public disposable
participant tags, so the proof does not duplicate that context.

## Trust Rules

- Do not trust a plaintext durable buyer pubkey tag.
- Do not trust a decrypted payload unless the signature verifies.
- Treat seller-authored copies of buyer proofs as hints unless policy later
  defines them as authoritative. Buyer-authored reservations are the authority
  for buyer disclosure.
- Unknown roles can be added without changing the tag shape.
