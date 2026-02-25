import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart'
    show Bip340EventSigner, Filter, Nip01Utils, Nip51List;

import '../auth/auth.dart';
import '../crud.usecase.dart';

@Singleton()
class EscrowMethods extends CrudUseCase<EscrowMethod> {
  final Auth auth;

  EscrowMethods({
    required super.requests,
    required super.logger,
    required this.auth,
  }) : super(kind: EscrowMethod.kinds[0]);

  /// The set of escrow method type names this client natively supports.
  /// Used locally to avoid querying the relay for our own advertised methods.
  static final Set<String> supportedTypes = {EscrowType.EVM.name};

  /// Returns a locally-built [EscrowMethod] event representing this client's
  /// supported methods. Avoids a relay round-trip when we already know our own
  /// capabilities. Returns null if no key pair is active.
  Future<EscrowMethod?> localMethod() async {
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return null;

    final pubkey = keyPair.publicKey;
    final signer = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: pubkey,
    );

    final list = Nip51List(
      pubKey: pubkey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: kNostrKindEscrowMethod,
      elements: [],
    );
    for (final type in supportedTypes) {
      list.addElement('t', type, false);
    }

    final event = await list.toEvent(signer);
    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: keyPair.privateKey!,
      event: event,
    );
    return EscrowMethod.fromNostrEvent(signed);
  }

  /// Ensures the current user's escrow method list contains [EscrowType.EVM].
  /// If the user has no escrow method list or it's missing EVM, publishes an
  /// updated list that includes it.
  Future<void> ensureEscrowMethod() async {
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return;

    final pubkey = keyPair.publicKey;
    final existing = await getOne(
      Filter(kinds: EscrowMethod.kinds, authors: [pubkey]),
    );

    final signer = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: pubkey,
    );

    if (existing != null) {
      final nip51 = await existing.toNip51List();
      final hasEvm = nip51.elements.any(
        (e) => e.tag == 't' && e.value == EscrowType.EVM.name,
      );
      if (hasEvm) return;

      // Add EVM to the existing list and republish
      nip51.addElement('t', EscrowType.EVM.name, false);
      final event = await nip51.toEvent(signer);
      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: keyPair.privateKey!,
        event: event,
      );
      await upsert(EscrowMethod.fromNostrEvent(signed));
    } else {
      // No escrow method list exists – create one with EVM
      final list = Nip51List(
        pubKey: pubkey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: kNostrKindEscrowMethod,
        elements: [],
      )..addElement('t', EscrowType.EVM.name, false);

      final event = await list.toEvent(signer);
      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: keyPair.privateKey!,
        event: event,
      );
      await upsert(EscrowMethod.fromNostrEvent(signed));
    }
    logger.i('Ensured EVM escrow method for $pubkey');
  }
}
