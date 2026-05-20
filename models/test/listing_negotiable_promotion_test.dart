import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

Listing _base({
  bool negotiable = false,
  Specifications? specifications,
}) =>
    Listing.create(
      pubKey: MockKeys.hoster.publicKey,
      dTag: 'listing-negotiable',
      title: 'Negotiable Listing',
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
      specifications: specifications ?? Specifications(),
      negotiable: negotiable,
    );

void main() {
  group('Listing negotiable promotion', () {
    test('emits promoted N tag for negotiable listings', () {
      final listing = _base(negotiable: true);

      expect(listing.negotiable, isTrue);
      expect(listing.parsedTags.getTags('N'), contains('true'));
    });

    test('filter builder targets promoted negotiable tag', () {
      final filter = Listing.buildFilter().negotiable().build();

      expect(filter.tags?['t'], ['accommodation']);
      expect(filter.tags?['N'], ['true']);
    });

    test('emits promoted A tag for active state', () {
      final activeListing = _base();
      final inactiveListing = activeListing.rebuild(active: false);

      expect(activeListing.active, isTrue);
      expect(activeListing.parsedTags.getTags('A'), contains('true'));
      expect(inactiveListing.active, isFalse);
      expect(inactiveListing.parsedTags.getTags('A'), contains('false'));
      expect(inactiveListing.parsedTags.getTags('A'), isNot(contains('true')));
    });

    test('rebuild refreshes promoted negotiable tag', () {
      final listing = _base();
      final rebuilt = listing.rebuild(negotiable: true);

      expect(rebuilt.negotiable, isTrue);
      expect(rebuilt.parsedTags.getTags('N'), contains('true'));
      expect(rebuilt.parsedTags.getTags('N'), isNot(contains('false')));
    });

    test('emits promoted feature-combination tags for relay-side AND', () {
      final listing = _base(
        specifications: Specifications({
          'kitchen': true,
          'allows_pets': true,
          'beachfront': true,
        }),
      );

      expect(listing.parsedTags.getTags('s'), contains('kitchen'));
      expect(listing.parsedTags.getTags('s'), contains('allows_pets'));
      expect(listing.parsedTags.getTags('S'), contains('allows_pets+kitchen'));
      expect(listing.parsedTags.getTags('S'),
          contains('allows_pets+beachfront+kitchen'));
    });

    test('filter builder uses compound tag for multi-feature search', () {
      final filter =
          Listing.buildFilter().features(['kitchen', 'allows_pets']).build();

      expect(filter.tags?['t'], ['accommodation']);
      expect(filter.tags?['s'], isNull);
      expect(filter.tags?['S'], ['allows_pets+kitchen']);
    });

    test('filter builder keeps promoted boolean tag for single-feature search',
        () {
      final filter = Listing.buildFilter().features(['kitchen']).build();

      expect(filter.tags?['s'], ['kitchen']);
      expect(filter.tags?['S'], isNull);
    });

    test('derives rent mode from recurring prices and promotes it', () {
      final listing = _base();

      expect(listing.rentOrBuy, RentOrBuy.rent);
      expect(listing.parsedTags.getTags('rentOrBuy'), ['rent']);
      expect(listing.parsedTags.getTags('M'), ['rent']);
    });

    test('derives buy mode from fixed prices and promotes it', () {
      final listing = _base().rebuild(
        prices: [
          Price(
            amount: DenominatedAmount(
              value: BigInt.from(100000),
              denomination: 'BTC',
              decimals: 8,
            ),
          ),
        ],
      );

      expect(listing.rentOrBuy, RentOrBuy.buy);
      expect(listing.parsedTags.getTags('rentOrBuy'), ['buy']);
      expect(listing.parsedTags.getTags('M'), ['buy']);
      expect(listing.parsedTags.getTags('M'), isNot(contains('rent')));
    });

    test('filter builder targets promoted rent or buy tag', () {
      final filter = Listing.buildFilter().forRent().build();

      expect(filter.tags?['t'], ['accommodation']);
      expect(filter.tags?['M'], ['rent']);
    });
  });
}
