import 'dart:core';

import '../nostr_kinds.dart';
import 'event.dart';

/// NIP-58 Badge Award (kind 8)
/// Awards a badge to one or more pubkeys
/// Must reference a badge definition via 'a' tag and recipients via 'p' tags
/// Awards are immutable and non-transferable per NIP-58
class BadgeAward extends Event {
  static const List<int> kinds = [NOSTR_KIND_BADGE_AWARD];

  BadgeAward.fromNostrEvent(super.e);

  /// Get the badge definition anchor (kind:pubkey:d)
  String? get badgeDefinitionAnchor => nip01Event.getFirstTag('a');

  /// Get all recipient pubkeys
  List<String> get recipients => nip01Event.pTags;

  /// Get target anchor (for listing-bound badges)
  String? get targetAnchor {
    final aTags = nip01Event.tags
        .where((tag) => tag.isNotEmpty && tag[0] == 'a')
        .toList();
    // First 'a' tag is the badge definition, subsequent ones are targets
    return aTags.length > 1 && aTags[1].length > 1 ? aTags[1][1] : null;
  }
}
