import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

abstract class RelayConnector {
  CustomLogger logger = CustomLogger();
  Future connect();
}

@Injectable(as: RelayConnector, env: Env.allButTestAndMock)
class ProdRelayConnector extends RelayConnector {
  RelayStorage relayStorage = getIt<RelayStorage>();
  NwcStorage nwcStorage = getIt<NwcStorage>();
  Ndk ndk = getIt<Ndk>();

  @override
  Future connect() async {
    var relays = await relayStorage.get();
    Uri? nwc = await nwcStorage.getUri();
    logger.i('Connecting to relays');

    // await ndk.relays.c(
    //   relaysUrl: new Set.of([
    //     ...getIt<Config>().relays,
    //     ...relays,
    //     // if (nwc != null) nwc.queryParameters['relay']!
    //   ]).toList(),
    //   onRelayListening: (String relayUrl, receivedData, ws) {
    //     logger.i('Relay listening: $relayUrl');
    //   }, // will be called once a relay is connected and listening to events.
    //   onRelayConnectionError: (String relayUrl, Object? error, ws) {
    //     logger.e('Error connecting to relay: $relayUrl', error: error);
    //   }, // will be called once a relay is disconnected or an error occurred.
    //   onRelayConnectionDone: (String relayUrl, ws) {
    //     logger.i('Relay connection done: $relayUrl');
    //   }, // will be called once a relay is disconnected, finished.
    //   lazyListeningToRelays:
    //       false, // if true, the relays will not start listening to events until you call `Nostr.instance.relaysService.startListeningToRelays()`, if false, the relays will start listening to events as soon as they are connected.
    // );
  }
}

@Injectable(as: RelayConnector, env: [Env.mock, Env.test])
class MockRelayConnector extends RelayConnector {
  @override
  Future connect() async {}
}
