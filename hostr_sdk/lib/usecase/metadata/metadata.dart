import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' hide Requests;

@Singleton()
class MetadataUseCase extends CrudUseCase<ProfileMetadata> {
  static const Duration metadataLoadTimeout = Duration(seconds: 40);

  Auth auth;
  final Ndk ndk;
  MetadataUseCase({
    required this.auth,
    required this.ndk,
    required super.requests,
    required super.logger,
  }) : super(kind: Metadata.kKind);

  Future<ProfileMetadata?> loadMetadata(String pubkey) async {
    // We can't use NDK metadata use case, since it does not return custom fields/tags
    final metadatas = await requests
        .query(
          filter: Filter(kinds: [Metadata.kKind], authors: [pubkey], limit: 1),
          timeout: metadataLoadTimeout,
          name: 'Metadata-load-$pubkey',
        )
        .toList();

    if (metadatas.isNotEmpty) {
      return ProfileMetadata.fromNostrEvent(
        metadatas.reduce((a, b) => a.createdAt >= b.createdAt ? a : b),
      );
    }

    // TODO: Remove this cache fallback and implement a proper metadata-loading
    // strategy that reliably resolves the latest profile from relays.
    // Fallback to local NDK cache when the relay query returns no results.
    // This helps in cases where metadata exists locally but is temporarily
    // unavailable from the current relay query path.
    final cachedMetadatas = await ndk.requests
        .query(
          name: 'Metadata-load-cache-$pubkey',
          filter: Filter(kinds: [Metadata.kKind], authors: [pubkey], limit: 20),
          cacheRead: true,
          cacheWrite: true,
          timeout: metadataLoadTimeout,
        )
        .stream
        .toList();

    if (cachedMetadatas.isNotEmpty) {
      logger.w(
        'Metadata relay query returned empty for $pubkey, using cached metadata (${cachedMetadatas.length} hit(s))',
      );
      return ProfileMetadata.fromNostrEvent(
        cachedMetadatas.reduce((a, b) => a.createdAt >= b.createdAt ? a : b),
      );
    }

    return null;
  }

  /// Ensures the current user's profile has an EVM address tag.
  /// Only broadcasts an update if the tag is missing.
  Future<void> ensureEvmAddress() async {
    final metadata = await loadMetadata(auth.activeKeyPair!.publicKey);
    if (metadata == null) return; // No profile yet — nothing to patch.

    try {
      if (metadata.evmAddress != null) return; // Already has it.
    } catch (_) {
      // evmAddress getter throws if the tag is absent.
    }

    final updated = metadata.withEvmAddress(
      getEvmCredentials(auth.activeKeyPair!.privateKey!).address.eip55With0x,
    );
    await requests.broadcast(event: updated);
    notifyUpdate(updated);
  }
}
