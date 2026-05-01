/// Hostr listing, custom addressable event using NIP-01 kind ranges:
/// https://nips.nostr.com/01
const kNostrKindListing = 32121;

/// Hostr reservation, custom addressable event using NIP-01 kind ranges:
/// https://nips.nostr.com/01
const kNostrKindReservation = 32122;

/// Hostr review, custom addressable event using NIP-01 kind ranges:
/// https://nips.nostr.com/01
const kNostrKindReview = 32124;

/// Hostr commit authorization, regular custom event per NIP-01:
/// https://nips.nostr.com/01
const kNostrKindCommitAuthorization = 1328;

/// Hostr trade-key authorization, regular custom event per NIP-01:
/// https://nips.nostr.com/01
const kNostrKindTradeKeyAuthorization = 1329;

/// Hostr account seed backup, replaceable custom event per NIP-01:
/// https://nips.nostr.com/01
const kNostrKindHostrSeed = 17389;

/// Reservation transitions are append-only audit events, so this kind must
/// stay outside NIP-01 replaceable ranges:
/// https://nips.nostr.com/01
const kNostrKindReservationTransition = 1326;

/// Escrow service advertisement. Moved from 40021 (ephemeral range, not stored
/// by relays) to 30303 (parameterized replaceable) so relays persist it.
/// Range semantics come from NIP-01:
/// https://nips.nostr.com/01
const kNostrKindEscrowService = 30303;

/// Escrow payment method is one replaceable event per pubkey per NIP-01:
/// https://nips.nostr.com/01
const kNostrKindEscrowMethod = 17388;

/// Escrow service selection is addressable per trade via NIP-01 ranges:
/// https://nips.nostr.com/01
const kNostrKindEscrowServiceSelected = 30302;

/// User metadata, defined by NIP-01:
/// https://nips.nostr.com/01
const kNostrKindProfile = 0;

/// External identity claims, defined by NIP-39:
/// https://nips.nostr.com/39
const kNostrKindIdentityClaims = 10011;

/// Legacy encrypted direct message, defined by NIP-04:
/// https://nips.nostr.com/04
const kNostrKindLegacyDM = 4;

/// Private direct message rumor, defined by NIP-17:
/// https://nips.nostr.com/17
const kNostrKindDM = 14;

/// Hostr custom JSON message rumor; regular custom event per NIP-01:
/// https://nips.nostr.com/01
const kNostrKindJsonMessage = 1327;

/// Hostr read receipt rumor; regular custom event per NIP-01:
/// https://nips.nostr.com/01
const kNostrKindSeenStatus = 16;

/// Reaction, defined by NIP-25:
/// https://nips.nostr.com/25
const kNostrKindReaction = 7;

/// Zap request, defined by NIP-57:
/// https://nips.nostr.com/57
const kNostrKindZapRequest = 9734;

/// Zap receipt, defined by NIP-57:
/// https://nips.nostr.com/57
const kNostrKindZapReceipt = 9735;

/// Nostr Connect request/response, defined by NIP-46:
/// https://nips.nostr.com/46
const kNostrKindConnect = 24133;

/// Seal, defined by NIP-59:
/// https://nips.nostr.com/59
const kNostrKindSeal = 13;

/// Gift wrap, defined by NIP-59:
/// https://nips.nostr.com/59
const kNostrKindGiftWrap = 1059;

/// NIP-17 preferred relays for receiving direct messages, listed in NIP-51:
/// https://nips.nostr.com/51
const kNostrKindDmRelays = 10050;

/// Mark-as-received heartbeat discussion:
/// https://github.com/nostr-protocol/nips/pull/2000
const kNostrKindReceivedHeartbeat = 10017;

/// Typing indicators are not enabled. If revived, use an ephemeral event kind
/// from NIP-01's 20000-29999 range:
/// https://nips.nostr.com/01
// const kNostrKindTypingIndicator = 10018;

/// Unused bloom-filter seen-message proposal from the read-receipt discussion:
/// https://github.com/nostr-protocol/nips/pull/1761
const kNostrKindSeenMessages = 30010;

/// Nostr Wallet Connect info event, defined by NIP-47:
/// https://nips.nostr.com/47
const kNostrKindNWCInfo = 13194;

/// Nostr Wallet Connect request, defined by NIP-47:
/// https://nips.nostr.com/47
const kNostrKindNWCRequest = 23194;

/// Nostr Wallet Connect response, defined by NIP-47:
/// https://nips.nostr.com/47
const kNostrKindNWCResponse = 23195;

/// Legacy Nostr Wallet Connect notification kind; NIP-47 now specifies 23197
/// and keeps 23196 for backwards compatibility:
/// https://nips.nostr.com/47
const kNostrKindNWCNotification = 23196;

/// Badge Award, defined by NIP-58:
/// https://nips.nostr.com/58
const kNostrKindBadgeAward = 8;

/// Badge Definition, defined by NIP-58:
/// https://nips.nostr.com/58
const kNostrKindBadgeDefinition = 30009;

/// Profile Badges, defined by NIP-58:
/// https://nips.nostr.com/58
const kNostrKindProfileBadges = 10008;

/// Event kinds that are specific to the hostr application and must NEVER be
/// broadcast to external relays. The [Requests.broadcast] guard uses this set
/// to force these events onto the hostr relay only.
///
/// Gift wraps are intentionally excluded. Their contents are encrypted and the
/// outer `1059` event is standard NIP-59, so callers may route them to external
/// recipient relays while keeping Hostr-specific inner events hidden.
const kHostrOnlyKinds = <int>{
  kNostrKindSeenStatus,
  kNostrKindListing,
  kNostrKindReservation,
  kNostrKindReview,
  kNostrKindCommitAuthorization,
  kNostrKindTradeKeyAuthorization,
  kNostrKindHostrSeed,
  kNostrKindReservationTransition,
  kNostrKindEscrowService,
  kNostrKindEscrowMethod,
  kNostrKindEscrowServiceSelected,
  kNostrKindIdentityClaims,
  kNostrKindJsonMessage,
  kNostrKindSeal,
  kNostrKindReceivedHeartbeat,
  kNostrKindSeenMessages,
  // Hostr-issued badge awards/definitions carry host reputation/listing data
  // and must not leak to external relays.
  kNostrKindBadgeAward,
  kNostrKindBadgeDefinition,
};

const kReservationRefTag = "r";
const kThreadRefTag = "t";
const kListingRefTag = "l";
const kConversationTag = "conversation";
