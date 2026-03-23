import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event, Nip01Utils, Nip51List;

import '../../config.dart' show CoinlibEventSigner, HostrConfig;
import '../auth/auth.dart';
import '../crud.usecase.dart';
import '../escrow/supported_escrow_contract/supported_bytecodes.dart';

@Singleton()
class EscrowMethods extends CrudUseCase<EscrowMethod> {
  final Auth _auth;
  final HostrConfig _config;
  Auth get auth => _auth;

  EscrowMethods({
    required super.requests,
    required super.logger,
    required Auth auth,
    required HostrConfig config,
  }) : _auth = auth,
       _config = config,
       super(kind: EscrowMethod.kinds[0]);

  /// The bytecode hashes of escrow contracts this client natively supports.
  ///
  /// The contract identity is the runtime bytecode hash, not a human name.
  Set<String> get supportedContractBytecodeHashes =>
      supportedEscrowBytecodeHashes.keys.toSet();

  Future<EscrowMethod?> myMethod() async {
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return null;
    return getOne(
      Filter(kinds: EscrowMethod.kinds, authors: [keyPair.publicKey]),
    );
  }

  /// Returns a locally-built [EscrowMethod] event representing this client's
  /// trusted escrows, supported contract bytecodes, and accepted payment forms.
  ///
  /// [acceptedPaymentForms] declares which concrete tokens the user is willing
  /// to receive for each denomination (see `PRICING.md` Layer 2).
  ///
  /// Avoids a relay round-trip when we already know our own capabilities.
  /// Returns null if no key pair is active.
  Future<EscrowMethod?> localMethod({
    List<String> trustedEscrowPubkeys = const [],
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
    for (final pubkey in trustedEscrowPubkeys) {
      list.addElement('p', pubkey, false);
    }
    for (final bytecodeHash in supportedContractBytecodeHashes) {
      list.addElement('c', bytecodeHash, false);
    }

    final listEvent = await list.toEvent(signer);

    // Build the complete tag list before creating the event so the
    // auto-computed id covers every tag.  Mutating tags on an existing
    // Nip01Event leaves the id stale because it is `late final` and
    // Nip01Utils.signWithPrivateKey does not recalculate it.
    final completeTags = [
      ...listEvent.tags,
      for (final form in acceptedPaymentForms) form.toTag(),
    ];

    final completeEvent = Nip01Event(
      pubKey: listEvent.pubKey,
      kind: listEvent.kind,
      tags: completeTags,
      content: listEvent.content,
      createdAt: listEvent.createdAt,
    );

    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: keyPair.privateKey!,
      event: completeEvent,
    );
    return EscrowMethod.fromNostrEvent(signed);
  }

  /// Ensures the current user's escrow method list contains the given trusted
  /// escrow pubkeys, supported contract bytecode hashes, and accepted payment
  /// forms.
  ///
  /// If the user has no escrow method list, or it's missing required tags,
  /// publishes an updated list that includes them.
  /// Build [AcceptedPaymentForm] entries from the configured EVM chains'
  /// well-known tokens.
  ///
  /// For each chain, includes:
  ///   - The native token (ETH) denominated as `BTC`.
  ///   - tBTC (if configured) denominated as `BTC`.
  ///   - USDT (if configured) denominated as `USD`.
  List<AcceptedPaymentForm> _buildAcceptedPaymentForms() {
    final forms = <AcceptedPaymentForm>[];
    for (final chain in _config.evmConfig.chains) {
      // Native chain token.
      forms.add(
        AcceptedPaymentForm(
          denomination: 'BTC',
          tokenTagId: Token.rbtc(chain.chainId).tagId,
        ),
      );
      // tBTC ERC-20.
      final tbtc = chain.tokens['tBTC'];
      if (tbtc != null) {
        forms.add(
          AcceptedPaymentForm(
            denomination: 'BTC',
            tokenTagId: Token(
              chainId: chain.chainId,
              address: tbtc.address,
              decimals: tbtc.decimals,
            ).tagId,
          ),
        );
      }
      // USDT ERC-20.
      final usdt = chain.tokens['USDT'];
      if (usdt != null) {
        forms.add(
          AcceptedPaymentForm(
            denomination: 'USD',
            tokenTagId: Token(
              chainId: chain.chainId,
              address: usdt.address,
              decimals: usdt.decimals,
            ).tagId,
          ),
        );
      }
    }
    return forms;
  }

  Future<void> ensureEscrowMethod({
    List<String> trustedEscrowPubkeys = const [],
    List<AcceptedPaymentForm>? acceptedPaymentForms,
  }) async {
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return;

    if (supportedContractBytecodeHashes.isEmpty) {
      logger.w(
        'No supported escrow bytecode hashes configured — '
        'escrow method will have no "c" tags. '
        'Populate supportedEscrowBytecodeHashes in supported_bytecodes.dart.',
      );
    }

    // Default to config-derived forms when caller doesn't supply explicit ones.
    final resolvedForms = acceptedPaymentForms ?? _buildAcceptedPaymentForms();

    final pubkey = keyPair.publicKey;
    final existing = await getOne(
      Filter(kinds: EscrowMethod.kinds, authors: [pubkey]),
    );

    final signer = CoinlibEventSigner(
      privateKey: keyPair.privateKey,
      publicKey: pubkey,
    );

    if (existing != null) {
      final existingTrusted = existing.getTags('p').toSet();
      final missingTrusted = trustedEscrowPubkeys
          .where((pubkey) => !existingTrusted.contains(pubkey))
          .toList();
      final existingContracts = existing.getTags('c').toSet();
      final missingContracts = supportedContractBytecodeHashes
          .where((hash) => !existingContracts.contains(hash))
          .toList();
      final existingForms = existing.acceptedPaymentForms.toSet();
      final missingForms = resolvedForms
          .where((f) => !existingForms.contains(f))
          .toList();

      if (missingTrusted.isEmpty &&
          missingContracts.isEmpty &&
          missingForms.isEmpty) {
        return;
      }

      final tags = [
        for (final tag in existing.tags) [...tag],
      ];
      for (final pubkey in missingTrusted) {
        tags.add(['p', pubkey]);
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
      // No escrow method list exists – create one with trusted escrows,
      // supported bytecodes, and accepted forms.
      final list = Nip51List(
        pubKey: pubkey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: kNostrKindEscrowMethod,
        elements: [],
      );

      for (final trusted in trustedEscrowPubkeys) {
        list.addElement('p', trusted, false);
      }

      for (final contract in supportedContractBytecodeHashes) {
        list.addElement('c', contract, false);
      }

      final listEvent = await list.toEvent(signer);

      // Build the complete tag list before creating the event so the
      // auto-computed id covers every tag.  Mutating tags on an existing
      // Nip01Event leaves the id stale because it is `late final` and
      // Nip01Utils.signWithPrivateKey does not recalculate it.
      final completeTags = [
        ...listEvent.tags,
        for (final form in resolvedForms) form.toTag(),
      ];

      logger.i(
        'Publishing new escrow method for $pubkey with '
        '${trustedEscrowPubkeys.length} trusted escrows, '
        '${supportedContractBytecodeHashes.length} supported bytecodes, and '
        '${resolvedForms.length} accepted payment forms.',
      );

      final completeEvent = Nip01Event(
        pubKey: listEvent.pubKey,
        kind: listEvent.kind,
        tags: completeTags,
        content: listEvent.content,
        createdAt: listEvent.createdAt,
      );

      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: keyPair.privateKey!,
        event: completeEvent,
      );
      await upsert(EscrowMethod.fromNostrEvent(signed));
    }
    logger.i('Ensured escrow method for $pubkey');
  }
}
