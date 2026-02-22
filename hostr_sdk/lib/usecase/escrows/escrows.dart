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
    String pubkey1,
    String pubkey2,
  ) async {
    // Get EscrowTrust and EscrowMethod for both pubkeys simultaneously
    final results = await Future.wait([
      escrowTrusts.getOne(Filter(kinds: EscrowTrust.kinds, authors: [pubkey1])),
      escrowTrusts.getOne(Filter(kinds: EscrowTrust.kinds, authors: [pubkey2])),
      escrowMethods.getOne(
        Filter(kinds: EscrowMethod.kinds, authors: [pubkey1]),
      ),
      escrowMethods.getOne(
        Filter(kinds: EscrowMethod.kinds, authors: [pubkey2]),
      ),
    ]);

    final trust1 = results[0] as EscrowTrust?;
    final trust2 = results[1] as EscrowTrust?;
    final methods1 = results[2] as EscrowMethod?;
    final methods2 = results[3] as EscrowMethod?;

    // if (trust1 == null) {
    //   throw Exception('Host escrow trust list is missing');
    // }
    // if (trust2 == null) {
    //   throw Exception('Guest escrow trust list is missing');
    // }
    // if (methods1 == null) {
    //   throw Exception('Host escrow methods are missing');
    // }
    // if (methods2 == null) {
    //   throw Exception('Guest escrow methods are missing');
    // }

    final result = MutualEscrowResult(
      sellerTrust: trust1,
      buyerTrust: trust2,
      sellerMethod: methods1,
      buyerMethod: methods2,
    );

    // Extract trusted pubkeys from each user's trust list
    final trustedPubkeys1 = result.sellerTrust != null
        ? (await result.sellerTrust!.toNip51List()).elements
              .map((e) => e.value)
              .toSet()
        : <String>{};
    final trustedPubkeys2 = result.buyerTrust != null
        ? (await result.buyerTrust!.toNip51List()).elements
              .map((e) => e.value)
              .toSet()
        : <String>{};

    logger.d('Trusted escrow pubkeys: $trustedPubkeys2 $trustedPubkeys2');

    // Find mutually trusted pubkeys
    final mutuallyTrustedPubkeys = trustedPubkeys1.intersection(
      trustedPubkeys2,
    );

    // if (mutuallyTrustedPubkeys.isEmpty) {
    //   throw Exception(
    //     'No mutually trusted escrow pubkeys found between $pubkey1 and $pubkey2',
    //   );
    // }

    // Extract escrow types from each user's method list
    final types1 = result.sellerMethod != null
        ? (await result.sellerMethod!.toNip51List()).elements
              .map((e) => e.value)
              .toSet()
        : <String>{};
    final types2 = result.buyerMethod != null
        ? (await result.buyerMethod!.toNip51List()).elements
              .map((e) => e.value)
              .toSet()
        : <String>{};

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

    // Fall back to the host's trusted escrows with a compatible method
    if (trustedPubkeys2.isNotEmpty) {
      final hostEscrowServices = await list(
        Filter(kinds: EscrowService.kinds, authors: trustedPubkeys2.toList()),
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
