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
              kAcceptedPaymentFormTag,
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
              kAcceptedPaymentFormTag,
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

    test('builds a generic EVM address ownership message', () {
      final message = evmAddressOwnershipMessage(
        nostrPubkey: pubkey,
        evmAddress: '0x1111111111111111111111111111111111111111',
      );

      expect(message, isNot(contains('Hostr')));
      expect(
        message,
        [
          'EVM address ownership proof',
          'nostr:$pubkey',
          'evm:address:0x1111111111111111111111111111111111111111',
        ].join('\n'),
      );
    });

    test('parses embedded EVM address claims', () {
      final method = EscrowMethod.fromNostrEvent(
        Nip01Event(
          pubKey: 'pubkey',
          kind: kNostrKindEscrowMethod,
          tags: const [
            ['i', 'github:alice', 'proof'],
            [
              'i',
              'evm:address:0x1111111111111111111111111111111111111111',
              'eip191:0xsig',
            ],
          ],
          content: '',
        ),
      );

      expect(
        method.evmAddress,
        '0x1111111111111111111111111111111111111111',
      );
      expect(method.evmAddressProof, '0xsig');
    });

    test('replaces only prior EVM address claims', () {
      final method = EscrowMethod.fromNostrEvent(
        Nip01Event(
          pubKey: 'pubkey',
          kind: kNostrKindEscrowMethod,
          tags: const [
            ['i', 'github:alice', 'proof'],
            ['i', 'evm:address:0xold', 'eip191:0xoldproof'],
          ],
          content: '',
        ),
      ).withEvmAddress('0xnew', eip191Proof: '0xnewproof');

      expect(
        method.tags,
        contains(predicate<List<String>>((tag) {
          return tag.length == 3 &&
              tag[0] == 'i' &&
              tag[1] == 'github:alice' &&
              tag[2] == 'proof';
        })),
      );
      expect(
        method.tags,
        isNot(contains(predicate<List<String>>((tag) {
          return tag.length >= 2 && tag[1] == 'evm:address:0xold';
        }))),
      );
      expect(
        method.tags,
        contains(predicate<List<String>>((tag) {
          return tag.length == 3 &&
              tag[0] == 'i' &&
              tag[1] == 'evm:address:0xnew' &&
              tag[2] == 'eip191:0xnewproof';
        })),
      );
    });
  });
}
