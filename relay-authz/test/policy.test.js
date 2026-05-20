import assert from 'node:assert/strict';
import test from 'node:test';

import { Decision, decideEventAdmission } from '../src/policy.js';

const pubkey =
  'c062cfc7a20158a7ee5c7dc556af8b3849c09454a24c3b9975390aadb7d2db31';
const otherPubkey =
  '1c2cf8e8877b6b0e4de79c5e280119eca801868726d6428f9eadb5b034d1d95d';

function event(overrides = {}) {
  return {
    id: Buffer.alloc(32, 1),
    pubkey: Buffer.from(pubkey, 'hex'),
    createdAt: 1,
    kind: 1,
    content: '',
    tags: [],
    sig: Buffer.alloc(64, 2),
    ...overrides,
  };
}

test('denies writes without NIP-42 auth pubkey', () => {
  const decision = decideEventAdmission({ event: event({ kind: 30402 }) });

  assert.equal(decision.decision, Decision.DENY);
  assert.equal(decision.message, 'auth-required: NIP-42 authentication required');
});

test('permits writes when auth pubkey matches event author', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 30402 }),
    authPubkey: Buffer.from(pubkey, 'hex'),
  });

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('denies writes when auth pubkey does not match event author', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 30402 }),
    authPubkey: Buffer.from(otherPubkey, 'hex'),
  });

  assert.equal(decision.decision, Decision.DENY);
  assert.match(decision.message, /must match event author/);
});

test('denies event kinds not needed by Hostr even when authenticated', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 20001 }),
    authPubkey: Buffer.from(pubkey, 'hex'),
  });

  assert.equal(decision.decision, Decision.DENY);
  assert.match(decision.message, /unsupported-kind/);
});

test('can be configured to allow an additional event kind', () => {
  const decision = decideEventAdmission(
    {
      event: event(),
      authPubkey: Buffer.from(pubkey, 'hex'),
    },
    { allowedKinds: [1] },
  );

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('permits NIP-59 gift wraps from ephemeral author pubkeys when authenticated', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 1059 }),
    authPubkey: Buffer.from(otherPubkey, 'hex'),
  });

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('permits order events from per-trade participant keys when authenticated', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 32122 }),
    authPubkey: Buffer.from(otherPubkey, 'hex'),
  });

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('permits order transition events from per-trade participant keys when authenticated', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 1326 }),
    authPubkey: Buffer.from(otherPubkey, 'hex'),
  });

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('permits NIP-46 Nostr Connect envelopes without authentication', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 24133 }),
  });

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('permits NIP-46 Nostr Connect envelopes with a mismatched authenticated pubkey', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 24133 }),
    authPubkey: Buffer.from(otherPubkey, 'hex'),
  });

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('permits ephemeral NWC request and notification envelopes without authentication', () => {
  for (const kind of [23194, 23195, 23196, 23197]) {
    const decision = decideEventAdmission({
      event: event({ kind }),
    });

    assert.deepEqual(decision, { decision: Decision.PERMIT });
  }
});

test('permits NWC info events without authentication', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 13194 }),
  });

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('still denies NIP-59 gift wraps without authentication', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 1059 }),
  });

  assert.equal(decision.decision, Decision.DENY);
  assert.match(decision.message, /NIP-42 authentication required/);
});

test('can be configured to require auth without author matching', () => {
  const decision = decideEventAdmission(
    {
      event: event({ kind: 30402 }),
      authPubkey: Buffer.from(otherPubkey, 'hex'),
    },
    { requireAuthorMatch: false },
  );

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});

test('accepts snake_case auth_pubkey from alternate proto loader settings', () => {
  const decision = decideEventAdmission({
    event: event({ kind: 30402 }),
    auth_pubkey: Buffer.from(pubkey, 'hex'),
  });

  assert.deepEqual(decision, { decision: Decision.PERMIT });
});
