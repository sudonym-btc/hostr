import 'package:hostr/config/main.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

@Singleton(as: Ndk)
class NostrNdk extends Ndk {
  Config c;
  NostrNdk(this.c)
      : super(NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: MemCacheManager(),
            engine: NdkEngine.JIT,
            defaultQueryTimeout: Duration(seconds: 10),
            bootstrapRelays: c.relays));
}
