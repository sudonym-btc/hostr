const kNostrKindListing = 32121;
const kNostrKindReservation = 32122;
const kNostrKindReservationRequest = 32123;
const kNostrKindReview = 32124;
const kNostrKindEscrow = 40021;
const kNostrKindEscrowTrust = 30300;
const kNostrKindEscrowMethod = 30301;

const kNostrKindProfile = 0;
const kNostrKindDM = 14;
const kNostrKindReaction = 7;
const kNostrKindZapRequest = 9734;
const kNostrKindZapReceipt = 9735;
const kNostrKindConnect = 24133;

/// A seal is a kind:13 event that wraps a rumor with the sender's regular key. The seal is always encrypted to a receiver's pubkey but there is no p tag pointing to the receiver. There is no way to know who the rumor is for without the receiver's or the sender's private key. The only public information in this event is who is signing it.
const kNostrKindSeal = 13;

/// A gift wrap event is a kind:1059 event that wraps any other event. tags SHOULD include any information needed to route the event to its intended recipient, including the recipient's p tag
const kNostrKindGiftWrap = 1059;

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

const kReservationRefTag = "r";
const kThreadRefTag = "t";
const kListingRefTag = "l";
