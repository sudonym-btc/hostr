import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import '../stubs/keypairs.dart';

/// A denomination → concrete token mapping declared via an `"a"` tag on an
/// [EscrowMethod] event (kind 30301).
///
/// Tag wire format: `["a", "<denomination>", "<tokenTagId>"]`
///
/// Example:
/// ```
/// ["a", "BTC", "30:0x0000000000000000000000000000000000000000"]  // native RBTC
/// ["a", "USD", "30:0xdAC17F958D2ee523a2206206994597C13D831ec7"]  // USDT on RSK
/// ```
///
/// See `PRICING.md` Layer 2 for the full specification.
class AcceptedPaymentForm {
  /// Unit-of-account identifier, e.g. `"BTC"`, `"USD"`.
  final String denomination;

  /// The concrete token's `Token.tagId`, e.g. `"BTC"` (Lightning),
  /// `"30:0x000…000"` (native RBTC), or `"30:0xdAC17…"` (ERC-20).
  final String tokenTagId;

  const AcceptedPaymentForm({
    required this.denomination,
    required this.tokenTagId,
  });

  /// Serialize to a 3-element Nostr tag.
  List<String> toTag() => ['a', denomination, tokenTagId];

  /// Parse from a raw Nostr tag (must have ≥ 3 elements with `tag[0] == 'a'`).
  static AcceptedPaymentForm? fromTag(List<String> tag) {
    if (tag.length < 3 || tag[0] != 'a') return null;
    return AcceptedPaymentForm(denomination: tag[1], tokenTagId: tag[2]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcceptedPaymentForm &&
          denomination == other.denomination &&
          tokenTagId == other.tokenTagId;

  @override
  int get hashCode => denomination.hashCode ^ tokenTagId.hashCode;

  @override
  String toString() => 'AcceptedPaymentForm($denomination, $tokenTagId)';
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

  /// All accepted payment forms declared via `"a"` tags on this event.
  List<AcceptedPaymentForm> get acceptedPaymentForms {
    return tags
        .where((t) => t.length >= 3 && t[0] == 'a')
        .map((t) => AcceptedPaymentForm(denomination: t[1], tokenTagId: t[2]))
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
    return acceptedPaymentForms.any(
      (f) => f.denomination == denomination && f.tokenTagId == tokenTagId,
    );
  }
}
