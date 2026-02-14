import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
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
        )
        .toList();
    if (metadatas.isNotEmpty) {
      return ProfileMetadata.fromNostrEvent(metadatas.first);
    }
    return null;
  }

  Future<Future<List<RelayBroadcastResponse>>> upsertMetadata() async {
    final metadata = await loadMetadata(auth.activeKeyPair!.publicKey);
    var metadataEvent =
        metadata ??
        ProfileMetadata.fromNostrEvent(
          Nip01Event(
            pubKey: auth.activeKeyPair!.publicKey,
            kind: Metadata.kKind,
            tags: [],
            content: '',
          ),
        );

    if (metadataEvent.evmAddress == null) {
      metadataEvent.setEvmAddress(
        getEvmCredentials(auth.activeKeyPair!.privateKey!).address.eip55With0x,
      );
    }

    return requests.broadcast(event: metadataEvent);
  }
}
