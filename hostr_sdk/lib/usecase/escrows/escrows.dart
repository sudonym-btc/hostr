import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../crud.usecase.dart';
import '../escrow_methods/escrows_methods.dart';

@Singleton()
class Escrows extends CrudUseCase<EscrowService> {
  EscrowMethods escrowMethods;

  Escrows({
    required super.requests,
    required super.logger,
    required this.escrowMethods,
  }) : super(kind: EscrowService.kinds[0]);

  Future<MutualEscrowResult> determineMutualEscrow(
    String buyerPubkey,
    String sellerPubkey,
  ) => logger.span('determineMutualEscrow', () async {
    // Query both users' escrow-method events. Trust, contract literacy, and
    // token acceptance all live on the same kind:30301 event now.
    final results = await Future.wait([
      escrowMethods.getOne(
        Filter(kinds: EscrowMethod.kinds, authors: [buyerPubkey]),
      ),
      escrowMethods.getOne(
        Filter(kinds: EscrowMethod.kinds, authors: [sellerPubkey]),
      ),
    ]);
    final buyerMethod = results[0];
    final sellerMethod = results[1];
    logger.d('Buyer($buyerPubkey) escrow method: $buyerMethod');
    logger.d('Seller($sellerPubkey) escrow method: $sellerMethod');
    final result = MutualEscrowResult(
      sellerMethod: sellerMethod,
      buyerMethod: buyerMethod,
    );

    final trustedBuyerPubkeys =
        buyerMethod?.trustedEscrowPubkeys.toSet() ?? <String>{};
    final trustedSellerPubkeys =
        sellerMethod?.trustedEscrowPubkeys.toSet() ?? <String>{};

    logger.d(
      'Trusted escrow pubkeys: buyer=$trustedBuyerPubkeys seller=$trustedSellerPubkeys',
    );

    // Find mutually trusted pubkeys
    final mutuallyTrustedPubkeys = trustedBuyerPubkeys.intersection(
      trustedSellerPubkeys,
    );

    // if (mutuallyTrustedPubkeys.isEmpty) {
    //   throw Exception(
    //     'No mutually trusted escrow pubkeys found between $pubkey1 and $pubkey2',
    //   );
    // }

    final mutualBytecodeHashes =
        (buyerMethod?.supportedContractBytecodeHashes.toSet() ?? <String>{})
            .intersection(
              sellerMethod?.supportedContractBytecodeHashes.toSet() ??
                  <String>{},
            );

    logger.d('Trusted escrow bytecode hashes: $mutualBytecodeHashes');

    if (mutualBytecodeHashes.isEmpty) {
      result.compatibleServices = [];
      return result;
    }

    // Try mutually trusted escrow providers first
    if (mutuallyTrustedPubkeys.isNotEmpty) {
      final escrowServices = await list(
        Filter(
          kinds: EscrowService.kinds,
          authors: mutuallyTrustedPubkeys.toList(),
        ),
      );

      final escrowServicesFiltered = escrowServices
          .where(
            (escrow) =>
                mutualBytecodeHashes.contains(escrow.contractBytecodeHash),
          )
          .toList();

      if (escrowServicesFiltered.isNotEmpty) {
        result.compatibleServices = escrowServicesFiltered;
        return result;
      }
    }

    // Fall back to the seller's trusted escrows with a compatible method
    if (trustedSellerPubkeys.isNotEmpty) {
      final hostEscrowServices = await list(
        Filter(
          kinds: EscrowService.kinds,
          authors: trustedSellerPubkeys.toList(),
        ),
      );

      final hostEscrowServicesFiltered = hostEscrowServices
          .where(
            (escrow) =>
                mutualBytecodeHashes.contains(escrow.contractBytecodeHash),
          )
          .toList();

      result.compatibleServices = hostEscrowServicesFiltered;
      return result;
    }

    result.compatibleServices = [];
    return result;
  });
}

class MutualEscrowResult {
  EscrowMethod? sellerMethod;
  EscrowMethod? buyerMethod;
  late List<EscrowService> compatibleServices;

  MutualEscrowResult({required this.sellerMethod, required this.buyerMethod});
}
