import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

Listing _base({bool negotiable = false}) => Listing.create(
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
      specifications: Specifications(),
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

      expect(filter.tags?['N'], ['true']);
    });

    test('rebuild refreshes promoted negotiable tag', () {
      final listing = _base();
      final rebuilt = listing.rebuild(negotiable: true);

      expect(rebuilt.negotiable, isTrue);
      expect(rebuilt.parsedTags.getTags('N'), contains('true'));
      expect(rebuilt.parsedTags.getTags('N'), isNot(contains('false')));
    });
  });
}
