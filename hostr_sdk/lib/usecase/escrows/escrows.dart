import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../crud.usecase.dart';
import '../escrow_methods/escrows_methods.dart';

@Singleton()
class Escrows extends CrudUseCase<EscrowService> {
  final EscrowMethods _escrowMethods;

  Escrows({
    required super.requests,
    required super.logger,
    required EscrowMethods escrowMethods,
  }) : _escrowMethods = escrowMethods,
       super(kind: EscrowService.kinds[0]);

  Future<MutualEscrowResult> determineMutualEscrow(
    String buyerPubkey,
    String sellerPubkey,
  ) => logger.span('determineMutualEscrow', () async {
    // Query both users' escrow-method events. Trust, contract literacy, and
    // token acceptance all live on the same escrow method event now.
    final results = await Future.wait([
      _escrowMethods.getOne(
        Filter(kinds: EscrowMethod.kinds, authors: [buyerPubkey]),
        cacheRead: false,
      ),
      _escrowMethods.getOne(
        Filter(kinds: EscrowMethod.kinds, authors: [sellerPubkey]),
        cacheRead: false,
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

    final trustedSellerPubkeys =
        sellerMethod?.trustedEscrowPubkeys.toSet() ?? <String>{};
    final trustedBuyerPubkeys =
        buyerMethod?.trustedEscrowPubkeys.toSet() ?? <String>{};

    logger.d(
      'Trusted escrow pubkeys: buyer=$trustedBuyerPubkeys seller=$trustedSellerPubkeys',
    );

    final sellerBytecodeHashes =
        sellerMethod?.supportedContractBytecodeHashes.toSet() ?? <String>{};
    final buyerBytecodeHashes =
        buyerMethod?.supportedContractBytecodeHashes.toSet() ?? <String>{};
    final buyerHasEscrowPreference =
        trustedBuyerPubkeys.isNotEmpty || buyerBytecodeHashes.isNotEmpty;
    final preferredPubkeys = buyerHasEscrowPreference
        ? trustedBuyerPubkeys.intersection(trustedSellerPubkeys)
        : trustedSellerPubkeys;
    final preferredBytecodeHashes = buyerHasEscrowPreference
        ? buyerBytecodeHashes.intersection(sellerBytecodeHashes)
        : sellerBytecodeHashes;

    logger.d('Preferred escrow bytecode hashes: $preferredBytecodeHashes');

    // Try the buyer/seller overlap first. If the buyer has no escrow method,
    // or has a stale/incompatible one, a missing buyer match must not make the
    // host's escrow preference unusable.
    if (preferredPubkeys.isNotEmpty && preferredBytecodeHashes.isNotEmpty) {
      final preferredServices = await _findServices(
        authors: preferredPubkeys,
        bytecodeHashes: preferredBytecodeHashes,
      );

      if (preferredServices.isNotEmpty) {
        result.compatibleServices = preferredServices;
        return result;
      }
    }

    logger.d(
      'No compatible buyer/seller escrow preference found; falling back to seller preference',
    );

    if (trustedSellerPubkeys.isNotEmpty && sellerBytecodeHashes.isNotEmpty) {
      result.compatibleServices = await _findServices(
        authors: trustedSellerPubkeys,
        bytecodeHashes: sellerBytecodeHashes,
      );
      return result;
    }

    result.compatibleServices = [];
    return result;
  });

  Future<List<EscrowService>> _findServices({
    required Set<String> authors,
    required Set<String> bytecodeHashes,
  }) async {
    final escrowServices = await list(
      Filter(kinds: EscrowService.kinds, authors: authors.toList()),
    );

    return escrowServices
        .where((escrow) => bytecodeHashes.contains(escrow.contractBytecodeHash))
        .toList();
  }
}

class MutualEscrowResult {
  EscrowMethod? sellerMethod;
  EscrowMethod? buyerMethod;
  late List<EscrowService> compatibleServices;

  MutualEscrowResult({required this.sellerMethod, required this.buyerMethod});
}
