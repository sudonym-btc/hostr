import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

@Singleton(env: Env.allButTestAndMock)
class MetadataUseCase {
  Ndk ndk;
  MetadataUseCase({required this.ndk});
  Future<Metadata?> loadMetadata(String pubkey) {
    return ndk.metadata.loadMetadata(pubkey);
  }
}
