import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart' hide Requests;
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../config.dart';
import '../blossom/blossom.dart';
import '../crud.usecase.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../escrow_methods/escrows_methods.dart';
import '../evm/evm.dart';
import '../identity_claims/identity_claims.dart';
import '../relays/relays.dart';

@visibleForTesting
List<String> metadataDiscoveryRelays({
  required String hostrRelay,
  required List<String> bootstrapRelays,
}) {
  return [
    ...{
      if (hostrRelay.trim().isNotEmpty) hostrRelay.trim(),
      for (final relay in bootstrapRelays)
        if (relay.trim().isNotEmpty) relay.trim(),
    },
  ];
}

@Singleton()
class MetadataUseCase extends CrudUseCase<ProfileMetadata> {
  static const Duration metadataLoadTimeout = Duration(seconds: 40);

  final Ndk _ndk;
  final Relays _relays;
  final EscrowMethods _escrowMethods;
  // Keep injected while automatic Blossom list publishing is paused so the
  // future re-enable path stays obvious and local to ensureUserConfig.
  // ignore: unused_field
  final BlossomUseCase _blossom;
  final Evm _evm;
  final IdentityClaimsUseCase _identityClaims;
  final HostrConfig _config;
  final Map<String, Future<ProfileMetadata?>> _inFlightLoads = {};

  MetadataUseCase({
    required Ndk ndk,
    required Relays relays,
    required EscrowMethods escrowMethods,
    required BlossomUseCase blossom,
    required Evm evm,
    required IdentityClaimsUseCase identityClaims,
    required HostrConfig config,
    required super.requests,
    required super.logger,
  }) : _ndk = ndk,
       _relays = relays,
       _escrowMethods = escrowMethods,
       _blossom = blossom,
       _evm = evm,
       _identityClaims = identityClaims,
       _config = config,
       super(kind: Metadata.kKind);

  @override
  Future<List<RelayBroadcastResponse>> upsert(ProfileMetadata event) =>
      logger.span('upsert', () async {
        final result = await super.upsert(event);
        await _ndk.config.cache.saveMetadata(event.metadata);
        // Fire-and-forget: ensure all user config is up-to-date now that
        // the profile has been saved and relays are connected.
        final pubkey = event.pubKey;
        if (pubkey.isNotEmpty) {
          ensureSellerConfig(pubkey).catchError((e) {
            logger.e('ensureSellerConfig failed: $e');
          });
        }
        return result;
      });

  Future<ProfileMetadata?> loadMetadata(
    String pubkey, {
    bool forceRefresh = false,
  }) {
    final trimmedPubkey = pubkey.trim();
    if (trimmedPubkey.isEmpty) return Future.value(null);

    // A force refresh is a stronger request, so regular callers can share it
    // instead of opening a parallel non-force metadata query for the same key.
    if (!forceRefresh) {
      final forceKey = _metadataLoadKey(trimmedPubkey, forceRefresh: true);
      final forceLoad = _inFlightLoads[forceKey];
      if (forceLoad != null) return forceLoad;
    }

    final key = _metadataLoadKey(trimmedPubkey, forceRefresh: forceRefresh);
    final existing = _inFlightLoads[key];
    if (existing != null) return existing;

    late final Future<ProfileMetadata?> load;
    load = logger
        .span(
          'loadMetadata',
          () => loadMetadataFromSources(
            trimmedPubkey,
            forceRefresh: forceRefresh,
          ),
        )
        .whenComplete(() {
          if (identical(_inFlightLoads[key], load)) {
            _inFlightLoads.remove(key);
          }
        });
    _inFlightLoads[key] = load;
    return load;
  }

  String _metadataLoadKey(String pubkey, {required bool forceRefresh}) =>
      '$pubkey|forceRefresh=$forceRefresh';

  @protected
  @visibleForTesting
  Future<ProfileMetadata?> loadMetadataFromSources(
    String pubkey, {
    required bool forceRefresh,
  }) async {
    final cachedOrJit = await _ndk.metadata.loadMetadata(
      pubkey,
      forceRefresh: forceRefresh,
    );
    if (cachedOrJit != null && !forceRefresh) {
      return ProfileMetadata.fromNostrEvent(cachedOrJit.toEvent());
    }

    final discovered = await _loadMetadataFromDiscoveryRelays(pubkey);
    if (discovered != null) return discovered;

    if (cachedOrJit != null) {
      return ProfileMetadata.fromNostrEvent(cachedOrJit.toEvent());
    }

    return null;
  }

  Future<ProfileMetadata?> _loadMetadataFromDiscoveryRelays(
    String pubkey,
  ) async {
    final relays = metadataDiscoveryRelays(
      hostrRelay: _config.hostrRelay,
      bootstrapRelays: _config.bootstrapRelays,
    );
    if (relays.isEmpty) return null;

    ProfileMetadata? latest;
    await for (final profile in requests.query<ProfileMetadata>(
      filter: Filter(kinds: [Metadata.kKind], authors: [pubkey], limit: 1),
      relays: relays,
      name: 'metadata-discovery',
      timeout: metadataLoadTimeout,
    )) {
      if (latest == null || latest.createdAt < profile.createdAt) {
        latest = profile;
      }
    }

    if (latest != null) {
      await _ndk.config.cache.saveMetadata(latest.metadata);
    }
    return latest;
  }

  /// Refreshes the cached NIP-65 relay list for [pubkey] from the network.
  /// Call before [loadMetadata] with forceRefresh so the JIT engine knows
  /// which relays to query.
  Future<UserRelayList?> refreshNip65(String pubkey) async {
    return await _ndk.userRelayLists.getSingleUserRelayList(
      pubkey,
      forceRefresh: true,
    );
  }

  /// Ensures Hostr-managed user config is up to date:
  /// identity claims and escrow methods.
  ///
  /// Blossom and NIP-65 list writes are intentionally paused. We do not want the
  /// app to rely on user-published server/relay lists while Hostr traffic is
  /// scoped to Hostr-owned infrastructure, but the code remains nearby so it can
  /// be re-enabled when those lists become part of the product contract again.
  ///
  /// Called automatically after every [upsert] and by user startup.
  ///
  /// This intentionally does not mutate the user's NIP-65 relay list during
  /// startup/profile sync. Hostr may read NIP-65 for discovery, but should
  /// not silently append its own relay while the product is still treating the
  /// wider relay graph as read-mostly.
  Future<void> ensureSellerConfig(String pubkey) =>
      logger.span('ensureSellerConfig', () async {
        if (_config.hostrRelay.isNotEmpty) {
          logger.i(
            'Skipping automatic NIP-65 publish for $pubkey '
            'while syncing via ${_relays.runtimeType}',
          );
        }

        try {
          await _identityClaims.ensureEvmAddress();
        } catch (e) {
          logger.e('IdentityClaims.ensureEvmAddress failed: $e');
        }

        try {
          final bytecodeHashes = <String>{};
          for (final chain in _evm.configuredChains) {
            final addr = chain.config.escrowContractAddress;
            if (addr == null || addr.isEmpty) continue;
            try {
              bytecodeHashes.add(
                await SupportedEscrowContractRegistry.bytecodeHashForAddress(
                  chain,
                  EthereumAddress.fromHex(addr),
                ),
              );
            } catch (e) {
              logger.w(
                'Could not resolve bytecode hash for $addr on '
                '${chain.config.id}: $e',
              );
            }
          }
          await _escrowMethods.ensureEscrowMethod(
            trustedEscrowPubkeys: _config.bootstrapEscrowPubkeys,
            bytecodeHashes: bytecodeHashes,
          );
        } catch (e) {
          logger.e('ensureEscrowMethod failed: $e');
        }

        logger.i('Skipping automatic Blossom server-list publish for $pubkey');
        /*
        try {
          await _blossom.ensureBlossomServer(pubkey);
        } catch (e) {
          logger.e('ensureBlossomServer failed: $e');
        }
        */
      });

  Future<void> ensureUserConfig(String pubkey) => ensureSellerConfig(pubkey);
}
