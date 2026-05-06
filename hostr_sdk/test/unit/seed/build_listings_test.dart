import 'package:hostr_sdk/seed/pipeline/seed_context.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_models.dart';
import 'package:hostr_sdk/seed/pipeline/stages/build_listings.dart';
import 'package:test/test.dart';

void main() {
  group('buildListings', () {
    test('marks about half of seeded listings as negotiable', () {
      final ctx = SeedContext(seed: 7);
      final host = SeedUser(
        index: 1,
        keyPair: ctx.deriveKeyPair(1),
        isHost: true,
        hasEvm: true,
        spec: const SeedUserSpec.host(listingCount: 4),
      );

      final listings = buildListings(
        ctx: ctx,
        config: const SeedPipelineConfig(),
        hosts: [host],
      );

      expect(listings, hasLength(4));
      expect(listings.where((listing) => listing.negotiable), hasLength(2));
    });

    test('uses exactly one price denomination per seeded listing', () {
      final ctx = SeedContext(seed: 11);
      final host = SeedUser(
        index: 1,
        keyPair: ctx.deriveKeyPair(1),
        isHost: true,
        hasEvm: true,
        spec: const SeedUserSpec.host(listingCount: 50),
      );

      final listings = buildListings(
        ctx: ctx,
        config: const SeedPipelineConfig(
          usdtAddress: '0x0000000000000000000000000000000000000001',
        ),
        hosts: [host],
      );

      final denominations = listings
          .map((listing) => listing.prices.map((p) => p.amount.denomination))
          .toList();

      expect(denominations, everyElement(hasLength(1)));
      expect(denominations.any((d) => d.single == 'BTC'), isTrue);
      expect(denominations.any((d) => d.single == 'USD'), isTrue);
    });

    test('gives every seeded listing multiple images', () {
      final ctx = SeedContext(seed: 19);
      final host = SeedUser(
        index: 1,
        keyPair: ctx.deriveKeyPair(1),
        isHost: true,
        hasEvm: true,
        spec: const SeedUserSpec.host(listingCount: 40),
      );

      final listings = buildListings(
        ctx: ctx,
        config: const SeedPipelineConfig(),
        hosts: [host],
      );

      expect(listings, hasLength(40));
      expect(
        listings.map((listing) => listing.images.length),
        everyElement(greaterThan(1)),
      );
    });
  });
}
