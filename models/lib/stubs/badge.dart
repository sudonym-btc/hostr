import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

/// Mock badge definitions for testing
final MOCK_BADGE_DEFINITIONS = [
  BadgeDefinition.fromNostrEvent(Nip01Event(
    pubKey: MockKeys.escrow.publicKey,
    content: json.encode({
      'name': 'Verified Host',
      'description': 'This host has been verified by the Hostr team',
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Twitter_Verified_Badge.svg/1200px-Twitter_Verified_Badge.svg.png',
    }),
    createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
    kind: NOSTR_KIND_BADGE_DEFINITION,
    tags: [
      ['d', 'verified-host'],
    ],
  )..sign(MockKeys.escrow.privateKey!)),
  BadgeDefinition.fromNostrEvent(Nip01Event(
    pubKey: MockKeys.escrow.publicKey,
    content: json.encode({
      'name': 'Top Rated',
      'description': 'This listing has consistently excellent reviews',
      'image': 'https://cdn-icons-png.flaticon.com/512/1828/1828970.png',
    }),
    createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
    kind: NOSTR_KIND_BADGE_DEFINITION,
    tags: [
      ['d', 'top-rated'],
    ],
  )..sign(MockKeys.escrow.privateKey!)),
  BadgeDefinition.fromNostrEvent(Nip01Event(
    pubKey: MockKeys.escrow.publicKey,
    content: json.encode({
      'name': 'Eco-Friendly',
      'description': 'This property follows sustainable practices',
    }),
    createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
    kind: NOSTR_KIND_BADGE_DEFINITION,
    tags: [
      ['d', 'eco-friendly'],
    ],
  )..sign(MockKeys.escrow.privateKey!)),
].toList();

/// Mock badge awards for testing
/// Awards the "Verified" badge to all mock listings (1 and 2)
final MOCK_BADGE_AWARDS = [
  // Listing 1 - Verified badge
  BadgeAward.fromNostrEvent(Nip01Event(
    pubKey: MockKeys.escrow.publicKey,
    content: '',
    createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
    kind: NOSTR_KIND_BADGE_AWARD,
    tags: [
      [
        'a',
        '$NOSTR_KIND_BADGE_DEFINITION:${MockKeys.escrow.publicKey}:verified-host'
      ],
      ['a', MOCK_LISTINGS[0].anchor],
      ['p', MockKeys.hoster.publicKey],
    ],
  )..sign(MockKeys.escrow.privateKey!)),
  // Listing 2 - Verified badge
  BadgeAward.fromNostrEvent(Nip01Event(
    pubKey: MockKeys.escrow.publicKey,
    content: '',
    createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
    kind: NOSTR_KIND_BADGE_AWARD,
    tags: [
      [
        'a',
        '$NOSTR_KIND_BADGE_DEFINITION:${MockKeys.escrow.publicKey}:verified-host'
      ],
      ['a', MOCK_LISTINGS[0].anchor],
      ['p', MockKeys.hoster.publicKey],
    ],
  )..sign(MockKeys.escrow.privateKey!)),
].toList();
