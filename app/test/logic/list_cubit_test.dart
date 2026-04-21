import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/logic/cubit/list/list.cubit.dart';
import 'package:models/main.dart';

Listing _listing({
  required String pubKey,
  required String dTag,
  required int createdAt,
  required String title,
}) {
  return Listing.create(
    pubKey: pubKey,
    dTag: dTag,
    title: title,
    description: '',
    images: const [],
    price: const [],
    location: '',
    type: ListingType.room,
    specifications: Specifications(),
    createdAt: createdAt,
  );
}

void main() {
  group('upsertNostrListItem', () {
    test('replaces addressable events by kind pubkey and d tag', () {
      final original = _listing(
        pubKey: 'host-pubkey',
        dTag: 'listing-1',
        createdAt: 10,
        title: 'Old title',
      );
      final updated = _listing(
        pubKey: 'host-pubkey',
        dTag: 'listing-1',
        createdAt: 11,
        title: 'New title',
      );

      final result = upsertNostrListItem([original], updated);

      expect(result, hasLength(1));
      expect(result.single.title, 'New title');
    });

    test(
      'keeps the newest addressable event when an older copy arrives later',
      () {
        final updated = _listing(
          pubKey: 'host-pubkey',
          dTag: 'listing-1',
          createdAt: 11,
          title: 'New title',
        );
        final original = _listing(
          pubKey: 'host-pubkey',
          dTag: 'listing-1',
          createdAt: 10,
          title: 'Old title',
        );

        final result = upsertNostrListItem([updated], original);

        expect(result, hasLength(1));
        expect(result.single.title, 'New title');
      },
    );

    test('keeps same d tag from different authors as different events', () {
      final firstHost = _listing(
        pubKey: 'host-1',
        dTag: 'listing-1',
        createdAt: 10,
        title: 'First host',
      );
      final secondHost = _listing(
        pubKey: 'host-2',
        dTag: 'listing-1',
        createdAt: 11,
        title: 'Second host',
      );

      final result = upsertNostrListItem([firstHost], secondHost);

      expect(result, hasLength(2));
      expect(result.map((listing) => listing.title), [
        'First host',
        'Second host',
      ]);
    });
  });
}
