import 'package:models/main.dart';
import 'package:test/test.dart';

void main() {
  group('EventTags', () {
    test('getTags skips malformed tag entries', () {
      final tags = EventTags([
        ['a'],
        ['a', '32121:pubkey:listing'],
        [],
      ]);

      expect(tags.getTags('a'), ['32121:pubkey:listing']);
    });

    test('hasRequiredTags matches full required tag patterns', () {
      expect(
        hasRequiredTags(
          [
            ['a', '32121:pubkey:listing'],
          ],
          [
            ['a', 'other-anchor'],
          ],
        ),
        isFalse,
      );
      expect(
        hasRequiredTags(
          [
            ['a', '32121:pubkey:listing'],
          ],
          [
            ['a', '32121:pubkey:listing'],
          ],
        ),
        isTrue,
      );
    });
  });

  group('ReferencesListing', () {
    test('listingAnchorOrNull returns null when missing', () {
      final tags = ReservationTags([]);

      expect(tags.listingAnchorOrNull, isNull);
    });

    test('listingAnchor throws a clear error when missing', () {
      final tags = ReservationTags([]);

      expect(
        () => tags.listingAnchor,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Missing listing reference tag'),
          ),
        ),
      );
    });
  });
}
