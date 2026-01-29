import 'package:hostr/data/sources/nostr/nostr/usecase/nwc/nwc.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' hide Nwc;

@Singleton(env: Env.allButTestAndMock)
class Zaps {
  Nwc nwc;
  Ndk ndk;

  Zaps({required this.nwc, required this.ndk});

  Future<ZapResponse> zap({required String lnurl, required int amountSats}) {
    return ndk.zaps.zap(
      nwcConnection: nwc.connections[0],
      lnurl: lnurl,
      amountSats: amountSats,
    );
  }
}

@Singleton(as: Zaps, env: [Env.test, Env.mock])
class MockZaps extends Zaps {
  MockZaps({required super.nwc, required super.ndk});
}
