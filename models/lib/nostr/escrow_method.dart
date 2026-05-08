import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import '../stubs/keypairs.dart';

const kAcceptedPaymentFormTag = 'o';

/// A denomination → concrete token mapping declared via an `"o"` tag on an
/// [EscrowMethod] event.
///
/// Tag wire format: `["o", "<denomination>", "<tokenTagId>"]`
///
/// Example:
/// ```
/// ["o", "BTC", "30:0x0000000000000000000000000000000000000000"]  // native RBTC
/// ["o", "USD", "30:0xdAC17F958D2ee523a2206206994597C13D831ec7"]  // USDT on RSK
/// ```
///
/// See `PRICING.md` Layer 2 for the full specification.
class AcceptedPaymentForm {
  /// Unit-of-account identifier, e.g. `"BTC"`, `"USD"`.
  final String denomination;

  /// The concrete token's `Token.tagId`, e.g. `"BTC"` (Lightning),
  /// `"30:0x000…000"` (native RBTC), or `"30:0xdAC17…"` (ERC-20).
  final String tokenTagId;

  /// Optional application identifier used to scope payment forms so that
  /// [EscrowMethods.ensureEscrowMethod] can replace all forms belonging to
  /// a given app atomically instead of only appending.
  ///
  /// Wire format: `["o", "<denomination>", "<tokenTagId>", "<appId>"]`
  /// The 4th element is omitted when no application scope is needed.
  final String? appId;

  const AcceptedPaymentForm({
    required this.denomination,
    required this.tokenTagId,
    this.appId,
  });

  static String canonicalTokenTagId(String tokenTagId) {
    final separator = tokenTagId.indexOf(':');
    if (separator == -1) return tokenTagId;

    final chainId = tokenTagId.substring(0, separator);
    final address = tokenTagId.substring(separator + 1);
    if (address.startsWith('0x') || address.startsWith('0X')) {
      return '$chainId:${address.toLowerCase()}';
    }
    return tokenTagId;
  }

  /// Serialize to a Nostr tag (3 or 4 elements depending on [appId]).
  List<String> toTag() => [
        kAcceptedPaymentFormTag,
        denomination,
        tokenTagId,
        if (appId != null) appId!,
      ];

  /// Parse from a raw Nostr tag (must have ≥ 3 elements with payment-form tag).
  static AcceptedPaymentForm? fromTag(List<String> tag) {
    if (tag.length < 3 || tag[0] != kAcceptedPaymentFormTag) return null;
    return AcceptedPaymentForm(
      denomination: tag[1],
      tokenTagId: tag[2],
      appId: tag.length >= 4 ? tag[3] : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcceptedPaymentForm &&
          denomination == other.denomination &&
          canonicalTokenTagId(tokenTagId) ==
              canonicalTokenTagId(other.tokenTagId) &&
          appId == other.appId;

  @override
  int get hashCode =>
      Object.hash(denomination, canonicalTokenTagId(tokenTagId), appId);

  @override
  String toString() =>
      'AcceptedPaymentForm($denomination, $tokenTagId${appId != null ? ', $appId' : ''})';
}

class EscrowMethod extends Event {
  static const List<int> kinds = [kNostrKindEscrowMethod];
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;

  EscrowMethod.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  Future<Nip51List> toNip51List() async {
    return Nip51List.fromEvent(
        this,
        Bip340EventSigner(
            privateKey: MockKeys.escrow.privateKey,
            publicKey: MockKeys.escrow.publicKey));
  }

  // ── Accepted payment form helpers ───────────────────────────────────

  /// All trusted escrow arbiter pubkeys declared via `"p"` tags.
  List<String> get trustedEscrowPubkeys => getTags('p');

  /// All contract bytecode hashes declared via `"c"` tags.
  List<String> get supportedContractBytecodeHashes => getTags('c');

  /// All accepted payment forms declared via `"o"` tags on this event.
  List<AcceptedPaymentForm> get acceptedPaymentForms {
    return tags
        .where((t) => t.length >= 3 && t[0] == kAcceptedPaymentFormTag)
        .map((t) => AcceptedPaymentForm.fromTag(t)!)
        .toList();
  }

  /// Token tag IDs accepted for a specific [denomination] (e.g. `"BTC"`).
  List<String> acceptedTokensFor(String denomination) {
    return acceptedPaymentForms
        .where((f) => f.denomination == denomination)
        .map((f) => f.tokenTagId)
        .toList();
  }

  /// Whether this escrow method declares trust in [pubkey] as an arbiter.
  bool trustsEscrow(String pubkey) => trustedEscrowPubkeys.contains(pubkey);

  /// Whether this escrow method declares support for [bytecodeHash].
  bool supportsContractBytecodeHash(String bytecodeHash) =>
      supportedContractBytecodeHashes.contains(bytecodeHash);

  /// Whether this escrow method declares acceptance of [tokenTagId] for
  /// the given [denomination].
  bool acceptsToken(String denomination, String tokenTagId) {
    final canonicalTokenTagId =
        AcceptedPaymentForm.canonicalTokenTagId(tokenTagId);
    return acceptedPaymentForms.any(
      (f) =>
          f.denomination == denomination &&
          AcceptedPaymentForm.canonicalTokenTagId(f.tokenTagId) ==
              canonicalTokenTagId,
    );
  }
}
