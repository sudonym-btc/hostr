import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

void main() {
  group('Listing securityDeposit', () {
    test('creates listing with securityDeposit tag', () {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-deposit',
        title: 'Listing with deposit',
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
      );

      expect(listing.securityDeposit, isNotNull);
      expect(listing.securityDeposit!.value, BigInt.from(50000));
      expect(listing.securityDeposit!.denomination, 'BTC');
      expect(listing.securityDeposit!.decimals, 8);
    });

    test('creates listing without securityDeposit tag', () {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-no-deposit',
        title: 'Listing without deposit',
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
      );

      expect(listing.securityDeposit, isNull);
    });

    test('securityDeposit round-trips through sign and parse', () {
      final signed = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-roundtrip',
        title: 'Roundtrip',
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
          value: BigInt.from(25000),
          denomination: 'BTC',
          decimals: 8,
        ),
      ).signAs(MockKeys.hoster, Listing.fromNostrEvent);

      expect(signed.securityDeposit, isNotNull);
      expect(signed.securityDeposit!.value, BigInt.from(25000));
      expect(signed.securityDeposit!.denomination, 'BTC');
      expect(signed.securityDeposit!.decimals, 8);
    });

    test('rebuild preserves securityDeposit', () {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-rebuild',
        title: 'Rebuild',
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
      );

      final rebuilt = listing.rebuild(title: 'Updated Title');
      expect(rebuilt.securityDeposit, isNotNull);
      expect(rebuilt.securityDeposit!.value, BigInt.from(50000));
      expect(rebuilt.title, 'Updated Title');
    });

    test('rebuild can clear securityDeposit', () {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-clear',
        title: 'Clear',
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
      );

      final cleared = listing.rebuild(clearSecurityDeposit: true);
      expect(cleared.securityDeposit, isNull);
    });

    test('rebuild can update securityDeposit', () {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-update',
        title: 'Update',
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
      );

      final updated = listing.rebuild(
        securityDeposit: DenominatedAmount(
          value: BigInt.from(75000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );
      expect(updated.securityDeposit, isNotNull);
      expect(updated.securityDeposit!.value, BigInt.from(75000));
    });
  });

  group('Listing minPaymentAmount', () {
    Listing _base({DenominatedAmount? minPaymentAmount}) => Listing.create(
          pubKey: MockKeys.hoster.publicKey,
          dTag: 'listing-min-payment',
          title: 'Min Payment Listing',
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
          minPaymentAmount: minPaymentAmount,
        );

    test('creates listing with minPaymentAmount tag', () {
      final listing = _base(
        minPaymentAmount: DenominatedAmount(
          value: BigInt.from(10000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );
      expect(listing.minPaymentAmount, isNotNull);
      expect(listing.minPaymentAmount!.value, BigInt.from(10000));
      expect(listing.minPaymentAmount!.denomination, 'BTC');
    });

    test('creates listing without minPaymentAmount', () {
      final listing = _base();
      expect(listing.minPaymentAmount, isNull);
    });

    test('minPaymentAmount round-trips through sign and parse', () {
      final signed = _base(
        minPaymentAmount: DenominatedAmount(
          value: BigInt.from(25000),
          denomination: 'BTC',
          decimals: 8,
        ),
      ).signAs(MockKeys.hoster, Listing.fromNostrEvent);

      expect(signed.minPaymentAmount, isNotNull);
      expect(signed.minPaymentAmount!.value, BigInt.from(25000));
    });

    test('rebuild preserves minPaymentAmount', () {
      final listing = _base(
        minPaymentAmount: DenominatedAmount(
          value: BigInt.from(10000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );
      final rebuilt = listing.rebuild(title: 'Updated');
      expect(rebuilt.minPaymentAmount, isNotNull);
      expect(rebuilt.minPaymentAmount!.value, BigInt.from(10000));
    });

    test('rebuild can clear minPaymentAmount', () {
      final listing = _base(
        minPaymentAmount: DenominatedAmount(
          value: BigInt.from(10000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );
      final cleared = listing.rebuild(clearMinPaymentAmount: true);
      expect(cleared.minPaymentAmount, isNull);
    });

    test('rebuild can update minPaymentAmount', () {
      final listing = _base(
        minPaymentAmount: DenominatedAmount(
          value: BigInt.from(10000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );
      final updated = listing.rebuild(
        minPaymentAmount: DenominatedAmount(
          value: BigInt.from(50000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );
      expect(updated.minPaymentAmount!.value, BigInt.from(50000));
    });

    test('both securityDeposit and minPaymentAmount coexist', () {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-both',
        title: 'Both fields',
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
      ).signAs(MockKeys.hoster, Listing.fromNostrEvent);

      expect(listing.securityDeposit!.value, BigInt.from(50000));
      expect(listing.minPaymentAmount!.value, BigInt.from(10000));
    });
  });
}
