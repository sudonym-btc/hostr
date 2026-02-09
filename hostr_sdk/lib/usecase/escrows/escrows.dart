import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../crud.usecase.dart';
import '../escrow_methods/escrows_methods.dart';
import '../escrow_trusts/escrows_trusts.dart';

@Singleton()
class Escrows extends CrudUseCase<EscrowService> {
  EscrowMethods escrowMethods;
  EscrowTrusts escrowTrusts;

  Escrows({
    required super.requests,
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

    final trust1 = results[0] as EscrowTrust;
    final trust2 = results[1] as EscrowTrust;
    final methods1 = results[2] as EscrowMethod;
    final methods2 = results[3] as EscrowMethod;

    final result = MutualEscrowResult(
      hostTrust: trust1,
      guestTrust: trust2,
      hostMethod: methods1,
      guestMethod: methods2,
    );

    // Extract trusted pubkeys from each user's trust list
    final trustedPubkeys1 = (await result.hostTrust.toNip51List()).elements
        .map((e) => e.value)
        .toSet();
    final trustedPubkeys2 = (await result.guestTrust.toNip51List()).elements
        .map((e) => e.value)
        .toSet();

    logger.d('Trusted escrow pubkeys: $trustedPubkeys2 $trustedPubkeys2');

    // Find mutually trusted pubkeys
    final mutuallyTrustedPubkeys = trustedPubkeys1.intersection(
      trustedPubkeys2,
    );

    if (mutuallyTrustedPubkeys.isEmpty) {
      throw Exception(
        'No mutually trusted escrow pubkeys found between $pubkey1 and $pubkey2',
      );
    }

    // Extract escrow types from each user's method list
    final types1 = (await result.hostMethod.toNip51List()).elements
        .map((e) => e.value)
        .toSet();
    final types2 = (await result.guestMethod.toNip51List()).elements
        .map((e) => e.value)
        .toSet();

    logger.d('Trusted escrow methods: $types1 $types2');

    // Find overlapping escrow types
    final overlappingTypes = types1.intersection(types2);

    if (overlappingTypes.isEmpty) {
      throw Exception(
        'No overlapping escrow methods found between $pubkey1 and $pubkey2',
      );
    }

    // Query escrows from mutually trusted pubkeys with overlapping types
    final escrowServices = await list(
      Filter(
        kinds: EscrowService.kinds,
        authors: mutuallyTrustedPubkeys.toList(),
      ),
    );

    final escrowServicesFiltered = escrowServices
        .where(
          (escrow) => overlappingTypes.contains(escrow.parsedContent.type.name),
        )
        .toList();

    result.compatibleServices = escrowServicesFiltered;
    return result;
  }
}

class MutualEscrowResult {
  EscrowTrust hostTrust;
  EscrowTrust guestTrust;
  EscrowMethod hostMethod;
  EscrowMethod guestMethod;
  late List<EscrowService> compatibleServices;

  MutualEscrowResult({
    required this.hostTrust,
    required this.guestTrust,
    required this.hostMethod,
    required this.guestMethod,
  });
}
