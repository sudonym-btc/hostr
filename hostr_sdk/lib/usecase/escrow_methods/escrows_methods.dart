import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event, Nip01Utils, Nip51List;
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../config.dart' show CoinlibEventSigner;
import '../auth/auth.dart';
import '../crud.usecase.dart';
import '../evm/evm.dart';

@Singleton()
class EscrowMethods extends CrudUseCase<EscrowMethod> {
  final Auth _auth;
  final Evm _evm;
  Auth get auth => _auth;

  EscrowMethods({
    required super.requests,
    required super.logger,
    required Auth auth,
    required Evm evm,
  }) : _auth = auth,
       _evm = evm,
       super(kind: EscrowMethod.kinds[0]);

  Future<EscrowMethod?> myMethod() async {
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return null;
    return getOne(
      Filter(kinds: EscrowMethod.kinds, authors: [keyPair.publicKey]),
    );
  }

  /// Ensures the current user's escrow method list contains the given trusted
  /// escrow pubkeys, supported contract bytecode hashes, and accepted payment
  /// forms.
  ///
  /// If the user has no escrow method list, or it's missing required tags,
  /// publishes an updated list that includes them.
  /// Build [AcceptedPaymentForm] entries from discovered EVM swap
  /// capabilities plus configured stablecoins.
  ///
  /// For each chain, includes:
  ///   - The native token denominated as `BTC` when live Boltz support exists.
  ///   - tBTC denominated as `BTC` when live Boltz support exists for the
  ///     configured tBTC token.
  ///   - USDT (if configured) denominated as `USD`.
  List<AcceptedPaymentForm> _buildAcceptedPaymentForms() =>
      buildAcceptedPaymentForms(_evm);

  Future<void> ensureEscrowMethod({
    Set<String> bytecodeHashes = const {},
    List<String> trustedEscrowPubkeys = const [],
    List<AcceptedPaymentForm>? acceptedPaymentForms,
  }) async {
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return;

    if (bytecodeHashes.isEmpty) {
      logger.w(
        'No bytecode hashes provided — escrow method will have no "c" tags. '
        'Ensure escrowContractAddress is set in EvmChainConfig.',
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
      final missingContracts = bytecodeHashes
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
      // Ensure the d tag is present for parameterized replaceable events.
      if (!tags.any((t) => t.isNotEmpty && t[0] == 'd')) {
        tags.insert(0, ['d', '']);
      }
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

      logger.i('Upserting escrow method $signed');

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

      for (final contract in bytecodeHashes) {
        list.addElement('c', contract, false);
      }

      final listEvent = await list.toEvent(signer);

      // Build the complete tag list before creating the event so the
      // auto-computed id covers every tag.  Mutating tags on an existing
      // Nip01Event leaves the id stale because it is `late final` and
      // Nip01Utils.signWithPrivateKey does not recalculate it.
      final completeTags = [
        ['d', ''],
        ...listEvent.tags,
        for (final form in resolvedForms) form.toTag(),
      ];

      logger.i(
        'Publishing new escrow method for $pubkey with '
        '${trustedEscrowPubkeys.length} trusted escrows, '
        '${bytecodeHashes.length} supported bytecodes, and '
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

/// Build [AcceptedPaymentForm] entries from discovered EVM swap capabilities
/// plus configured stablecoins.
///
/// For each chain, includes:
///   - The native token denominated as `BTC` when live Boltz support exists.
///   - tBTC denominated as `BTC` when live Boltz support exists for the
///     configured tBTC token.
///   - USDT (if configured) denominated as `USD`.
List<AcceptedPaymentForm> buildAcceptedPaymentForms(Evm evm) {
  final forms = <AcceptedPaymentForm>[];
  for (final chain in evm.configuredChains) {
    final swaps = chain.swaps;

    if (swaps != null) {
      forms.add(
        AcceptedPaymentForm(
          denomination: 'BTC',
          tokenTagId: Token.native(chain.config.chainId).tagId,
        ),
      );

      final tbtc = chain.config.tokens['tBTC'];
      if (tbtc != null &&
          swaps.supportsTokenAddress(EthereumAddress.fromHex(tbtc.address))) {
        forms.add(
          AcceptedPaymentForm(
            denomination: tbtc.denomination,
            tokenTagId: '${chain.config.chainId}:${tbtc.address}',
          ),
        );
      }
    }

    final usdt = chain.config.tokens['USDT'];
    if (usdt != null) {
      forms.add(
        AcceptedPaymentForm(
          denomination: usdt.denomination,
          tokenTagId: '${chain.config.chainId}:${usdt.address}',
        ),
      );
    }
  }
  return forms;
}
