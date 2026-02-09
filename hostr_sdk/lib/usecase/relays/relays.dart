import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../storage/storage.dart';

@Singleton(env: Env.allButTestAndMock)
class Relays {
  final CustomLogger logger;
  final Ndk ndk;
  final RelayStorage relayStorage;
  Relays({required this.ndk, required this.relayStorage, required this.logger});

  Future<void> add(String url) {
    logger.d('Adding relay: $url');
    return ndk.relays
        .connectRelay(dirtyUrl: url, connectionSource: ConnectionSource.seed)
        .then((value) async {
          logger.i('Connected to relay: $url success: ${value.first}');
          if (value.first == true) {
            await relayStorage.add(url);
          } else {
            throw Exception(value.second);
          }
        });
  }

  Future<void> remove(String url) async {
    logger.d('Removing relay: $url');
    ndk.relays.closeAllTransports();

    List<RelayConnectivity<dynamic>> relays = ndk.relays.connectedRelays;
    for (var relay in relays) {
      if (relay.url == url) {
        await relay.close();
      }
    }
    await relayStorage.remove(url);
  }

  Future<void> connect() {
    return ndk.relays.seedRelaysConnected;
  }

  Stream<Map<String, RelayConnectivity<dynamic>>> connectivity() {
    return ndk.relays.relayConnectivityChanges;
  }
}

@Singleton(as: Relays, env: [Env.test, Env.mock])
class MockRelays extends Relays {
  MockRelays({
    required super.ndk,
    required super.relayStorage,
    required super.logger,
  });
}
