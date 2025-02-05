import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

abstract class RelayConnector {
  CustomLogger logger = CustomLogger();
  Future connect();
}

@Injectable(as: RelayConnector)
class ProdRelayConnector extends RelayConnector {
  RelayStorage relayStorage = getIt<RelayStorage>();
  NwcStorage nwcStorage = getIt<NwcStorage>();
  Ndk ndk = getIt<Ndk>();

  @override
  Future connect() async {
    var relays = await relayStorage.get();
    Uri? nwc = await nwcStorage.getUri();
    logger.i('Connecting to relays');

    await getIt<Ndk>().relays.seedRelaysConnected;
  }
}
