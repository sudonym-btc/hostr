import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/setup.dart';

import 'main.dart';

seed() async {
  CustomLogger logger = CustomLogger();
  logger.i("seed");
  await getIt<RelayConnector>().connect();
  for (var x in MOCK_ESCROWS) {
    getIt<NostrProvider>().sendEventToRelaysAsync(event: x);
  }
  for (var x in MOCK_LISTINGS) {
    getIt<NostrProvider>().sendEventToRelaysAsync(event: x);
  }
  for (var x in MOCK_PROFILES) {
    getIt<NostrProvider>().sendEventToRelaysAsync(event: x);
  }
}

void main() async {
  setup(Env.dev);
  await seed();
}
