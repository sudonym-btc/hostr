import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityClaims', () {
    test('parses chain-agnostic EVM address claims', () {
      final event = IdentityClaims.fromNostrEvent(
        Nip01Event(
          pubKey: 'pubkey',
          kind: kNostrKindIdentityClaims,
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
        event.evmAddress,
        '0x1111111111111111111111111111111111111111',
      );
      expect(event.evmAddressProof, '0xsig');
    });

    test('replaces only prior EVM address claims', () {
      final event = IdentityClaims.fromNostrEvent(
        Nip01Event(
          pubKey: 'pubkey',
          kind: kNostrKindIdentityClaims,
          tags: const [
            ['i', 'github:alice', 'proof'],
            ['i', 'evm:address:0xold', 'eip191:0xoldproof'],
          ],
          content: '',
        ),
      ).withEvmAddress('0xnew', eip191Proof: '0xnewproof');

      expect(
        event.tags,
        contains(predicate<List<String>>((tag) {
          return tag.length == 3 &&
              tag[0] == 'i' &&
              tag[1] == 'github:alice' &&
              tag[2] == 'proof';
        })),
      );
      expect(
        event.tags,
        isNot(contains(predicate<List<String>>((tag) {
          return tag.length >= 2 && tag[1] == 'evm:address:0xold';
        }))),
      );
      expect(
        event.tags,
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
