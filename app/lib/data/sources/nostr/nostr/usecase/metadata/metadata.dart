import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' hide Requests;

import '../auth/auth.dart';
import '../requests/requests.dart';

@Singleton()
class MetadataUseCase {
  Requests requests;
  Auth auth;
  MetadataUseCase({required this.auth, required this.requests});

  Future<ProfileMetadata?> loadMetadata(String pubkey) async {
    List<Nip01Event> metadatas = await requests
        .query(
          filter: Filter(kinds: [Metadata.kKind], authors: [pubkey], limit: 1),
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
