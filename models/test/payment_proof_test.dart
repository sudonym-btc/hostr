import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentProof', () {
    test('serializes EVM tx hash under generic payment proof params', () {
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
      final listing = Listing.fromNostrEvent(
        Nip01EventModel.fromJson({
          'id': '',
          'pubkey': MockKeys.hoster.publicKey,
          'created_at': 0,
          'kind': kNostrKindListing,
          'tags': const [
            ['d', 'listing'],
          ],
          'content': '{}',
          'sig': '',
        }),
      );
      final proof = PaymentProof(
        listing: listing,
        paymentProof: const PaymentProofEvidence(
          method: PaymentMethod.evm,
          params: EvmPaymentProofParams(txHash: '0xabc123'),
        ),
        escrow: EscrowPaymentContext(
          escrowService: service,
          sellerEscrowMethod: method,
        ),
      );

      final json = proof.toJson();

      expect(json.containsKey('txHash'), isFalse);
      expect(json.containsKey('zapProof'), isFalse);
      expect(json.containsKey('escrowProof'), isFalse);
      expect(json['paymentProof'], {
        'method': 'evm',
        'params': {'txHash': '0xabc123'},
      });
      expect(json['escrow']['sellerEscrowMethod'], isA<String>());

      final roundTrip = PaymentProof.fromJson(json);
      final params = roundTrip.paymentProof!.params as EvmPaymentProofParams;
      expect(roundTrip.paymentProof!.method, PaymentMethod.evm);
      expect(params.txHash, '0xabc123');
      expect(roundTrip.escrow!.escrowService.contractAddress,
          service.contractAddress);
      expect(roundTrip.escrow!.sellerEscrowMethod.pubKey, method.pubKey);
    });
  });
}
