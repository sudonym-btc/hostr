const NOSTR_KIND_LISTING = 32121;
const NOSTR_KIND_RESERVATION = 32122;
const NOSTR_KIND_RESERVATION_REQUEST = 32123;
const NOSTR_KIND_REVIEW = 32124;

const NOSTR_KIND_ZAP_REQUEST = 9734;
const NOSTR_KIND_ZAP_RECEIPT = 9735;
const NOSTR_KIND_CONNECT = 24133;
const NOSTR_KIND_ESCROW = 40021;
const NOSTR_KIND_ESCROW_TRUST = 30300;
const NOSTR_KIND_ESCROW_METHOD = 30301;
const NOSTR_KIND_PROFILE = 0;
const NOSTR_KIND_DM = 14;
const NOSTR_KIND_REACTION = 7;

/// A seal is a kind:13 event that wraps a rumor with the sender's regular key. The seal is always encrypted to a receiver's pubkey but there is no p tag pointing to the receiver. There is no way to know who the rumor is for without the receiver's or the sender's private key. The only public information in this event is who is signing it.
const NOSTR_KIND_SEAL = 13;

/// A gift wrap event is a kind:1059 event that wraps any other event. tags SHOULD include any information needed to route the event to its intended recipient, including the recipient's p tag
const NOSTR_KIND_GIFT_WRAP = 1059;

const NOSTR_KIND_NWC_INFO = 13194;
const NOSTR_KIND_NWC_REQUEST = 23194;
const NOSTR_KIND_NWC_RESPONSE = 23195;
const NOSTR_KIND_NWC_NOTIFICATION = 23196;

/// NIP-58 Badge events
/// Kind 8: Badge Award - awards a badge to one or more pubkeys
const NOSTR_KIND_BADGE_AWARD = 8;

/// Kind 30009: Badge Definition - defines a badge with metadata (replaceable)
const NOSTR_KIND_BADGE_DEFINITION = 30009;

/// Kind 30008: Profile Badges - user's chosen badges to display (replaceable)
const NOSTR_KIND_PROFILE_BADGES = 30008;

const RESERVATION_REFERENCE_TAG = "r";
const THREAD_REFERENCE_TAG = "t";
const LISTING_REFERENCE_TAG = "l";
