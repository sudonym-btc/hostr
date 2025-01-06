import 'package:dart_nostr/nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

abstract class RelayConnector {
  CustomLogger logger = CustomLogger();
  Future connect();
}

@Injectable(as: RelayConnector, env: Env.allButMock)
class ProdRelayConnector extends RelayConnector {
  RelayStorage relayStorage = getIt<RelayStorage>();

  @override
  Future connect() async {
    var relays = await relayStorage.get();
    logger.i('Connecting to relays');
    await Nostr.instance.relaysService.init(
      relaysUrl: new Set.of([...getIt<Config>().relays, ...relays]).toList(),
      onRelayListening: (String relayUrl, receivedData, ws) {
        logger.i('Relay listening: $relayUrl');
      }, // will be called once a relay is connected and listening to events.
      onRelayConnectionError: (String relayUrl, Object? error, ws) {
        logger.e('Error connecting to relay: $relayUrl', error: error);
      }, // will be called once a relay is disconnected or an error occurred.
      onRelayConnectionDone: (String relayUrl, ws) {
        logger.i('Relay connection done: $relayUrl');
      }, // will be called once a relay is disconnected, finished.
      lazyListeningToRelays:
          false, // if true, the relays will not start listening to events until you call `Nostr.instance.relaysService.startListeningToRelays()`, if false, the relays will start listening to events as soon as they are connected.
    );
  }
}

@Injectable(as: RelayConnector, env: [Env.mock])
class MockRelayConnector extends RelayConnector {
  @override
  Future connect() async {}
}
