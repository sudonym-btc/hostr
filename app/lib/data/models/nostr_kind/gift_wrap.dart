import 'dart:convert';
import 'dart:core';

import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'type_parent.dart';

class GiftWrap<T extends Event> extends ParentTypeNostrEvent<T> {
  static const List<int> kinds = [NOSTR_KIND_GIFT_WRAP];
  GiftWrap.fromNostrEvent(super.e, KeyPair key)
      : super(
            child: parser<T>(Nip01Event.fromJson(jsonDecode(e.content)), key));

  static GiftWrap<T> typed<T extends Event>(
      Nip01Event e, KeyPair key, Uri? nwc) {
    return GiftWrap<T>.fromNostrEvent(e, key);
  }

  static GiftWrap create(String to, KeyPair from, Event event) {
    return GiftWrap.fromNostrEvent(
      Nip01Event(
          kind: NOSTR_KIND_GIFT_WRAP,
          tags: [
            ['p', to]
          ],
          pubKey: from.publicKey,
          content: event.toString()),
      from,

      // content: Nip04().encrypt(from.private, to,
      //     event.toString())), // Should be updated encryption technique
    );
  }
}

GiftWrap giftWrapAndSeal(String to, KeyPair from, Event event, Uri? nwc) {
  return GiftWrap.fromNostrEvent(
    Nip01Event(
        pubKey: Bip340.generatePrivateKey().publicKey,
        kind: NOSTR_KIND_GIFT_WRAP,
        tags: [
          ['p', to]
        ],
        content: Seal.fromNostrEvent(
          Nip01Event(
              kind: NOSTR_KIND_SEAL,
              pubKey: from.publicKey,
              content: event.toString(),
              tags: []),
          from,
        ).toString())
      ..sign(Bip340.generatePrivateKey().privateKey!),
    from,
  );
}
