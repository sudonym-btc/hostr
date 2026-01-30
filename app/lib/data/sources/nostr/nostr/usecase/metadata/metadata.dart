import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/util/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' hide Requests;

import '../auth/auth.dart';
import '../requests/requests.dart';

@Singleton(env: Env.allButTestAndMock)
class MetadataUseCase {
  Ndk ndk;
  Requests requests;
  Auth auth;
  MetadataUseCase({
    required this.ndk,
    required this.auth,
    required this.requests,
  });

  Future<Metadata?> loadMetadata(String pubkey) {
    return ndk.metadata.loadMetadata(pubkey);
  }

  Future<Future<List<RelayBroadcastResponse>>> upsertMetadata() async {
    final metadata = await loadMetadata(auth.activeKeyPair!.publicKey);
    var metadataEvent =
        metadata?.toEvent() ??
        Metadata(pubKey: auth.activeKeyPair!.publicKey).toEvent();
    List<String> iTags = metadataEvent
        .getTags('i')
        .where((tag) => tag[0] == 'evm:address')
        .toList();

    String evmAddress = getEvmCredentials(
      auth.activeKeyPair!.privateKey!,
    ).address.eip55With0x;

    if (!iTags.map((tag) => tag[1]).any((tag) => tag == evmAddress)) {
      metadataEvent = metadataEvent.copyWith(
        tags: [
          ...metadataEvent.tags,
          ['i', 'evm:address', evmAddress],
        ],
      );
    }
    return requests.broadcast(event: metadataEvent);
  }
}
