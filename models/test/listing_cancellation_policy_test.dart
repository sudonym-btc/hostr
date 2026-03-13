import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

void main() {
  group('Listing cancellation policies', () {
    test('creates and parses cancellationPolicy tags', () {
      final listing = Listing.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'listing-cancellation-policy',
        title: 'Listing with policy',
        description: 'Fixture',
        images: const [],
        price: [
          Price(
            amount: Amount(currency: Currency.BTC, value: BigInt.from(1000)),
            frequency: Frequency.daily,
          ),
        ],
        location: 'Test',
        type: ListingType.house,
        amenities: Amenities(),
        cancellationPolicy: const [
          CancellationPolicy(
            durationBeforeStart: Duration(days: 14),
            refundFraction: 0.5,
          ),
          CancellationPolicy(
            durationBeforeStart: Duration(days: 7),
            refundFraction: 0.1,
          ),
        ],
      ).signAs(MockKeys.hoster, Listing.fromNostrEvent);

      final parsed = parser<Listing>(listing);

      expect(
        parsed.tags.where((tag) => tag[0] == 'cancellationPolicy'),
        [
          ['cancellationPolicy', '${Duration(days: 14).inSeconds}', '0.5'],
          ['cancellationPolicy', '${Duration(days: 7).inSeconds}', '0.1'],
        ],
      );
      expect(parsed.cancellationPolicy, const [
        CancellationPolicy(
          durationBeforeStart: Duration(days: 14),
          refundFraction: 0.5,
        ),
        CancellationPolicy(
          durationBeforeStart: Duration(days: 7),
          refundFraction: 0.1,
        ),
      ]);
    });
  });
}
