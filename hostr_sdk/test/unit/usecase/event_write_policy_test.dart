import 'package:hostr_sdk/usecase/event_write_policy.dart';
import 'package:test/test.dart';

void main() {
  group('nextUpsertCreatedAt', () {
    test('advances replacement events beyond the previous timestamp', () {
      expect(
        nextUpsertCreatedAt(
          1000,
          now: DateTime.fromMillisecondsSinceEpoch(1000000),
        ),
        1001,
      );
      expect(
        nextUpsertCreatedAt(
          1000,
          now: DateTime.fromMillisecondsSinceEpoch(2000000),
        ),
        2000,
      );
    });
  });
}
