import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('EscrowProof', () {
    test('serializes EVM tx hash under service-specific params', () {
      final service = MOCK_ESCROWS(
        contractAddress: '0x000000000000000000000000000000000000dEaD',
        evmAddress: '0x000000000000000000000000000000000000bEEF',
      ).first;
      final method = EscrowMethod.fromNostrEvent(
        Nip01EventModel.fromJson({
          'id': '',
          'pubkey': MockKeys.hoster.publicKey,
          'created_at': 0,
          'kind': kNostrKindEscrowMethod,
          'tags': [
            ['c', service.contractBytecodeHash],
            ['p', service.pubKey],
          ],
          'content': '',
          'sig': '',
        }),
      );
      final proof = EscrowProof(
        escrowService: service,
        sellerEscrowMethods: method,
        params: const EvmEscrowProofParams(txHash: '0xabc123'),
      );

      final json = proof.toJson();

      expect(json.containsKey('txHash'), isFalse);
      expect(json.containsKey('hostsEscrowMethods'), isFalse);
      expect(json['params'], {'txHash': '0xabc123'});
      expect(json['sellerEscrowMethods'], isA<String>());

      final roundTrip = EscrowProof.fromJson(json);
      expect(roundTrip.txHash, '0xabc123');
      expect(roundTrip.params, isA<EvmEscrowProofParams>());
      expect(roundTrip.escrowService.contractAddress, service.contractAddress);
      expect(roundTrip.sellerEscrowMethods.pubKey, method.pubKey);
    });
  });
}
