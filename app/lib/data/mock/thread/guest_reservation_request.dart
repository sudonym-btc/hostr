import 'package:dart_nostr/nostr/core/key_pairs.dart';
import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:hostr/config/constants.dart';

import '../../models/main.dart';
import '../keypairs.dart';

List<GiftWrap> MOCK_GUEST_RESERVATION_REQUEST = [
  GiftWrap.fromNostrEvent(NostrEvent.fromPartialData(
      kind: NOSTR_KIND_GIFT_WRAP,
      keyPairs: NostrKeyPairs.generate(),
      content: Seal.fromNostrEvent(
        NostrEvent.fromPartialData(
            kind: NOSTR_KIND_SEAL,
            keyPairs: MockKeys.guest,
            content: Message.fromNostrEvent(NostrEvent.fromPartialData(
              kind: NOSTR_KIND_DM,
              keyPairs: MockKeys.guest,
              content: 'YOLO',
            )).toString()),
      ).toString()))
];
