import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart' hide Requests;
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../config.dart';
import '../auth/auth.dart';
import '../blossom/blossom.dart';
import '../crud.usecase.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../escrow_methods/escrows_methods.dart';
import '../evm/evm.dart';
import '../relays/relays.dart';

@Singleton()
class MetadataUseCase extends CrudUseCase<ProfileMetadata> {
  static const Duration metadataLoadTimeout = Duration(seconds: 40);

  final Auth _auth;
  final Ndk _ndk;
  final Relays _relays;
  final EscrowMethods _escrowMethods;
  final BlossomUseCase _blossom;
  final Evm _evm;
  final HostrConfig _config;
  final Map<String, Future<ProfileMetadata?>> _inFlightLoads = {};

  MetadataUseCase({
    required Auth auth,
    required Ndk ndk,
    required Relays relays,
    required EscrowMethods escrowMethods,
    required BlossomUseCase blossom,
    required Evm evm,
    required HostrConfig config,
    required super.requests,
    required super.logger,
  }) : _auth = auth,
       _ndk = ndk,
       _relays = relays,
       _escrowMethods = escrowMethods,
       _blossom = blossom,
       _evm = evm,
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
          ensureUserConfig(pubkey).catchError((e) {
            logger.e('ensureUserConfig failed: $e');
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
    final relays = _config.bootstrapRelays;
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
  /// EVM address tag, escrow methods, blossom servers.
  ///
  /// Called automatically after every [upsert] and by user startup.
  ///
  /// This intentionally does not mutate the user's NIP-65 relay list during
  /// startup/profile sync. Hostr may read NIP-65 for discovery, but should
  /// not silently append its own relay while the product is still treating the
  /// wider relay graph as read-mostly.
  Future<void> ensureUserConfig(String pubkey) =>
      logger.span('ensureUserConfig', () async {
        if (_config.hostrRelay.isNotEmpty) {
          logger.i(
            'Skipping automatic NIP-65 publish for $pubkey '
            'while syncing via ${_relays.runtimeType}',
          );
        }

        try {
          await ensureEvmAddress();
        } catch (e) {
          logger.e('ensureEvmAddress failed: $e');
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

        try {
          await _blossom.ensureBlossomServer(pubkey);
        } catch (e) {
          logger.e('ensureBlossomServer failed: $e');
        }
      });

  /// Ensures the current user's profile is present on the Hostr relay with an
  /// EVM address tag.
  Future<void> ensureEvmAddress() => logger.span('ensureEvmAddress', () async {
    final metadata = await loadMetadata(_auth.activeKeyPair!.publicKey);
    if (metadata == null) return; // No profile yet — nothing to patch.

    final address = await _auth.hd.getEvmAddress();
    try {
      if (metadata.evmAddress == address.eip55With0x) return;
    } catch (_) {
      // No EVM tag yet.
    }

    final updated = _profileWithEvmAddress(metadata, address.eip55With0x);
    await requests.broadcast(
      event: updated,
      relays: _config.hostrRelay.isEmpty ? null : [_config.hostrRelay],
    );
    notifyUpdate(updated);
  });

  ProfileMetadata _profileWithEvmAddress(
    ProfileMetadata metadata,
    String address,
  ) {
    final updatedTags = List<List<String>>.from(
      metadata.tags.where((tag) {
        return tag.length < 2 || tag[0] != 'i' || tag[1] != 'evm:address';
      }),
    )..add(['i', 'evm:address', address]);

    return ProfileMetadata.fromNostrEvent(
      Nip01Event(
        pubKey: metadata.pubKey,
        kind: metadata.kind,
        tags: updatedTags,
        content: metadata.content,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );
  }
}
