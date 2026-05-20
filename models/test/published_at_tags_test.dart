import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

const _publishedAtTag = 'published_at';

final _listingAnchor = '30402:${MockKeys.hoster.publicKey}:test-listing';

Listing _listing({int createdAt = 1000}) {
  return Listing.create(
    pubKey: MockKeys.hoster.publicKey,
    dTag: 'test-listing',
    title: 'Test Listing',
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
    location: 'Test City',
    type: ListingType.house,
    specifications: Specifications(),
    createdAt: createdAt,
  );
}

Order _order({int createdAt = 1000}) {
  return Order.create(
    pubKey: MockKeys.guest.publicKey,
    dTag: 'test-order',
    listingAnchor: _listingAnchor,
    createdAt: createdAt,
  );
}

void main() {
  group('published_at tags', () {
    test('Listing.create sets published_at from createdAt', () {
      final listing = _listing(createdAt: 1111);

      expect(listing.parsedTags.getTagValue(_publishedAtTag), '1111');
    });

    test('Listing.rebuild preserves the first published_at value', () {
      final rebuilt = _listing(createdAt: 1111).rebuild(
        title: 'Updated',
        createdAt: 2222,
      );

      expect(rebuilt.createdAt, 2222);
      expect(rebuilt.parsedTags.getTagValue(_publishedAtTag), '1111');
    });

    test('Order.create sets published_at from createdAt', () {
      final order = _order(createdAt: 3333);

      expect(order.parsedTags.getTagValue(_publishedAtTag), '3333');
    });

    test('Order.copy carries published_at into replacement tags', () {
      final copied = _order(createdAt: 3333).copy(
        createdAt: 4444,
        tags: OrderTags([
          [kListingRefTag, _listingAnchor],
          ['d', 'test-order'],
        ]),
      );

      expect(copied.createdAt, 4444);
      expect(copied.parsedTags.getTagValue(_publishedAtTag), '3333');
    });
  });
}
