import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/core/constants.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/sources/main.dart';

import 'seal.dart';
import 'type_parent.dart';

class GiftWrap<T extends NostrEvent> extends ParentTypeNostrEvent<T> {
  static const List<int> kinds = [NOSTR_KIND_GIFT_WRAP];
  GiftWrap.fromNostrEvent(NostrEvent e)
      : super(
            content: e.content,
            child: parser<T>(NostrEvent.deserialized(jsonEncode(
                [NostrConstants.event, '', jsonDecode(e.content!)]))),
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

GiftWrap giftWrapAndSeal(String to, NostrKeyPairs from, NostrEvent event) {
  return GiftWrap.fromNostrEvent(NostrEvent.fromPartialData(
      kind: NOSTR_KIND_GIFT_WRAP,
      tags: [
        ['p', to]
      ],
      keyPairs: NostrKeyPairs.generate(),
      content: Seal.fromNostrEvent(
        NostrEvent.fromPartialData(
            kind: NOSTR_KIND_SEAL, keyPairs: from, content: event.toString()),
      ).toString()));
}
