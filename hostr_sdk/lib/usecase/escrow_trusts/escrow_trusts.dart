import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../auth/auth.dart';
import '../crud.usecase.dart';

@Singleton()
class EscrowTrusts extends CrudUseCase<EscrowTrust> {
  final Auth auth;
  EscrowTrusts({
    required super.requests,
    required super.logger,
    required this.auth,
  }) : super(kind: EscrowTrust.kinds[0]);

  Future<EscrowTrust?> trusted(String pubkey) async {
    return await getOne(Filter(authors: [pubkey]));
  }

  Future<EscrowTrust?> myTrusted() async {
    String pubkey = auth.activeKeyPair!.publicKey;
    return trusted(pubkey);
  }

  /// Ensures the current user's escrow trust list contains the given
  /// [escrowPubkeys]. If no trust list exists or it is missing any of
  /// the pubkeys, publishes an updated list that includes them all.
  Future<void> ensureEscrowTrust(List<String> escrowPubkeys) async {
    if (escrowPubkeys.isEmpty) return;

    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return;

    final pubkey = keyPair.publicKey;
    final existing = await getOne(
      Filter(kinds: EscrowTrust.kinds, authors: [pubkey]),
    );

    final signer = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: pubkey,
    );

    if (existing != null) {
      final nip51 = await existing.toNip51List();
      final existingPubkeys = nip51.elements
          .where((e) => e.tag == 'p')
          .map((e) => e.value)
          .toSet();
      final missing = escrowPubkeys
          .where((pk) => !existingPubkeys.contains(pk))
          .toList();
      if (missing.isEmpty) return;

      // Add missing pubkeys to the existing list and republish
      for (final pk in missing) {
        nip51.addElement('p', pk, false);
      }
      final event = await nip51.toEvent(signer);
      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: keyPair.privateKey!,
        event: event,
      );
      await upsert(EscrowTrust.fromNostrEvent(signed));
    } else {
      // No trust list exists — create one with the bootstrap escrow pubkeys
      final list = Nip51List(
        pubKey: pubkey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: kNostrKindEscrowTrust,
        elements: [],
      );
      for (final pk in escrowPubkeys) {
        list.addElement('p', pk, false);
      }

      final event = await list.toEvent(signer);
      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: keyPair.privateKey!,
        event: event,
      );
      await upsert(EscrowTrust.fromNostrEvent(signed));
    }
    logger.i(
      'Ensured escrow trust for $pubkey with ${escrowPubkeys.length} provider(s)',
    );
  }
}
