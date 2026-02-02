import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../escrow_methods/escrows_methods.dart';
import '../escrow_trusts/escrows_trusts.dart';

@Singleton()
class Escrows extends CrudUseCase<Escrow> {
  EscrowMethods escrowMethods;
  EscrowTrusts escrowTrusts;

  Escrows({
    required super.requests,
    required this.escrowMethods,
    required this.escrowTrusts,
  }) : super(kind: Escrow.kinds[0]);

  Future<List<Escrow>> determineMutualEscrow(
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

    final trust1 = results[0];
    final trust2 = results[1];
    final methods1 = results[2];
    final methods2 = results[3];

    // Extract trusted pubkeys from each user's trust list
    final trustedPubkeys1 = (await (trust1 as EscrowTrust).toNip51List())
        .elements
        .map((e) => e.value)
        .toSet();
    final trustedPubkeys2 = (await (trust2 as EscrowTrust).toNip51List())
        .elements
        .map((e) => e.value)
        .toSet();

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
    final types1 = (await (methods1 as EscrowMethod).toNip51List()).elements
        .map((e) => e.value)
        .toSet();
    final types2 = (await (methods2 as EscrowMethod).toNip51List()).elements
        .map((e) => e.value)
        .toSet();
    // Find overlapping escrow types
    final overlappingTypes = types1.intersection(types2);

    if (overlappingTypes.isEmpty) {
      throw Exception(
        'No overlapping escrow methods found between $pubkey1 and $pubkey2',
      );
    }

    // Query escrows from mutually trusted pubkeys with overlapping types
    final escrows = await list(
      Filter(kinds: Escrow.kinds, authors: mutuallyTrustedPubkeys.toList()),
    );

    return escrows
        .where(
          (escrow) =>
              overlappingTypes.contains(escrow.parsedContent.type.toString()),
        )
        .toList();
  }
}
