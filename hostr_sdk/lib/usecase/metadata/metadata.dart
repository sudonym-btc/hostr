import 'dart:async';

import 'package:injectable/injectable.dart';
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
  }) => logger.span('loadMetadata', () async {
    final metadata = await _ndk.metadata.loadMetadata(
      pubkey,
      forceRefresh: forceRefresh,
    );
    if (metadata != null) {
      return ProfileMetadata.fromNostrEvent(metadata.toEvent());
    }
    return null;
  });

  /// Refreshes the cached NIP-65 relay list for [pubkey] from the network.
  /// Call before [loadMetadata] with forceRefresh so the JIT engine knows
  /// which relays to query.
  Future<UserRelayList?> refreshNip65(String pubkey) async {
    return await _ndk.userRelayLists.getSingleUserRelayList(
      pubkey,
      forceRefresh: true,
    );
  }

  /// Ensures all replaceable user-config events are up to date:
  /// NIP-65 relay list, EVM address tag, escrow methods, blossom servers.
  ///
  /// Called automatically after every [upsert] and by user startup for
  /// returning users who already have a NIP-65 relay list.
  Future<void> ensureUserConfig(String pubkey) =>
      logger.span('ensureUserConfig', () async {
        // Check whether a NIP-65 relay list already exists *before* we
        // publish one. If the user has no NIP-65 yet we must re-broadcast
        // their metadata to the relays that will be listed in the new
        // NIP-65 event, otherwise subsequent loads using the outbox model
        // will fail to find the profile.
        final hadNip65 =
            await _ndk.userRelayLists.getSingleUserRelayList(pubkey) != null;

        try {
          await _relays.publishNip65(
            hostrRelay: _config.hostrRelay,
            pubkey: pubkey,
          );
        } catch (e) {
          logger.e('publishNip65 failed: $e');
        }

        // First-time NIP-65: the metadata (kind-0) likely only lives on
        // relays the user was using before hostr. Re-broadcast it to the
        // hostr relay so it can be found via the new NIP-65 relay list.
        if (!hadNip65) {
          try {
            final profile = await loadMetadata(pubkey);
            if (profile != null) {
              logger.i(
                'Re-broadcasting metadata to NIP-65 relays (first NIP-65)',
              );
              await super.upsert(profile);
            }
          } catch (e) {
            logger.e('Re-broadcast metadata after first NIP-65 failed: $e');
          }
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
                  chain.client,
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

  /// Ensures the current user's profile has an EVM address tag.
  /// Only broadcasts an update if the tag is missing.
  Future<void> ensureEvmAddress() => logger.span('ensureEvmAddress', () async {
    final metadata = await loadMetadata(_auth.activeKeyPair!.publicKey);
    if (metadata == null) return; // No profile yet — nothing to patch.

    try {
      if (metadata.evmAddress != null) return; // Already has it.
    } catch (_) {
      // evmAddress getter throws if the tag is absent.
    }

    final address = await _auth.hd.getEvmAddress();
    final updated = metadata.withEvmAddress(address.eip55With0x);
    await requests.broadcast(event: updated);
    notifyUpdate(updated);
  });
}
