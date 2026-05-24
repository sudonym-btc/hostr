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
            amount: DenominatedAmount(
              value: BigInt.from(1000),
              denomination: 'BTC',
              decimals: 8,
            ),
            frequency: Frequency.daily,
          ),
        ],
        location: 'Test',
        type: ListingType.house,
        specifications: Specifications(),
        cancellationPolicy: const [
          CancellationPolicy(
            durationBeforeStart: Duration(days: 14),
            refundFraction: 0.5,
          ),
          CancellationPolicy(
            durationAfterOrder: Duration(hours: 1),
            refundFraction: 1.0,
          ),
          CancellationPolicy(
            durationBeforeStart: Duration(days: 7),
            durationAfterOrder: Duration(minutes: 30),
            refundFraction: 0.1,
          ),
        ],
      ).signAs(MockKeys.hoster, Listing.fromNostrEvent);

      final parsed = parser<Listing>(listing);

      expect(
        parsed.tags.where((tag) => tag[0] == 'cancellationPolicy'),
        [
          [
            'cancellationPolicy',
            'refundFraction',
            '0.5',
            'secondsBeforeStart',
            '${Duration(days: 14).inSeconds}',
          ],
          [
            'cancellationPolicy',
            'refundFraction',
            '1.0',
            'secondsAfterOrder',
            '${Duration(hours: 1).inSeconds}',
          ],
          [
            'cancellationPolicy',
            'refundFraction',
            '0.1',
            'secondsBeforeStart',
            '${Duration(days: 7).inSeconds}',
            'secondsAfterOrder',
            '${Duration(minutes: 30).inSeconds}',
          ],
        ],
      );
      expect(parsed.cancellationPolicy, const [
        CancellationPolicy(
          durationBeforeStart: Duration(days: 14),
          refundFraction: 0.5,
        ),
        CancellationPolicy(
          durationAfterOrder: Duration(hours: 1),
          refundFraction: 1.0,
        ),
        CancellationPolicy(
          durationBeforeStart: Duration(days: 7),
          durationAfterOrder: Duration(minutes: 30),
          refundFraction: 0.1,
        ),
      ]);
    });
  });
}
