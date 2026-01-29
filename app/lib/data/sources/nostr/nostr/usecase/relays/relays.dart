import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' hide Nwc;

@Singleton(env: Env.allButTestAndMock)
class Relays {
  Ndk ndk;

  Relays({required this.ndk});

  Future<void> connect() {
    return ndk.relays.seedRelaysConnected;
  }
}

@Singleton(as: Relays, env: [Env.test, Env.mock])
class MockRelays extends Relays {
  MockRelays({required super.ndk});
}
