import 'dart:math';

import 'package:models/main.dart';

import '../seed_context.dart';
import '../seed_pipeline_config.dart';
import '../seed_pipeline_models.dart';

/// Stage 3: Build listing events (kind 32121) for host users.
///
/// Respects per-user [SeedUserSpec.listingCount] overrides and falls back
/// to the global [SeedPipelineConfig.listingsPerHostAvg].
List<Listing> buildListings({
  required SeedContext ctx,
  required SeedPipelineConfig config,
  required List<SeedUser> hosts,
}) {
  final listings = <Listing>[];
  var listingIndex = 0;

  for (final host in hosts) {
    final count =
        host.spec?.listingCount ?? ctx.sampleAverage(config.listingsPerHostAvg);

    for (var i = 0; i < count; i++) {
      listingIndex++;
      final dailySats = 50 * 1000 + ctx.random.nextInt(200 * 1000);
      final requiresEscrow =
          host.hasEvm &&
          ctx.pickByRatio(config.threadStages.paidViaEscrowRatio);
      final base = _landSeedPoints[listingIndex % _landSeedPoints.length];
      const jitterDegrees = 0.7;
      final latJitter = (ctx.random.nextDouble() - 0.5) * jitterDegrees;
      final lonJitter = (ctx.random.nextDouble() - 0.5) * jitterDegrees;

      final latitude = (base.latitude + latJitter)
          .clamp(-85.0, 85.0)
          .toDouble();
      var longitude = base.longitude + lonJitter;
      if (longitude > 180) longitude -= 360;
      if (longitude < -180) longitude += 360;

      final h3Tags = H3Engine.bundled().hierarchy.hierarchyForPoint(
        latitude: latitude,
        longitude: longitude,
      );

      final tags = List<List<String>>.generate(
        h3Tags.length,
        (i) => ['g', h3Tags[i]],
      );
      tags.add(['d', count.toString()]);

      final listingType =
          ListingType.values[ctx.random.nextInt(ListingType.values.length)];
      final theme = _themeForListingType(listingType);
      final imageCount = 1 + ctx.random.nextInt(6);
      final images = List<String>.generate(
        imageCount,
        (imageIndex) => _buildListingImageUrl(
          ctx: ctx,
          theme: theme,
          listingIndex: listingIndex,
          imageIndex: imageIndex,
        ),
      );

      final listing = Listing(
        pubKey: host.keyPair.publicKey,
        tags: EventTags([
          ...tags,
          ['d', 'seed-listing-$listingIndex'],
        ]),
        createdAt: ctx.timestampDaysAfter(listingIndex),
        content: ListingContent(
          title: _buildListingTitle(ctx, theme),
          description: _buildListingDescription(ctx, theme),
          price: [
            Price(
              amount: Amount(
                currency: Currency.BTC,
                value: BigInt.from(dailySats),
              ),
              frequency: Frequency.daily,
            ),
          ],
          minStay: const Duration(days: 1),
          checkIn: TimeOfDay(hour: 15, minute: 0),
          checkOut: TimeOfDay(hour: 11, minute: 0),
          location: 'seed-location-${(listingIndex % 12) + 1}',
          quantity: 1 + ctx.random.nextInt(2),
          type: listingType,
          images: images,
          amenities: _buildRandomAmenities(ctx),
          requiresEscrow: requiresEscrow,
        ),
      ).signAs(host.keyPair, Listing.fromNostrEvent);

      listings.add(listing);
    }
  }
  return listings;
}

// ─── Listing themes ─────────────────────────────────────────────────────────

enum _ListingTheme { urban, cozy, family, boutique, coastal }

const Map<ListingType, _ListingTheme> _listingTypeTheme = {
  ListingType.room: _ListingTheme.cozy,
  ListingType.house: _ListingTheme.family,
  ListingType.apartment: _ListingTheme.urban,
  ListingType.villa: _ListingTheme.coastal,
  ListingType.hotel: _ListingTheme.boutique,
  ListingType.hostel: _ListingTheme.urban,
  ListingType.resort: _ListingTheme.coastal,
};

_ListingTheme _themeForListingType(ListingType type) =>
    _listingTypeTheme[type] ?? _ListingTheme.urban;

// ─── Title / description templates ──────────────────────────────────────────

const Map<_ListingTheme, List<String>> _themeTitlePrefixes = {
  _ListingTheme.urban: [
    'Modern',
    'Stylish',
    'Bright',
    'Contemporary',
    'Minimalist',
    'Sleek',
    'Central',
    'Trendy',
  ],
  _ListingTheme.cozy: [
    'Cozy',
    'Charming',
    'Warm',
    'Quiet',
    'Rustic',
    'Peaceful',
    'Snug',
    'Inviting',
  ],
  _ListingTheme.family: [
    'Spacious',
    'Comfortable',
    'Relaxed',
    'Sunny',
    'Welcoming',
    'Practical',
    'Roomy',
    'Convenient',
  ],
  _ListingTheme.boutique: [
    'Elegant',
    'Design-Forward',
    'Chic',
    'Refined',
    'Upscale',
    'Curated',
    'Premium',
    'Signature',
  ],
  _ListingTheme.coastal: [
    'Seaside',
    'Oceanfront',
    'Tropical',
    'Airy',
    'Breezy',
    'Sunlit',
    'Shoreline',
    'Island-Style',
  ],
};

const Map<_ListingTheme, List<String>> _themeTitleNouns = {
  _ListingTheme.urban: [
    'City Apartment',
    'Downtown Loft',
    'Urban Studio',
    'Metro Retreat',
    'Skyline Flat',
    'Transit Hub Loft',
    'City View Suite',
    'Central Apartment',
  ],
  _ListingTheme.cozy: [
    'Nature Getaway',
    'Garden Room',
    'Forest Hideaway',
    'Quiet Retreat',
    'Countryside Cabin',
    'Woodland Stay',
    'Hillside Nook',
    'Mountain Hideout',
  ],
  _ListingTheme.family: [
    'Family Home',
    'Neighborhood House',
    'Greenbelt Home',
    'Weekend Escape',
    'Suburban Retreat',
    'Group-Friendly Home',
    'Parkside House',
    'Family Basecamp',
  ],
  _ListingTheme.boutique: [
    'Boutique Stay',
    'Designer Suite',
    'Stylish Room',
    'Central Guesthouse',
    'Luxury Loft',
    'City Boutique Room',
    'Executive Suite',
    'Curated Residence',
  ],
  _ListingTheme.coastal: [
    'Beach Villa',
    'Ocean Getaway',
    'Coastal Retreat',
    'Resort Escape',
    'Sea View Apartment',
    'Lagoon Hideaway',
    'Surfside Villa',
    'Harbor Retreat',
  ],
};

const Map<_ListingTheme, List<String>> _themeDescriptionStarts = {
  _ListingTheme.urban: [
    'Set in a lively neighborhood with cafés and transit nearby, this stay is built for easy city exploring.',
    'A thoughtfully designed city base with clean lines, natural light, and everything needed for a smooth stay.',
    'Right in the heart of the city, this apartment makes it simple to walk, ride, and explore from morning to night.',
    'Polished interiors and practical amenities create a comfortable launchpad for busy urban days.',
  ],
  _ListingTheme.cozy: [
    'Tucked into a calmer setting, this space offers a peaceful atmosphere and a slower pace.',
    'Perfect for unwinding, this stay combines warm interiors with quiet surroundings.',
    'Surrounded by natural charm, this home invites you to disconnect and settle into a restful rhythm.',
    'Soft textures, warm light, and a tranquil setting make this space ideal for recharging.',
  ],
  _ListingTheme.family: [
    'This home offers generous space for small groups and families looking for comfort and convenience.',
    'Designed for longer, easygoing stays with room to spread out and relax together.',
    'With multiple sleeping areas and shared spaces, this stay is built for family routines and group comfort.',
    'A practical home base with flexible space, ideal for family holidays and group trips.',
  ],
  _ListingTheme.boutique: [
    'Curated interiors and thoughtful details create a polished boutique-style experience.',
    'An elevated stay with refined decor, central access, and a welcoming atmosphere.',
    'Distinctive design touches and premium finishes deliver a memorable, boutique-inspired stay.',
    'Tailored decor and well-considered comfort offer a refined city escape with personality.',
  ],
  _ListingTheme.coastal: [
    'Breezy interiors and a holiday vibe make this an ideal base for a coastal break.',
    'A sun-filled retreat designed for laid-back mornings and relaxed evenings.',
    'Steps from coastal scenery, this stay pairs relaxed living with bright, beachy interiors.',
    'Ocean air, open spaces, and easy access to the water create a true getaway atmosphere.',
  ],
};

const Map<_ListingTheme, List<String>> _themeDescriptionEnds = {
  _ListingTheme.urban: [
    'Great for digital nomads, couples, or short city breaks.',
    'Ideal for work trips and weekend escapes alike.',
    'Close to dining, transit, and nightlife while still feeling private and comfortable.',
    'A smart choice for guests who want convenience, style, and easy mobility.',
  ],
  _ListingTheme.cozy: [
    'A great pick for couples and solo travelers seeking a restful stay.',
    'Best for guests who value comfort, privacy, and a calm setting.',
    'Perfect for reading days, nature walks, and slow mornings with coffee.',
    'Ideal for travelers looking for serenity, warmth, and a homey atmosphere.',
  ],
  _ListingTheme.family: [
    'Perfect for family trips, friend groups, and longer visits.',
    'A practical, comfortable choice for guests who need extra room.',
    'Well-suited for shared meals, flexible sleeping arrangements, and longer stays.',
    'A dependable option for groups wanting space, comfort, and easy logistics.',
  ],
  _ListingTheme.boutique: [
    'Best for travelers who appreciate design, location, and convenience.',
    'Ideal for stylish city stays with hotel-like comfort.',
    'Excellent for couples or professionals seeking a premium, design-led stay.',
    'A standout pick for guests who enjoy aesthetics and elevated comfort.',
  ],
  _ListingTheme.coastal: [
    'Perfect for beach days, sunset dinners, and slow mornings.',
    'An easy choice for guests chasing ocean air and relaxed evenings.',
    'Great for guests who want a mix of seaside adventure and laid-back comfort.',
    'Best enjoyed with beach walks, open-air dining, and sunset views.',
  ],
};

String _buildListingTitle(SeedContext ctx, _ListingTheme theme) {
  final prefix = ctx.pickFrom(_themeTitlePrefixes[theme]!);
  final noun = ctx.pickFrom(_themeTitleNouns[theme]!);
  return '$prefix $noun';
}

String _buildListingDescription(SeedContext ctx, _ListingTheme theme) {
  final start = ctx.pickFrom(_themeDescriptionStarts[theme]!);
  final end = ctx.pickFrom(_themeDescriptionEnds[theme]!);
  return '$start $end';
}

// ─── Images ─────────────────────────────────────────────────────────────────

const Map<_ListingTheme, List<String>> _themeImageUrls = {
  _ListingTheme.urban: [
    'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1464890100898-a385f744067f?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1493666438817-866a91353ca9?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
  _ListingTheme.cozy: [
    'https://images.unsplash.com/photo-1449158743715-0a90ebb6d2d8?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1470246973918-29a93221c455?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1510798831971-661eb04b3739?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1499696010181-024a06f4f8a9?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1473116763249-2faaef81ccda?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1459535653751-d571815e906b?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1472224371017-08207f84aaae?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1430285561322-7808604715df?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1449844908441-8829872d2607?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
  _ListingTheme.family: [
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb3?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1613545325268-9265e1609167?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
  _ListingTheme.boutique: [
    'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1444201983204-c43cbd584d93?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1455587734955-081b22074882?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1479839672679-a46483c0e7c8?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1429170052398-05c242fdb399?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
  _ListingTheme.coastal: [
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1498503182468-3b51cbb6cb24?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1540541338287-41700207dee6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1473116763249-2faaef81ccda?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1505881502353-a1986add3762?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1468413253725-0d5181091126?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
};

String _buildListingImageUrl({
  required SeedContext ctx,
  required _ListingTheme theme,
  required int listingIndex,
  required int imageIndex,
}) {
  final lock = ctx.seed * 100000 + listingIndex * 10 + imageIndex;
  final options = _themeImageUrls[theme] ?? const <String>[];
  if (options.isEmpty) {
    return 'https://picsum.photos/seed/hostr-fallback-$lock/1200/800';
  }
  return options[lock % options.length];
}

// ─── Amenities ──────────────────────────────────────────────────────────────

Amenities _buildRandomAmenities(SeedContext ctx) {
  final amenities = Amenities();
  final appliers = <void Function(Amenities)>[
    (a) => a.airconditioning = true,
    (a) => a.allows_pets = true,
    (a) => a.bathtub = 1,
    (a) => a.beds = 1 + ctx.random.nextInt(4),
    (a) => a.bedrooms = 1 + ctx.random.nextInt(3),
    (a) => a.tv = 1,
    (a) => a.tumble_dryer = true,
    (a) => a.washer = true,
    (a) => a.elevator = true,
    (a) => a.free_parking = true,
    (a) => a.gym = true,
    (a) => a.heating = true,
    (a) => a.wireless_internet = true,
    (a) => a.kitchen = true,
    (a) => a.pool = true,
    (a) => a.breakfast = true,
    (a) => a.fireplace = true,
    (a) => a.essentials = true,
    (a) => a.oven = true,
    (a) => a.bbq = true,
    (a) => a.balcony = true,
    (a) => a.patio = true,
    (a) => a.dishwasher = true,
    (a) => a.refrigerator = true,
    (a) => a.garden_or_backyard = true,
    (a) => a.microwave = true,
    (a) => a.coffee_maker = true,
    (a) => a.stove = true,
    (a) => a.beachfront = true,
    (a) => a.hot_water = true,
    (a) => a.lake_access = true,
  ];

  final shuffledIndexes = List<int>.generate(appliers.length, (i) => i)
    ..shuffle(ctx.random);
  final count = 1 + ctx.random.nextInt(min(10, appliers.length));

  for (var i = 0; i < count; i++) {
    appliers[shuffledIndexes[i]](amenities);
  }

  return amenities;
}

// ─── Seed cities ────────────────────────────────────────────────────────────

const List<({double latitude, double longitude})> _landSeedPoints = [
  (latitude: 40.7128, longitude: -74.0060),
  (latitude: 34.0522, longitude: -118.2437),
  (latitude: 41.8781, longitude: -87.6298),
  (latitude: 47.6062, longitude: -122.3321),
  (latitude: 25.7617, longitude: -80.1918),
  (latitude: 43.6532, longitude: -79.3832),
  (latitude: 45.5017, longitude: -73.5673),
  (latitude: 19.4326, longitude: -99.1332),
  (latitude: 20.6597, longitude: -103.3496),
  (latitude: 4.7110, longitude: -74.0721),
  (latitude: 6.2442, longitude: -75.5812),
  (latitude: -12.0464, longitude: -77.0428),
  (latitude: -33.4489, longitude: -70.6693),
  (latitude: -23.5505, longitude: -46.6333),
  (latitude: -22.9068, longitude: -43.1729),
  (latitude: -34.6037, longitude: -58.3816),
  (latitude: -34.9011, longitude: -56.1645),
  (latitude: 51.5074, longitude: -0.1278),
  (latitude: 53.4808, longitude: -2.2426),
  (latitude: 48.8566, longitude: 2.3522),
  (latitude: 45.7640, longitude: 4.8357),
  (latitude: 52.5200, longitude: 13.4050),
  (latitude: 48.1351, longitude: 11.5820),
  (latitude: 52.3676, longitude: 4.9041),
  (latitude: 50.8503, longitude: 4.3517),
  (latitude: 40.4168, longitude: -3.7038),
  (latitude: 41.3851, longitude: 2.1734),
  (latitude: 38.7223, longitude: -9.1393),
  (latitude: 41.1579, longitude: -8.6291),
  (latitude: 41.9028, longitude: 12.4964),
  (latitude: 45.4642, longitude: 9.1900),
  (latitude: 59.3293, longitude: 18.0686),
  (latitude: 55.6761, longitude: 12.5683),
  (latitude: 59.9139, longitude: 10.7522),
  (latitude: 60.1699, longitude: 24.9384),
  (latitude: 52.2297, longitude: 21.0122),
  (latitude: 50.0755, longitude: 14.4378),
  (latitude: 47.4979, longitude: 19.0402),
  (latitude: 48.2082, longitude: 16.3738),
  (latitude: 50.1109, longitude: 8.6821),
  (latitude: 47.3769, longitude: 8.5417),
  (latitude: 46.2044, longitude: 6.1432),
  (latitude: 53.3498, longitude: -6.2603),
  (latitude: 64.1466, longitude: -21.9426),
  (latitude: 37.9838, longitude: 23.7275),
  (latitude: 41.0082, longitude: 28.9784),
  (latitude: 44.4268, longitude: 26.1025),
  (latitude: 42.6977, longitude: 23.3219),
  (latitude: 44.7866, longitude: 20.4489),
  (latitude: 45.8150, longitude: 15.9819),
  (latitude: 46.0569, longitude: 14.5058),
  (latitude: 43.8563, longitude: 18.4131),
  (latitude: 41.3275, longitude: 19.8187),
  (latitude: 35.1856, longitude: 33.3823),
  (latitude: 30.0444, longitude: 31.2357),
  (latitude: 31.2001, longitude: 29.9187),
  (latitude: 33.5731, longitude: -7.5898),
  (latitude: 36.8065, longitude: 10.1815),
  (latitude: 5.6037, longitude: -0.1870),
  (latitude: 6.5244, longitude: 3.3792),
  (latitude: 9.0765, longitude: 7.3986),
  (latitude: -1.2921, longitude: 36.8219),
  (latitude: 9.0054, longitude: 38.7636),
  (latitude: -26.2041, longitude: 28.0473),
  (latitude: -33.9249, longitude: 18.4241),
  (latitude: 14.7167, longitude: -17.4677),
  (latitude: 24.7136, longitude: 46.6753),
  (latitude: 25.2048, longitude: 55.2708),
  (latitude: 25.2854, longitude: 51.5310),
  (latitude: 32.0853, longitude: 34.7818),
  (latitude: 33.8938, longitude: 35.5018),
  (latitude: 35.6892, longitude: 51.3890),
  (latitude: 33.3152, longitude: 44.3661),
  (latitude: 28.6139, longitude: 77.2090),
  (latitude: 19.0760, longitude: 72.8777),
  (latitude: 12.9716, longitude: 77.5946),
  (latitude: 13.0827, longitude: 80.2707),
  (latitude: 22.5726, longitude: 88.3639),
  (latitude: 23.8103, longitude: 90.4125),
  (latitude: 24.8607, longitude: 67.0011),
  (latitude: 31.5204, longitude: 74.3587),
  (latitude: 27.7172, longitude: 85.3240),
  (latitude: 6.9271, longitude: 79.8612),
  (latitude: 13.7563, longitude: 100.5018),
  (latitude: 10.8231, longitude: 106.6297),
  (latitude: 21.0278, longitude: 105.8342),
  (latitude: 3.1390, longitude: 101.6869),
  (latitude: 1.3521, longitude: 103.8198),
  (latitude: -6.2088, longitude: 106.8456),
  (latitude: -8.6500, longitude: 115.2167),
  (latitude: 14.5995, longitude: 120.9842),
  (latitude: 7.1907, longitude: 125.4553),
  (latitude: 25.0330, longitude: 121.5654),
  (latitude: 22.3193, longitude: 114.1694),
  (latitude: 22.1987, longitude: 113.5439),
  (latitude: 31.2304, longitude: 121.4737),
  (latitude: 39.9042, longitude: 116.4074),
  (latitude: 23.1291, longitude: 113.2644),
  (latitude: 30.5728, longitude: 104.0668),
  (latitude: 35.6895, longitude: 139.6917),
  (latitude: 34.6937, longitude: 135.5023),
  (latitude: 43.0621, longitude: 141.3544),
  (latitude: 37.5665, longitude: 126.9780),
  (latitude: 35.1796, longitude: 129.0756),
  (latitude: -31.9505, longitude: 115.8605),
  (latitude: -33.8688, longitude: 151.2093),
  (latitude: -37.8136, longitude: 144.9631),
  (latitude: -27.4698, longitude: 153.0251),
  (latitude: -36.8485, longitude: 174.7633),
  (latitude: -41.2866, longitude: 174.7756),
];
