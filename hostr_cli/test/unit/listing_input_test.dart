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
            'guests': 2,
            'beds': 1,
            'bathrooms': 1,
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
