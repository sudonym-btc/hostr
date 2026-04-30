import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('EscrowMethod', () {
    final pubkey = List.filled(64, '0').join();

    test('matches EVM token tag IDs case-insensitively', () {
      final method = EscrowMethod.fromNostrEvent(
        Nip01EventModel.fromJson({
          'id': '',
          'pubkey': pubkey,
          'created_at': 0,
          'kind': kNostrKindEscrowMethod,
          'tags': [
            [
              'a',
              'USD',
              '412346:0x712516e61c8b383df4a63cfe83d7701bce54b03e',
            ],
          ],
          'content': '',
          'sig': '',
        }),
      );

      expect(
        method.acceptsToken(
          'USD',
          '412346:0x712516e61C8B383dF4A63CFe83d7701Bce54B03e',
        ),
        isTrue,
      );
    });

    test('keeps denominations case-sensitive', () {
      final method = EscrowMethod.fromNostrEvent(
        Nip01EventModel.fromJson({
          'id': '',
          'pubkey': pubkey,
          'created_at': 0,
          'kind': kNostrKindEscrowMethod,
          'tags': [
            [
              'a',
              'USD',
              '412346:0x712516e61c8b383df4a63cfe83d7701bce54b03e',
            ],
          ],
          'content': '',
          'sig': '',
        }),
      );

      expect(
        method.acceptsToken(
          'usd',
          '412346:0x712516e61c8b383df4a63cfe83d7701bce54b03e',
        ),
        isFalse,
      );
    });
  });
}
