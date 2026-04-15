import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' hide Requests;

import '../auth/auth.dart';
import '../crud.usecase.dart';

@Singleton()
class MetadataUseCase extends CrudUseCase<ProfileMetadata> {
  static const Duration metadataLoadTimeout = Duration(seconds: 40);

  final Auth _auth;
  final Ndk _ndk;

  MetadataUseCase({
    required Auth auth,
    required Ndk ndk,
    required super.requests,
    required super.logger,
  }) : _auth = auth,
       _ndk = ndk,
       super(kind: Metadata.kKind);

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
