import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/main.dart';
import 'package:hostr/injection.dart';

import 'main.dart';

seed() async {
  CustomLogger logger = CustomLogger();
  logger.i("seed");
  await getIt<RelayConnector>().connect();
  for (var x in MOCK_ESCROWS) {
    await getIt<NostrService>().sendEventToRelaysAsync(event: x);
  }
  for (var x in MOCK_LISTINGS) {
    await getIt<NostrService>().sendEventToRelaysAsync(event: x);
  }
  for (var x in MOCK_RESERVATIONS) {
    await getIt<NostrService>().sendEventToRelaysAsync(event: x);
  }
  for (var x in MOCK_GIFT_WRAPS) {
    await getIt<NostrService>().sendEventToRelaysAsync(event: x);
  }
  for (var x in MOCK_PROFILES) {
    await getIt<NostrService>().sendEventToRelaysAsync(event: x);
  }
}
