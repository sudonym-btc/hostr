export const Decision = Object.freeze({
  UNSPECIFIED: 0,
  PERMIT: 1,
  DENY: 2,
});

export const DEFAULT_AUTHOR_MISMATCH_KINDS = Object.freeze([
  1059, // NIP-59 gift wrap: signed by an ephemeral wrapper key.
  32122, // Hostr order: may be signed by a per-trade participant key.
  1326, // Hostr order transition: follows the order signer key.
]);

export const DEFAULT_ALLOWED_KINDS = Object.freeze([
  0, // NIP-01 profile metadata.
  4, // NIP-04 legacy encrypted DM, still used by escrow compatibility paths.
  5, // NIP-09 delete event.
  7, // NIP-25 reaction, used inside NIP-17 private chats.
  8, // NIP-58 badge award.
  13, // NIP-59 seal.
  14, // NIP-17 private DM rumor.
  16, // Hostr read receipt rumor.
  1059, // NIP-59 gift wrap.
  1326, // Hostr order transition.
  1327, // Hostr custom JSON message rumor.
  1328, // Hostr commit authorization.
  1329, // Hostr trade-key authorization.
  9734, // NIP-57 zap request.
  9735, // NIP-57 zap receipt.
  10008, // NIP-58 profile badges.
  10011, // NIP-39 external identity claims.
  10017, // Hostr received heartbeat.
  10050, // NIP-51/NIP-17 DM relay list.
  13194, // NIP-47 NWC info event.
  17388, // Hostr escrow payment method.
  17389, // Hostr account seed backup.
  22242, // NIP-42 relay authentication event.
  23194, // NIP-47 NWC request.
  23195, // NIP-47 NWC response.
  23196, // NIP-47 legacy NWC notification.
  23197, // NIP-47 current NWC notification.
  24133, // NIP-46 Nostr Connect.
  30009, // NIP-58 badge definition.
  30010, // Hostr seen-message bloom filter proposal.
  30302, // Hostr escrow service selection.
  30303, // Hostr escrow service advertisement.
  30402, // NIP-99 Hostr accommodation listing.
  31555, // Marketplace product review.
  32122, // Hostr order.
]);

export const DEFAULT_AUTH_OPTIONAL_KINDS = Object.freeze([
  24133, // NIP-46 Nostr Connect: bootstrap traffic before a Hostr session exists.
  13194, // NIP-47 NWC info: wallet services publish this before app auth exists.
  23194, // NIP-47 NWC request: ephemeral per-connection wallet traffic.
  23195, // NIP-47 NWC response.
  23196, // NIP-47 legacy NWC notification.
  23197, // NIP-47 current NWC notification.
]);

export function decideEventAdmission(request, options = {}) {
  const requireAuthorMatch = options.requireAuthorMatch ?? true;
  const allowedKinds = options.allowedKinds ?? DEFAULT_ALLOWED_KINDS;
  const authorMismatchKinds =
    options.authorMismatchKinds ?? DEFAULT_AUTHOR_MISMATCH_KINDS;
  const authOptionalKinds =
    options.authOptionalKinds ?? DEFAULT_AUTH_OPTIONAL_KINDS;
  const event = request?.event;
  if (!event) {
    return deny('missing event');
  }

  if (!kindInList(event.kind, allowedKinds)) {
    return deny(`unsupported-kind: event kind ${event.kind} is not allowed`);
  }

  const authPubkey = normalizeHex(request.authPubkey ?? request.auth_pubkey);
  if (!authPubkey) {
    if (kindInList(event.kind, authOptionalKinds)) {
      return permit();
    }
    return deny('auth-required: NIP-42 authentication required');
  }

  if (
    requireAuthorMatch &&
    !kindInList(event.kind, authOptionalKinds) &&
    !kindInList(event.kind, authorMismatchKinds)
  ) {
    const eventPubkey = normalizeHex(event.pubkey);
    if (!eventPubkey) {
      return deny('event pubkey is missing');
    }
    if (authPubkey !== eventPubkey) {
      return deny(
        'auth-required: NIP-42 authenticated pubkey must match event author',
      );
    }
  }

  return permit();
}

export function normalizeHex(value) {
  if (value == null) return '';
  if (typeof value === 'string') return value.toLowerCase();
  if (Buffer.isBuffer(value)) return value.toString('hex').toLowerCase();
  if (value instanceof Uint8Array) {
    return Buffer.from(value).toString('hex').toLowerCase();
  }
  return '';
}

export function kindAllowsAuthorMismatch(kind, kinds) {
  return kindInList(kind, kinds);
}

export function kindInList(kind, kinds) {
  const numericKind = Number(kind);
  if (!Number.isFinite(numericKind)) return false;
  if (kinds instanceof Set) return kinds.has(numericKind);
  return kinds.includes(numericKind);
}

function permit() {
  return { decision: Decision.PERMIT };
}

function deny(message) {
  return { decision: Decision.DENY, message };
}
