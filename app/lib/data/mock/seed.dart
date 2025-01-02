import 'package:hostr/core/main.dart';
import 'package:hostr/data/repositories/main.dart';
import 'package:hostr/data/sources/nostr/relay_connector.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/setup.dart';

import 'main.dart';

seed() async {
  CustomLogger logger = CustomLogger();
  logger.i("seed");
  await getIt<RelayConnector>().connect();
  for (var x in MOCK_ESCROWS) {
    getIt<EscrowRepository>().create(x.event);
  }
  for (var x in MOCK_LISTINGS) {
    getIt<ListingRepository>().create(x.event);
  }
  for (var x in MOCK_PROFILES) {
    getIt<ProfileRepository>().create(x);
  }
}

void main() async {
  setup(Env.dev);
  await seed();
}
