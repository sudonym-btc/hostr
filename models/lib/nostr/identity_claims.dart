import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';

class IdentityClaims extends Event {
  static const List<int> kinds = [kNostrKindIdentityClaims];
  static const String evmAddressClaimPrefix = 'evm:address:';
  static const String eip191ProofPrefix = 'eip191:';
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;

  IdentityClaims.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  factory IdentityClaims.build({
    required String pubKey,
    required String evmAddress,
    String? eip191Proof,
    Iterable<List<String>> tags = const [],
    int? createdAt,
  }) {
    final claimTags = withoutEvmAddressClaims(tags).toList()
      ..add(evmAddressTag(evmAddress, eip191Proof: eip191Proof));

    return IdentityClaims.fromNostrEvent(
      Nip01Event(
        pubKey: pubKey,
        kind: kNostrKindIdentityClaims,
        tags: claimTags,
        content: '',
        createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );
  }

  String? get evmAddress {
    final claim = _lastEvmAddressTag();
    if (claim == null) return null;
    return claim[1].substring(evmAddressClaimPrefix.length);
  }

  String? get evmAddressProof {
    final claim = _lastEvmAddressTag();
    if (claim == null || claim.length < 3) return null;
    final proof = claim[2];
    return proof.startsWith(eip191ProofPrefix)
        ? proof.substring(eip191ProofPrefix.length)
        : proof;
  }

  IdentityClaims withEvmAddress(String address, {String? eip191Proof}) {
    return IdentityClaims.build(
      pubKey: pubKey,
      evmAddress: address,
      eip191Proof: eip191Proof,
      tags: tags,
    );
  }

  static List<String> evmAddressTag(String address, {String? eip191Proof}) {
    return [
      'i',
      '$evmAddressClaimPrefix$address',
      if (eip191Proof != null && eip191Proof.isNotEmpty)
        '$eip191ProofPrefix$eip191Proof',
    ];
  }

  static bool isEvmAddressTag(List<String> tag) {
    return tag.length >= 2 &&
        tag[0] == 'i' &&
        tag[1].startsWith(evmAddressClaimPrefix);
  }

  static Iterable<List<String>> withoutEvmAddressClaims(
    Iterable<List<String>> tags,
  ) {
    return tags.where((tag) => !isEvmAddressTag(tag));
  }

  List<String>? _lastEvmAddressTag() {
    List<String>? latest;
    for (final tag in tags) {
      if (isEvmAddressTag(tag)) latest = tag;
    }
    return latest;
  }
}
