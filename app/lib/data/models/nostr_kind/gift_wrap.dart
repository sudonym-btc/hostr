import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/core/constants.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';

import 'type_parent.dart';

class GiftWrap<T extends NostrEvent> extends ParentTypeNostrEvent<T> {
  static const List<int> kinds = [NOSTR_KIND_GIFT_WRAP];
  GiftWrap.fromNostrEvent(NostrEvent e, NostrKeyPairs key, Uri? nwc)
      : super(
            content: e.content,
            child: parser<T>(
                NostrEvent.deserialized(jsonEncode(
                    [NostrConstants.event, '', jsonDecode(e.content!)])),
                key,
                nwc), // Should decrypt here
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);

  static GiftWrap<T> typed<T extends NostrEvent>(
      NostrEvent e, NostrKeyPairs key, Uri? nwc) {
    return GiftWrap<T>.fromNostrEvent(e, NostrKeyPairs.generate(), null);
  }

  static GiftWrap create(String to, NostrKeyPairs from, Event event) {
    return GiftWrap.fromNostrEvent(
        NostrEvent.fromPartialData(
            kind: NOSTR_KIND_GIFT_WRAP,
            tags: [
              ['p', to]
            ],
            keyPairs: NostrKeyPairs.generate(),
            content: event.toString()),
        from,
        null
        // content: Nip04().encrypt(from.private, to,
        //     event.toString())), // Should be updated encryption technique
        );
  }
}

GiftWrap giftWrapAndSeal(
    String to, NostrKeyPairs from, NostrEvent event, Uri? nwc) {
  return GiftWrap.fromNostrEvent(
      NostrEvent.fromPartialData(
          keyPairs: NostrKeyPairs.generate(),
          kind: NOSTR_KIND_GIFT_WRAP,
          tags: [
            ['p', to]
          ],
          content: Seal.fromNostrEvent(
                  NostrEvent.fromPartialData(
                      kind: NOSTR_KIND_SEAL,
                      keyPairs: from,
                      content: event.toString()),
                  from,
                  nwc)
              .toString()),
      from,
      null);
}
