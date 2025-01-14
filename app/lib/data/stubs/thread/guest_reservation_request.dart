import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:hostr/config/constants.dart';

import '../../models/main.dart';
import '../keypairs.dart';

List<GiftWrap> MOCK_GUEST_RESERVATION_REQUEST = [
  giftWrapAndSeal(
      MockKeys.hoster.public,
      MockKeys.guest,
      Message.fromNostrEvent(NostrEvent.fromPartialData(
        kind: NOSTR_KIND_DM,
        keyPairs: MockKeys.guest,
        content: 'YOLO',
      )))
];
