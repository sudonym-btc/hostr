import 'dart:math';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../seed_context.dart';
import '../seed_pipeline_models.dart';

// ─── Badge catalogue ──────────────────────────────────────────────────────

/// Definitions seeded into every environment.
///
/// Each entry: (identifier, name, description).
const _kBadgeCatalogue = [
  (
    'verified',
    'Verified Host',
    'Identity and property ownership verified by the Hostr team.',
  ),
  (
    'superhost',
    'Superhost',
    'Consistently outstanding reviews and a 4.9+ average rating.',
  ),
  (
    'eco_friendly',
    'Eco-Friendly',
    'Property uses renewable energy, recycling, and sustainable practices.',
  ),
  (
    'instant_book',
    'Instant Book',
    'Reservations are confirmed automatically without host approval.',
  ),
  (
    'long_stay_friendly',
    'Long-Stay Friendly',
    'Optimised for month-plus stays with discounted weekly and monthly rates.',
  ),
];

// ─── Deterministic RNG namespace ─────────────────────────────────────────────

/// Returns a per-badge [Random] seeded well away from other pipeline
/// namespaces (listings ≈ seed * 10_000, reviews ≈ seed * 10_000 + 200_000).
Random _badgeRng(int seed) => Random(seed * 10000 + 500000);

// ─── Public stage entry-point ─────────────────────────────────────────────────

class BadgeSeedData {
  final List<BadgeDefinition> definitions;
  final List<BadgeAward> awards;

  const BadgeSeedData({required this.definitions, required this.awards});
}

/// Stage: build badge definitions (published by the escrow/operator key) and
/// badge awards for ~half of the listings and ~half of the hosts.
///
/// Badge definitions are keyed to a stable author so they can be safely
/// re-seeded without creating duplicates.
BadgeSeedData buildBadges({
  required SeedContext ctx,
  required KeyPair issuerKey,
  required List<SeedUser> hosts,
  required List<Listing> listings,
}) {
  final rng = _badgeRng(ctx.seed);

  // ── 1. Build definitions ────────────────────────────────────────────────

  final definitions = <BadgeDefinition>[];
  final anchorByIdentifier = <String, String>{};

  for (final (identifier, name, description) in _kBadgeCatalogue) {
    final def = _buildDefinition(
      issuerKey: issuerKey,
      identifier: identifier,
      name: name,
      description: description,
      createdAt: ctx.timestampDaysAfter(1),
    );
    definitions.add(def);
    anchorByIdentifier[identifier] = def.anchor;
  }

  // ── 2. Award badges ─────────────────────────────────────────────────────

  final awards = <BadgeAward>[];

  // Give 'verified' to ~half the hosts (by pubkey, no listing anchor).
  final verifiedAnchor = anchorByIdentifier['verified']!;
  for (final host in hosts) {
    if (rng.nextDouble() < 0.5) {
      awards.add(
        _buildAward(
          issuerKey: issuerKey,
          definitionAnchor: verifiedAnchor,
          recipientPubkey: host.keyPair.publicKey,
          listingAnchor: null,
          createdAt: ctx.timestampDaysAfter(2),
        ),
      );
    }
  }

  // Give 'superhost' to ~¼ of hosts.
  final superhostAnchor = anchorByIdentifier['superhost']!;
  for (final host in hosts) {
    if (rng.nextDouble() < 0.25) {
      awards.add(
        _buildAward(
          issuerKey: issuerKey,
          definitionAnchor: superhostAnchor,
          recipientPubkey: host.keyPair.publicKey,
          listingAnchor: null,
          createdAt: ctx.timestampDaysAfter(3),
        ),
      );
    }
  }

  // Award listing-specific badges to ~half the listings.
  final listingBadges = [
    ('eco_friendly', anchorByIdentifier['eco_friendly']!),
    ('instant_book', anchorByIdentifier['instant_book']!),
    ('long_stay_friendly', anchorByIdentifier['long_stay_friendly']!),
  ];

  for (final listing in listings) {
    final listingAnchor = listing.anchor;
    if (listingAnchor == null) continue;

    // Each listing-level badge has a ~50% chance of being awarded.
    for (final (_, badgeAnchor) in listingBadges) {
      if (rng.nextDouble() < 0.5) {
        awards.add(
          _buildAward(
            issuerKey: issuerKey,
            definitionAnchor: badgeAnchor,
            recipientPubkey: listing.pubKey,
            listingAnchor: listingAnchor,
            createdAt: ctx.timestampDaysAfter(4),
          ),
        );
      }
    }
  }

  return BadgeSeedData(definitions: definitions, awards: awards);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

BadgeDefinition _buildDefinition({
  required KeyPair issuerKey,
  required String identifier,
  required String name,
  required String description,
  required int createdAt,
}) {
  final event = Nip01Event(
    pubKey: issuerKey.publicKey,
    kind: kNostrKindBadgeDefinition,
    tags: [
      ['d', identifier],
    ],
    content:
        '{"name":"${_escapeJson(name)}",'
        '"description":"${_escapeJson(description)}"}',
    createdAt: createdAt,
  );
  return BadgeDefinition.fromNostrEvent(
    event,
  ).signAs(issuerKey, BadgeDefinition.fromNostrEvent);
}

BadgeAward _buildAward({
  required KeyPair issuerKey,
  required String definitionAnchor,
  required String recipientPubkey,
  required String? listingAnchor,
  required int createdAt,
}) {
  final tags = <List<String>>[
    ['a', definitionAnchor],
    ['p', recipientPubkey],
    if (listingAnchor != null) ['a', listingAnchor],
  ];
  final event = Nip01Event(
    pubKey: issuerKey.publicKey,
    kind: kNostrKindBadgeAward,
    tags: tags,
    content: '',
    createdAt: createdAt,
  );
  return BadgeAward.fromNostrEvent(
    event,
  ).signAs(issuerKey, BadgeAward.fromNostrEvent);
}

String _escapeJson(String s) =>
    s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
