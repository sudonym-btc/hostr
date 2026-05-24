import 'package:hostr_cli/src/commands/base.dart';
import 'package:hostr_cli/src/daemon/listing_helpers.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';

void main() {
  group('listing input', () {
    test(
      'builds a listing with multiple images, BTC sats, empty public location, and g tags',
      () {
        final listing = buildListingFromInput(
          pubkey: 'f' * 64,
          input: {
            'title': 'Garden room',
            'description': 'A quiet room',
            'type': 'room',
            'negotiable': true,
            'autoAccept': false,
            'minDuration': 'P2D',
            'guests': 2,
            'beds': 1,
            'bathrooms': 1,
            'maxDisputePeriod': 86400,
            'cancellationPolicy': [
              {
                'secondsBeforeStart': 172800,
                'secondsAfterOrder': 3600,
                'refundFraction': 1.0,
              },
            ],
            'price': {
              'amount': {'value': '100000', 'currency': 'BTC', 'unit': 'sats'},
              'frequency': 'night',
            },
          },
          images: const [
            'https://hostr.network/a.jpg',
            'https://hostr.network/b.jpg',
          ],
          imageMetas: const [
            IMeta(url: 'https://hostr.network/a.jpg'),
            IMeta(url: 'https://hostr.network/b.jpg'),
          ],
          h3Tags: const [
            H3Tag(index: '599685771850416127', resolution: 15),
            H3Tag(index: '594475150812905471', resolution: 8),
          ],
        );

        expect(listing.images, hasLength(2));
        expect(listing.tags.where((tag) => tag.first == 'image').toList(), [
          ['image', 'https://hostr.network/a.jpg'],
          ['image', 'https://hostr.network/b.jpg'],
        ]);
        expect(listing.location, isEmpty);
        expect(listing.tags.where((tag) => tag.first == 'g'), hasLength(2));
        expect(listing.prices.single.amount.denomination, 'BTC');
        expect(listing.prices.single.amount.value, BigInt.from(100000));
        expect(listing.prices.single.frequency, Frequency.daily);
        expect(listing.rentOrBuy, RentOrBuy.rent);
        expect(listing.parsedTags.getTags('M'), ['rent']);
        expect(listing.negotiable, isTrue);
        expect(listing.autoAccept, isFalse);
        expect(listing.minDuration, 'P2D');
        expect(listing.tags, contains(equals(['minDuration', 'P2D'])));
        expect(listing.maxDisputePeriod, 86400);
        expect(
          listing.cancellationPolicy.single.durationBeforeStart,
          const Duration(seconds: 172800),
        );
        expect(
          listing.cancellationPolicy.single.durationAfterOrder,
          const Duration(seconds: 3600),
        );
        expect(listing.cancellationPolicy.single.refundFraction, 1.0);
        expect(listingSummary(listing), containsPair('negotiable', true));
      },
    );

    test('builds fixed-price listings as buy listings', () {
      final listing = buildListingFromInput(
        pubkey: 'f' * 64,
        input: {
          'title': 'Garden room',
          'description': 'A quiet room',
          'type': 'room',
          'price': {
            'amount': {'value': '100000', 'currency': 'BTC', 'unit': 'sats'},
            'frequency': 'fixed',
          },
        },
        images: const ['https://hostr.network/a.jpg'],
        imageMetas: const [IMeta(url: 'https://hostr.network/a.jpg')],
        h3Tags: const [H3Tag(index: '599685771850416127', resolution: 15)],
      );

      expect(listing.prices.single.frequency, isNull);
      expect(listing.rentOrBuy, RentOrBuy.buy);
      expect(listing.parsedTags.getTags('M'), ['buy']);
      expect(listing.tags.where((tag) => tag.first == 'minDuration'), isEmpty);
    });

    test('rejects numeric minDuration input', () {
      expect(
        () => buildListingFromInput(
          pubkey: 'f' * 64,
          input: {
            'title': 'Garden room',
            'description': 'A quiet room',
            'type': 'room',
            'minDuration': 2,
            'price': {
              'amount': {'value': '100000', 'currency': 'BTC', 'unit': 'sats'},
              'frequency': 'night',
            },
          },
          images: const ['https://hostr.network/a.jpg'],
          imageMetas: const [IMeta(url: 'https://hostr.network/a.jpg')],
          h3Tags: const [H3Tag(index: '599685771850416127', resolution: 15)],
        ),
        throwsA(
          isA<HostrCliException>().having(
            (e) => e.code,
            'code',
            'invalid_duration',
          ),
        ),
      );
    });

    test('rejects mixed listing currencies', () {
      expect(
        () => buildListingFromInput(
          pubkey: 'f' * 64,
          input: {
            'title': 'Garden room',
            'description': 'A quiet room',
            'type': 'room',
            'price': {
              'amount': {'value': '100000', 'currency': 'BTC', 'unit': 'sats'},
            },
            'securityDeposit': {'value': '10', 'currency': 'USD'},
          },
          images: const ['https://hostr.network/a.jpg'],
          imageMetas: const [IMeta(url: 'https://hostr.network/a.jpg')],
          h3Tags: const [H3Tag(index: '599685771850416127', resolution: 15)],
        ),
        throwsA(
          isA<HostrCliException>().having(
            (e) => e.code,
            'code',
            'mixed_currencies',
          ),
        ),
      );
    });

    test('rejects cancellation policy without a time condition', () {
      expect(
        () => buildListingFromInput(
          pubkey: 'f' * 64,
          input: {
            'title': 'Garden room',
            'description': 'A quiet room',
            'type': 'room',
            'cancellationPolicy': [
              {'refundFraction': 1.0},
            ],
            'price': {
              'amount': {'value': '100000', 'currency': 'BTC', 'unit': 'sats'},
            },
          },
          images: const ['https://hostr.network/a.jpg'],
          imageMetas: const [IMeta(url: 'https://hostr.network/a.jpg')],
          h3Tags: const [H3Tag(index: '599685771850416127', resolution: 15)],
        ),
        throwsA(
          isA<HostrCliException>().having(
            (e) => e.code,
            'code',
            'invalid_cancellation_policy',
          ),
        ),
      );
    });

    test('requires images', () {
      expect(
        () => buildListingFromInput(
          pubkey: 'f' * 64,
          input: {
            'title': 'Garden room',
            'description': 'A quiet room',
            'type': 'room',
            'price': {
              'amount': {'value': '100000', 'currency': 'BTC', 'unit': 'sats'},
            },
          },
          images: const [],
          imageMetas: const [],
          h3Tags: const [H3Tag(index: '599685771850416127', resolution: 15)],
        ),
        throwsA(
          isA<HostrCliException>().having(
            (e) => e.code,
            'code',
            'images_required',
          ),
        ),
      );
    });
  });
}
