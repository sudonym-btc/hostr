import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/ndk.dart' show Metadata, Filter;

import 'metadata.dart';

@Singleton(as: MetadataUseCase, env: [Env.mock, Env.test])
class MockMetadataUseCase extends MetadataUseCase {
  MockMetadataUseCase({
    required super.requests,
    required super.ndk,
    required super.auth,
  });
  @override
  Future<Metadata?> loadMetadata(String pubkey) async {
    List<Nip01Event> metadatas = await requests
        .query(
          filter: Filter(kinds: [Metadata.kKind], authors: [pubkey], limit: 1),
        )
        .toList();
    if (metadatas.isNotEmpty) {
      return Metadata.fromEvent(metadatas.first);
    }
    return null;
  }
}
