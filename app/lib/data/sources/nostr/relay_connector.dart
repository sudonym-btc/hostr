import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

/// Strategy for establishing connections to relays and wallets.
abstract class RelayConnector {
  final CustomLogger logger = CustomLogger();
  Future<void> connect();
}

@Injectable(as: RelayConnector)
class ProdRelayConnector extends RelayConnector {
  RelayStorage relayStorage = getIt<RelayStorage>();
  NwcStorage nwcStorage = getIt<NwcStorage>();
  Ndk ndk = getIt<Ndk>();

  @override
  Future<void> connect() async {
    var relays = await relayStorage.get();
    Uri? nwc = await nwcStorage.getUri();
    logger.i('Connecting to relays $relays $nwc');

    await getIt<Ndk>().relays.seedRelaysConnected;
  }
}
