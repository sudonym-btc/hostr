import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../crud.usecase.dart';
import '../escrow_methods/escrows_methods.dart';
import '../escrow_trusts/escrow_trusts.dart';

@Singleton()
class Escrows extends CrudUseCase<EscrowService> {
  EscrowMethods escrowMethods;
  EscrowTrusts escrowTrusts;

  Escrows({
    required super.requests,
    required super.logger,
    required this.escrowMethods,
    required this.escrowTrusts,
  }) : super(kind: EscrowService.kinds[0]);

  Future<MutualEscrowResult> determineMutualEscrow(
    String buyerPubkey,
    String sellerPubkey,
  ) async {
    final myPubkey = escrowMethods.auth.activeKeyPair?.publicKey;
    final counterpartyPubkey = buyerPubkey == myPubkey
        ? sellerPubkey
        : buyerPubkey;
    // Query trust lists for both users and escrow method only for the
    // counterparty. We already know our own supported methods locally.
    final results = await Future.wait([
      escrowTrusts.getOne(
        Filter(kinds: EscrowTrust.kinds, authors: [buyerPubkey]),
      ),
      escrowTrusts.getOne(
        Filter(kinds: EscrowTrust.kinds, authors: [sellerPubkey]),
      ),
      escrowMethods.getOne(
        Filter(kinds: EscrowMethod.kinds, authors: [counterpartyPubkey]),
      ),
    ]);
    final buyerTrust = results[0] as EscrowTrust?;
    final sellerTrust = results[1] as EscrowTrust?;
    final counterpartyMethod = results[2] as EscrowMethod?;

    final result = MutualEscrowResult(
      sellerTrust: sellerTrust,
      buyerTrust: buyerTrust,
      sellerMethod: sellerPubkey == myPubkey ? null : counterpartyMethod,
      buyerMethod: buyerPubkey == myPubkey ? null : counterpartyMethod,
    );

    // Extract trusted pubkeys from each user's trust list
    final trustedBuyerPubkeys = result.buyerTrust != null
        ? (await result.buyerTrust!.toNip51List()).elements
              .map((e) => e.value)
              .toSet()
        : <String>{};
    final trustedSellerPubkeys = result.sellerTrust != null
        ? (await result.sellerTrust!.toNip51List()).elements
              .map((e) => e.value)
              .toSet()
        : <String>{};

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

    // Extract escrow types. Use the hardcoded supportedTypes for our own
    // user and only parse the counterparty's advertised methods from the relay.
    final myTypes = EscrowMethods.supportedTypes;
    final counterpartyTypes = counterpartyMethod != null
        ? (await counterpartyMethod.toNip51List()).elements
              .map((e) => e.value)
              .toSet()
        : <String>{};

    final types1 = buyerPubkey == myPubkey ? myTypes : counterpartyTypes;
    final types2 = sellerPubkey == myPubkey ? myTypes : counterpartyTypes;

    logger.d('Trusted escrow methods: $types1 $types2');

    // Find overlapping escrow types
    final overlappingTypes = types1.intersection(types2);

    if (overlappingTypes.isEmpty) {
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
                overlappingTypes.contains(escrow.parsedContent.type.name),
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
                overlappingTypes.contains(escrow.parsedContent.type.name),
          )
          .toList();

      result.compatibleServices = hostEscrowServicesFiltered;
      return result;
    }

    result.compatibleServices = [];
    return result;
  }
}

class MutualEscrowResult {
  EscrowTrust? sellerTrust;
  EscrowTrust? buyerTrust;
  EscrowMethod? sellerMethod;
  EscrowMethod? buyerMethod;
  late List<EscrowService> compatibleServices;

  MutualEscrowResult({
    required this.sellerTrust,
    required this.buyerTrust,
    required this.sellerMethod,
    required this.buyerMethod,
  });
}
