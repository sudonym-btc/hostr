const kNostrKindListing = 32121;
const kNostrKindReservation = 32122;

const kNostrKindReview = 32124;

/// Reservation transitions are append-only audit events, so this kind must
/// stay outside NIP-16 replaceable ranges.
const kNostrKindReservationTransition = 1326;

/// Escrow service advertisement. Moved from 40021 (ephemeral range, not stored
/// by relays) to 30303 (parameterized replaceable) so relays persist it.
const kNostrKindEscrowService = 30303;
const kNostrKindEscrowTrust = 30300;
const kNostrKindEscrowMethod = 30301;
const kNostrKindEscrowServiceSelected = 30302;

const kNostrKindProfile = 0;
const kNostrKindDM = 14;
const kNostrKindJsonMessage = 1327;
const kNostrKindSeenStatus = 16;
const kNostrKindReaction = 7;
const kNostrKindZapRequest = 9734;
const kNostrKindZapReceipt = 9735;
const kNostrKindConnect = 24133;

/// A seal is a kind:13 event that wraps a rumor with the sender's regular key. The seal is always encrypted to a receiver's pubkey but there is no p tag pointing to the receiver. There is no way to know who the rumor is for without the receiver's or the sender's private key. The only public information in this event is who is signing it.
const kNostrKindSeal = 13;

/// A gift wrap event is a kind:1059 event that wraps any other event. tags SHOULD include any information needed to route the event to its intended recipient, including the recipient's p tag
const kNostrKindGiftWrap = 1059;

/// NIP-17 preferred relays for receiving direct messages.
const kNostrKindDmRelays = 10050;

const kNostrKindReceivedHeartbeat = 10017;
const kNostrKindTypingIndicator = 10018;
const kNostrKindSeenMessages = 30010;

const kNostrKindNWCInfo = 13194;
const kNostrKindNWCRequest = 23194;
const kNostrKindNWCResponse = 23195;
const kNostrKindNWCNotification = 23196;

/// NIP-58 Badge events
/// Kind 8: Badge Award - awards a badge to one or more pubkeys
const kNostrKindBadgeAward = 8;

/// Kind 30009: Badge Definition - defines a badge with metadata (replaceable)
const kNostrKindBadgeDefinition = 30009;

/// Kind 30008: Profile Badges - user's chosen badges to display (replaceable)
const kNostrKindProfileBadges = 30008;

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
  kNostrKindReservationTransition,
  kNostrKindEscrowService,
  kNostrKindEscrowTrust,
  kNostrKindEscrowMethod,
  kNostrKindEscrowServiceSelected,
  kNostrKindJsonMessage,
  kNostrKindSeal,
  kNostrKindReceivedHeartbeat,
  kNostrKindTypingIndicator,
  kNostrKindSeenMessages,
  // NIP-58 badge events are hostr-specific (host reputation, listing badges)
  // and must not leak to external relays.
  kNostrKindBadgeAward,
  kNostrKindBadgeDefinition,
  kNostrKindProfileBadges,
};

const kReservationRefTag = "r";
const kThreadRefTag = "t";
const kListingRefTag = "l";
const kConversationTag = "conversation";
