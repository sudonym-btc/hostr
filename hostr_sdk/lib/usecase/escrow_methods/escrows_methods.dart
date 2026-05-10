import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event, Nip51List;
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../auth/auth.dart';
import '../crud.usecase.dart';
import '../evm/evm.dart';

@Singleton()
class EscrowMethods extends CrudUseCase<EscrowMethod> {
  final Auth _auth;
  final Evm _evm;

  EscrowMethods({
    required super.requests,
    required super.logger,
    required Auth auth,
    required Evm evm,
  }) : _auth = auth,
       _evm = evm,
       super(kind: EscrowMethod.kinds[0]);

  Future<EscrowMethod?> myMethod() async {
    final keyPair = _auth.activeKeyPair;
    if (keyPair == null) return null;
    return getOne(
      Filter(kinds: EscrowMethod.kinds, authors: [keyPair.publicKey]),
      cacheRead: false,
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
    final keyPair = _auth.activeKeyPair;
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
      cacheRead: false,
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

      // Determine the appId used by our resolved forms (if any).
      // We strip all existing payment-form tags that share this appId, then
      // replace them with the freshly-resolved set.
      final appId = resolvedForms.isNotEmpty ? resolvedForms.first.appId : null;

      // Existing payment-form tags from other apps only: keep them.
      final retainedForms = existing.tags
          .where(
            (t) =>
                t.isNotEmpty &&
                t[0] == kAcceptedPaymentFormTag &&
                t.length >= 4 &&
                t[3] != appId,
          )
          .toList();

      // Build the set of forms that will end up on the event.
      final newFormsSet = {
        ...retainedForms
            .map((t) => AcceptedPaymentForm.fromTag(t))
            .whereType<AcceptedPaymentForm>(),
        ...resolvedForms,
      };
      final existingFormsSet = existing.acceptedPaymentForms.toSet();
      final formsChanged =
          newFormsSet.length != existingFormsSet.length ||
          !newFormsSet.containsAll(existingFormsSet);
      final hasLegacyHostrPaymentForms = existing.tags.any(
        _isLegacyHostrAcceptedPaymentFormTag,
      );

      if (missingTrusted.isEmpty &&
          missingContracts.isEmpty &&
          !formsChanged &&
          !hasLegacyHostrPaymentForms) {
        return;
      }

      // Rebuild tags: keep all non-payment-form tags, plus retained
      // foreign-appId payment-form tags, then append our fresh forms.
      final tags = <List<String>>[];
      for (final tag in existing.tags) {
        if (tag.isNotEmpty && tag[0] == kAcceptedPaymentFormTag) continue;
        if (_isLegacyHostrAcceptedPaymentFormTag(tag)) continue;
        tags.add([...tag]);
      }
      for (final pubkey in missingTrusted) {
        tags.add(['p', pubkey]);
      }
      for (final contract in missingContracts) {
        tags.add(['c', contract]);
      }
      // Re-add retained forms from other apps, then our fresh forms.
      for (final tag in retainedForms) {
        tags.add([...tag]);
      }
      for (final form in resolvedForms) {
        tags.add(form.toTag());
      }

      final signed = await _auth.signEvent(
        Nip01Event(
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

      final listEvent = await list.toEvent(null);

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

      final signed = await _auth.signEvent(completeEvent);
      await upsert(EscrowMethod.fromNostrEvent(signed));
    }
    logger.i('Ensured escrow method for $pubkey');
  }
}

/// Build [AcceptedPaymentForm] entries from discovered EVM swap capabilities
/// plus configured stablecoins.
///
/// For each chain, includes:
///   - The native token when live Boltz support exists, denominated per
///     [EvmChainConfig.nativeDenomination] (e.g. `ETH` on Arbitrum, `BTC` on
///     Rootstock).
///   - tBTC denominated as `BTC` when live Boltz support exists for the
///     configured tBTC token.
///   - USDT (if configured) denominated as `USD`.
///
/// All forms are tagged with `appId: 'hostr'` so they can be atomically
/// replaced on subsequent calls to [EscrowMethods.ensureEscrowMethod].
const _appId = 'hostr';

bool _isLegacyHostrAcceptedPaymentFormTag(List<String> tag) {
  if (tag.length < 4 || tag[0] != 'a' || tag[3] != _appId) return false;

  final tokenTagId = tag[2];
  return tokenTagId == tokenTagId.toUpperCase() ||
      RegExp(r'^\d+:0x[0-9a-fA-F]{40}$').hasMatch(tokenTagId);
}

List<AcceptedPaymentForm> buildAcceptedPaymentForms(Evm evm) {
  final forms = <AcceptedPaymentForm>[];
  for (final chain in evm.configuredChains) {
    final swaps = chain.swaps;

    if (swaps != null) {
      forms.add(
        AcceptedPaymentForm(
          denomination: chain.config.nativeDenomination,
          tokenTagId: Token.native(chain.config.chainId).tagId,
          appId: _appId,
        ),
      );

      final tbtc = chain.config.tokens['tBTC'];
      if (tbtc != null &&
          swaps.supportsTokenAddress(EthereumAddress.fromHex(tbtc.address))) {
        forms.add(
          AcceptedPaymentForm(
            denomination: tbtc.denomination,
            tokenTagId: '${chain.config.chainId}:${tbtc.address}',
            appId: _appId,
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
          appId: _appId,
        ),
      );
    }
  }
  return forms;
}
