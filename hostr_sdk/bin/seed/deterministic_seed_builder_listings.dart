part of 'deterministic_seed_builder.dart';

extension _DeterministicSeedListings on DeterministicSeedBuilder {
  List<({double latitude, double longitude})> get landSeedPoints => [
    (latitude: 40.7128, longitude: -74.0060), // New York
    (latitude: 34.0522, longitude: -118.2437), // Los Angeles
    (latitude: 41.8781, longitude: -87.6298), // Chicago
    (latitude: 47.6062, longitude: -122.3321), // Seattle
    (latitude: 25.7617, longitude: -80.1918), // Miami
    (latitude: 43.6532, longitude: -79.3832), // Toronto
    (latitude: 45.5017, longitude: -73.5673), // Montreal
    (latitude: 19.4326, longitude: -99.1332), // Mexico City
    (latitude: 20.6597, longitude: -103.3496), // Guadalajara
    (latitude: 4.7110, longitude: -74.0721), // Bogotá
    (latitude: 6.2442, longitude: -75.5812), // Medellín
    (latitude: -12.0464, longitude: -77.0428), // Lima
    (latitude: -33.4489, longitude: -70.6693), // Santiago
    (latitude: -23.5505, longitude: -46.6333), // São Paulo
    (latitude: -22.9068, longitude: -43.1729), // Rio de Janeiro
    (latitude: -34.6037, longitude: -58.3816), // Buenos Aires
    (latitude: -34.9011, longitude: -56.1645), // Montevideo
    (latitude: 51.5074, longitude: -0.1278), // London
    (latitude: 53.4808, longitude: -2.2426), // Manchester
    (latitude: 48.8566, longitude: 2.3522), // Paris
    (latitude: 45.7640, longitude: 4.8357), // Lyon
    (latitude: 52.5200, longitude: 13.4050), // Berlin
    (latitude: 48.1351, longitude: 11.5820), // Munich
    (latitude: 52.3676, longitude: 4.9041), // Amsterdam
    (latitude: 50.8503, longitude: 4.3517), // Brussels
    (latitude: 40.4168, longitude: -3.7038), // Madrid
    (latitude: 41.3851, longitude: 2.1734), // Barcelona
    (latitude: 38.7223, longitude: -9.1393), // Lisbon
    (latitude: 41.1579, longitude: -8.6291), // Porto
    (latitude: 41.9028, longitude: 12.4964), // Rome
    (latitude: 45.4642, longitude: 9.1900), // Milan
    (latitude: 59.3293, longitude: 18.0686), // Stockholm
    (latitude: 55.6761, longitude: 12.5683), // Copenhagen
    (latitude: 59.9139, longitude: 10.7522), // Oslo
    (latitude: 60.1699, longitude: 24.9384), // Helsinki
    (latitude: 52.2297, longitude: 21.0122), // Warsaw
    (latitude: 50.0755, longitude: 14.4378), // Prague
    (latitude: 47.4979, longitude: 19.0402), // Budapest
    (latitude: 48.2082, longitude: 16.3738), // Vienna
    (latitude: 50.1109, longitude: 8.6821), // Frankfurt
    (latitude: 47.3769, longitude: 8.5417), // Zurich
    (latitude: 46.2044, longitude: 6.1432), // Geneva
    (latitude: 53.3498, longitude: -6.2603), // Dublin
    (latitude: 64.1466, longitude: -21.9426), // Reykjavik
    (latitude: 37.9838, longitude: 23.7275), // Athens
    (latitude: 41.0082, longitude: 28.9784), // Istanbul
    (latitude: 44.4268, longitude: 26.1025), // Bucharest
    (latitude: 42.6977, longitude: 23.3219), // Sofia
    (latitude: 44.7866, longitude: 20.4489), // Belgrade
    (latitude: 45.8150, longitude: 15.9819), // Zagreb
    (latitude: 46.0569, longitude: 14.5058), // Ljubljana
    (latitude: 43.8563, longitude: 18.4131), // Sarajevo
    (latitude: 41.3275, longitude: 19.8187), // Tirana
    (latitude: 35.1856, longitude: 33.3823), // Nicosia
    (latitude: 30.0444, longitude: 31.2357), // Cairo
    (latitude: 31.2001, longitude: 29.9187), // Alexandria
    (latitude: 33.5731, longitude: -7.5898), // Casablanca
    (latitude: 36.8065, longitude: 10.1815), // Tunis
    (latitude: 5.6037, longitude: -0.1870), // Accra
    (latitude: 6.5244, longitude: 3.3792), // Lagos
    (latitude: 9.0765, longitude: 7.3986), // Abuja
    (latitude: -1.2921, longitude: 36.8219), // Nairobi
    (latitude: 9.0054, longitude: 38.7636), // Addis Ababa
    (latitude: -26.2041, longitude: 28.0473), // Johannesburg
    (latitude: -33.9249, longitude: 18.4241), // Cape Town
    (latitude: 14.7167, longitude: -17.4677), // Dakar
    (latitude: 24.7136, longitude: 46.6753), // Riyadh
    (latitude: 25.2048, longitude: 55.2708), // Dubai
    (latitude: 25.2854, longitude: 51.5310), // Doha
    (latitude: 32.0853, longitude: 34.7818), // Tel Aviv
    (latitude: 33.8938, longitude: 35.5018), // Beirut
    (latitude: 35.6892, longitude: 51.3890), // Tehran
    (latitude: 33.3152, longitude: 44.3661), // Baghdad
    (latitude: 28.6139, longitude: 77.2090), // Delhi
    (latitude: 19.0760, longitude: 72.8777), // Mumbai
    (latitude: 12.9716, longitude: 77.5946), // Bengaluru
    (latitude: 13.0827, longitude: 80.2707), // Chennai
    (latitude: 22.5726, longitude: 88.3639), // Kolkata
    (latitude: 23.8103, longitude: 90.4125), // Dhaka
    (latitude: 24.8607, longitude: 67.0011), // Karachi
    (latitude: 31.5204, longitude: 74.3587), // Lahore
    (latitude: 27.7172, longitude: 85.3240), // Kathmandu
    (latitude: 6.9271, longitude: 79.8612), // Colombo
    (latitude: 13.7563, longitude: 100.5018), // Bangkok
    (latitude: 10.8231, longitude: 106.6297), // Ho Chi Minh City
    (latitude: 21.0278, longitude: 105.8342), // Hanoi
    (latitude: 3.1390, longitude: 101.6869), // Kuala Lumpur
    (latitude: 1.3521, longitude: 103.8198), // Singapore
    (latitude: -6.2088, longitude: 106.8456), // Jakarta
    (latitude: -8.6500, longitude: 115.2167), // Denpasar
    (latitude: 14.5995, longitude: 120.9842), // Manila
    (latitude: 7.1907, longitude: 125.4553), // Davao
    (latitude: 25.0330, longitude: 121.5654), // Taipei
    (latitude: 22.3193, longitude: 114.1694), // Hong Kong
    (latitude: 22.1987, longitude: 113.5439), // Macau
    (latitude: 31.2304, longitude: 121.4737), // Shanghai
    (latitude: 39.9042, longitude: 116.4074), // Beijing
    (latitude: 23.1291, longitude: 113.2644), // Guangzhou
    (latitude: 30.5728, longitude: 104.0668), // Chengdu
    (latitude: 35.6895, longitude: 139.6917), // Tokyo
    (latitude: 34.6937, longitude: 135.5023), // Osaka
    (latitude: 43.0621, longitude: 141.3544), // Sapporo
    (latitude: 37.5665, longitude: 126.9780), // Seoul
    (latitude: 35.1796, longitude: 129.0756), // Busan
    (latitude: -31.9505, longitude: 115.8605), // Perth
    (latitude: -33.8688, longitude: 151.2093), // Sydney
    (latitude: -37.8136, longitude: 144.9631), // Melbourne
    (latitude: -27.4698, longitude: 153.0251), // Brisbane
    (latitude: -36.8485, longitude: 174.7633), // Auckland
    (latitude: -41.2866, longitude: 174.7756), // Wellington
  ];

  List<Listing> buildListings(List<SeedUser> hosts) {
    final listings = <Listing>[];
    var listingIndex = 0;

    for (final host in hosts) {
      final count = _sampleAverage(config.listingsPerHostAvg);
      for (var i = 0; i < count; i++) {
        listingIndex++;
        final dailySats = 50 * 1000 + _random.nextInt(200 * 1000);
        final requiresEscrow =
            host.hasEvm && _pickByRatio(config.paidViaEscrowRatio);
        final base = landSeedPoints[listingIndex % landSeedPoints.length];
        const jitterDegrees = 0.7;
        final latJitter = (_random.nextDouble() - 0.5) * jitterDegrees;
        final lonJitter = (_random.nextDouble() - 0.5) * jitterDegrees;

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
        final imageCount = 1 + _random.nextInt(6);
        final images = List<String>.generate(
          imageCount,
          (imageIndex) =>
              'https://picsum.photos/seed/hostr-listing-${config.seed}-$listingIndex-$imageIndex/1200/800',
        );
        final listing = Listing(
          pubKey: host.keyPair.publicKey,
          tags: EventTags([
            ...tags,
            ['d', 'seed-listing-$listingIndex'],
          ]),
          createdAt: _timestampDaysAfter(listingIndex),
          content: ListingContent(
            title: 'Seed Listing #$listingIndex',
            description:
                'Deterministic listing #$listingIndex generated from seed ${config.seed}. ${faker.lorem.sentences(5).join(' ')}',
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
            quantity: 1 + _random.nextInt(2),
            type:
                ListingType.values[_random.nextInt(ListingType.values.length)],
            images: images,
            amenities: Amenities(),
            requiresEscrow: requiresEscrow,
          ),
        ).signAs(host.keyPair, Listing.fromNostrEvent);

        listings.add(listing);
      }
    }
    return listings;
  }
}
