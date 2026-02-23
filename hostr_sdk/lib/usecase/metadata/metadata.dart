import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' hide Requests;

@Singleton()
class MetadataUseCase extends CrudUseCase<ProfileMetadata> {
  static const Duration metadataLoadTimeout = Duration(seconds: 40);

  Auth auth;
  MetadataUseCase({
    required this.auth,
    required super.requests,
    required super.logger,
  }) : super(kind: Metadata.kKind);

  Future<ProfileMetadata?> loadMetadata(String pubkey) async {
    // We can't use NDK metadata use case, since it does not return custom fields/tags
    List<Nip01Event> metadatas = await requests
        .query(
          filter: Filter(kinds: [Metadata.kKind], authors: [pubkey], limit: 1),
          timeout: metadataLoadTimeout,
          name: 'Metadata-load-$pubkey',
        )
        .toList();
    if (metadatas.isNotEmpty) {
      return ProfileMetadata.fromNostrEvent(metadatas.first);
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
