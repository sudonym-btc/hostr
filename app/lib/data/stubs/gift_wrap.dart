import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';

var MOCK_GIFT_WRAPS = [
  giftWrapAndSeal(
      MockKeys.guest.public,
      MockKeys.hoster,
      Message.fromNostrEvent(NostrEvent.fromPartialData(
        kind: NOSTR_KIND_DM,
        keyPairs: MockKeys.guest,
        content: 'YOLO',
      )))
].toList();
// var MOCK_GIFT_WRAPS = [
//   giftWrapAndSeal(
//       MockKeys.guest.public,
//       MockKeys.hoster,
//       NostrEvent.fromPartialData(
//         kind: NOSTR_KIND_DM,

//         /// Should unsigned if the Nostr lib would allow
//         keyPairs: NostrKeyPairs.generate(),
//         content: 'YOLO',
//       )),
// ].toList();
