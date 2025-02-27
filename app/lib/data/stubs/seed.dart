import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/main.dart';
import 'package:hostr/data/stubs/review.dart';
import 'package:hostr/injection.dart';

import 'main.dart';

var MOCK_EVENTS = [
  ...MOCK_ESCROWS.map((i) => i.nip01Event),
  ...MOCK_LISTINGS.map((i) => i.nip01Event),
  ...MOCK_RESERVATIONS.map((i) => i.nip01Event),
  ...MOCK_GIFT_WRAPS.map((i) => i.nip01Event),
  ...MOCK_PROFILES,
  ...MOCK_REVIEWS.map((i) => i.nip01Event)
];

seed() async {
  CustomLogger logger = CustomLogger();
  logger.i("seed");
  // for (KeyPair key in [MockKeys.guest, MockKeys.escrow, MockKeys.escrow]) {
  //   await getIt<Ndk>().userRelayLists.setInitialUserRelayList(UserRelayList(
  //       pubKey: key.publicKey,
  //       relays: {getIt<Config>().hostrRelay: ReadWriteMarker.readWrite},
  //       createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
  //       refreshedTimestamp: DateTime(2025).millisecondsSinceEpoch ~/ 1000));
  // }
  for (var x in MOCK_EVENTS) {
    await getIt<NostrService>().broadcast(event: x);
  }
  // for (var x in MOCK_LISTINGS) {
  //   await getIt<NostrService>().broadcast(event: x.nip01Event);
  // }
  // for (var x in MOCK_RESERVATIONS) {
  //   await getIt<NostrService>().broadcast(event: x.nip01Event);
  // }
  // for (var x in MOCK_GIFT_WRAPS) {
  //   await getIt<NostrService>().broadcast(event: x.nip01Event);
  // }
  // for (var x in MOCK_PROFILES) {
  //   await getIt<NostrService>().broadcast(event: x);
  // }
  // for (var x in MOCK_REVIEWS) {
  //   await getIt<NostrService>().broadcast(event: x.nip01Event);
  // }
  logger.i('seeded');
}
