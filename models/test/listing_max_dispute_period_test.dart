import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

Listing _base({int? maxDisputePeriod}) => Listing.create(
      pubKey: MockKeys.hoster.publicKey,
      dTag: 'listing-max-claim',
      title: 'Max Claim Period Listing',
      description: 'Fixture',
      images: const [],
      price: [
        Price(
          amount: DenominatedAmount(
            value: BigInt.from(100000),
            denomination: 'BTC',
            decimals: 8,
          ),
          frequency: Frequency.daily,
        ),
      ],
      location: 'Test',
      type: ListingType.house,
      specifications: Specifications(),
      maxDisputePeriod: maxDisputePeriod,
    );

void main() {
  group('Listing maxDisputePeriod', () {
    test('defaults to 2 weeks when not set', () {
      final listing = _base();
      expect(listing.maxDisputePeriod, 14 * 24 * 60 * 60);
    });

    test('creates listing with explicit maxDisputePeriod', () {
      final listing = _base(maxDisputePeriod: 86400); // 1 day
      expect(listing.maxDisputePeriod, 86400);
    });

    test('round-trips through sign and parse', () {
      final signed = _base(maxDisputePeriod: 604800) // 1 week
          .signAs(MockKeys.hoster, Listing.fromNostrEvent);

      expect(signed.maxDisputePeriod, 604800);
    });

    test('defaults to 2 weeks after sign+parse when not set', () {
      final signed = _base().signAs(MockKeys.hoster, Listing.fromNostrEvent);

      // Tag is absent → getter falls back to defaultMaxDisputePeriod.
      expect(signed.maxDisputePeriod, ListingTagRead.defaultMaxDisputePeriod);
    });

    test('rebuild preserves maxDisputePeriod', () {
      final listing = _base(maxDisputePeriod: 172800); // 2 days
      final rebuilt = listing.rebuild(title: 'Updated');
      expect(rebuilt.maxDisputePeriod, 172800);
      expect(rebuilt.title, 'Updated');
    });

    test('rebuild can clear maxDisputePeriod back to default', () {
      final listing = _base(maxDisputePeriod: 86400);
      final cleared = listing.rebuild(clearMaxDisputePeriod: true);
      // Tag is gone → getter falls back to default 2 weeks.
      expect(cleared.maxDisputePeriod, ListingTagRead.defaultMaxDisputePeriod);
    });

    test('rebuild can update maxDisputePeriod', () {
      final listing = _base(maxDisputePeriod: 86400);
      final updated = listing.rebuild(maxDisputePeriod: 259200); // 3 days
      expect(updated.maxDisputePeriod, 259200);
    });

    test('coexists with securityDeposit and minPaymentAmount', () {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-coexist',
        title: 'Coexist',
        description: 'Fixture',
        images: const [],
        price: [
          Price(
            amount: DenominatedAmount(
              value: BigInt.from(100000),
              denomination: 'BTC',
              decimals: 8,
            ),
            frequency: Frequency.daily,
          ),
        ],
        location: 'Test',
        type: ListingType.house,
        specifications: Specifications(),
        securityDeposit: DenominatedAmount(
          value: BigInt.from(50000),
          denomination: 'BTC',
          decimals: 8,
        ),
        minPaymentAmount: DenominatedAmount(
          value: BigInt.from(10000),
          denomination: 'BTC',
          decimals: 8,
        ),
        maxDisputePeriod: 604800, // 1 week
      ).signAs(MockKeys.hoster, Listing.fromNostrEvent);

      expect(listing.securityDeposit!.value, BigInt.from(50000));
      expect(listing.minPaymentAmount!.value, BigInt.from(10000));
      expect(listing.maxDisputePeriod, 604800);
    });
  });
}
