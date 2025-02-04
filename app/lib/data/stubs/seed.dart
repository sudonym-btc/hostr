import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/main.dart';
import 'package:hostr/data/stubs/review.dart';
import 'package:hostr/injection.dart';

import 'main.dart';

seed() async {
  CustomLogger logger = CustomLogger();
  logger.i("seed");
  await getIt<RelayConnector>().connect();
  for (var x in MOCK_ESCROWS) {
    await getIt<NostrService>().broadcast(event: x.nip01Event);
  }
  for (var x in MOCK_LISTINGS) {
    print(x.nip01Event.pubKey);
    await getIt<NostrService>().broadcast(event: x.nip01Event);
  }
  for (var x in MOCK_RESERVATIONS) {
    await getIt<NostrService>().broadcast(event: x.nip01Event);
  }
  for (var x in MOCK_GIFT_WRAPS) {
    await getIt<NostrService>().broadcast(event: x.nip01Event);
  }
  for (var x in MOCK_PROFILES) {
    print(x.pubKey);
    // await getIt<NostrService>().broadcast(event: x.);
  }
  for (var x in MOCK_REVIEWS) {
    await getIt<NostrService>().broadcast(event: x.nip01Event);
  }
}
