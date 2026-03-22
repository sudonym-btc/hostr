import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event, Nip01Utils, Nip51List;

import '../../config.dart' show CoinlibEventSigner;
import '../auth/auth.dart';
import '../crud.usecase.dart';

@Singleton()
class EscrowMethods extends CrudUseCase<EscrowMethod> {
  final Auth _auth;
  Auth get auth => _auth;

  EscrowMethods({
    required super.requests,
    required super.logger,
    required Auth auth,
  }) : _auth = auth,
       super(kind: EscrowMethod.kinds[0]);

  /// The set of escrow method type names this client natively supports.
  /// Used locally to avoid querying the relay for our own advertised methods.
  static final Set<String> supportedTypes = {EscrowType.EVM.name};

  /// Supported escrow contract families this client can interoperate with.
  static final Set<String> supportedContracts = {'MultiEscrow'};

  /// Returns a locally-built [EscrowMethod] event representing this client's
  /// supported methods and accepted payment forms.
  ///
  /// [acceptedPaymentForms] declares which concrete tokens the user is willing
  /// to receive for each denomination (see `PRICING.md` Layer 2).
  ///
  /// Avoids a relay round-trip when we already know our own capabilities.
  /// Returns null if no key pair is active.
  Future<EscrowMethod?> localMethod({
    List<AcceptedPaymentForm> acceptedPaymentForms = const [],
  }) async {
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return null;

    final pubkey = keyPair.publicKey;
    final signer = CoinlibEventSigner(
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
    for (final contract in supportedContracts) {
      list.addElement('c', contract, false);
    }

    final event = await list.toEvent(signer);

    // Accepted payment form tags are 3-element (`["a", denom, tokenTagId]`)
    // which NIP-51's 2-element addElement cannot represent. Inject them as
    // raw tags before re-signing.
    for (final form in acceptedPaymentForms) {
      event.tags.add(form.toTag());
    }

    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: keyPair.privateKey!,
      event: event,
    );
    return EscrowMethod.fromNostrEvent(signed);
  }

  /// Ensures the current user's escrow method list contains [EscrowType.EVM]
  /// and the given [acceptedPaymentForms].
  ///
  /// If the user has no escrow method list, or it's missing required tags,
  /// publishes an updated list that includes them.
  Future<void> ensureEscrowMethod({
    List<AcceptedPaymentForm> acceptedPaymentForms = const [],
  }) async {
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return;

    final pubkey = keyPair.publicKey;
    final existing = await getOne(
      Filter(kinds: EscrowMethod.kinds, authors: [pubkey]),
    );

    final signer = CoinlibEventSigner(
      privateKey: keyPair.privateKey,
      publicKey: pubkey,
    );

    if (existing != null) {
      final hasEvm = existing.getTags('t').contains(EscrowType.EVM.name);
      final existingContracts = existing.getTags('c').toSet();
      final missingContracts = supportedContracts
          .where((contract) => !existingContracts.contains(contract))
          .toList();
      final existingForms = existing.acceptedPaymentForms.toSet();
      final missingForms = acceptedPaymentForms
          .where((f) => !existingForms.contains(f))
          .toList();

      if (hasEvm && missingContracts.isEmpty && missingForms.isEmpty) return;

      final tags = [
        for (final tag in existing.tags) [...tag],
      ];
      if (!hasEvm) {
        tags.add(['t', EscrowType.EVM.name]);
      }
      for (final contract in missingContracts) {
        tags.add(['c', contract]);
      }
      for (final form in missingForms) {
        tags.add(form.toTag());
      }

      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: keyPair.privateKey!,
        event: Nip01Event(
          pubKey: pubkey,
          kind: kNostrKindEscrowMethod,
          tags: tags,
          content: existing.content,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );

      await upsert(EscrowMethod.fromNostrEvent(signed));
    } else {
      // No escrow method list exists – create one with EVM + accepted forms.
      final list = Nip51List(
        pubKey: pubkey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: kNostrKindEscrowMethod,
        elements: [],
      )..addElement('t', EscrowType.EVM.name, false);

      for (final contract in supportedContracts) {
        list.addElement('c', contract, false);
      }

      final event = await list.toEvent(signer);

      for (final form in acceptedPaymentForms) {
        event.tags.add(form.toTag());
      }

      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: keyPair.privateKey!,
        event: event,
      );
      await upsert(EscrowMethod.fromNostrEvent(signed));
    }
    logger.i('Ensured EVM escrow method for $pubkey');
  }
}
