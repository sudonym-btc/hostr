import 'dart:convert';
import 'dart:core';

import 'package:models/nostr_kinds.dart';
import 'package:models/nostr_parser.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'event.dart';
import 'seal.dart';
import 'type_parent.dart';

/// Define a type alias for the parser function
typedef NostrEventParser<T extends Event> = T Function(
    Nip01Event e, KeyPair key);

class GiftWrap<T extends Event> extends ParentTypeNostrEvent<T> {
  static const List<int> kinds = [NOSTR_KIND_GIFT_WRAP];
  GiftWrap.fromNostrEvent(super.e, KeyPair key)
      : super(child: parser(Nip01Event.fromJson(jsonDecode(e.content)), key));

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

GiftWrap giftWrapAndSeal(String to, KeyPair from, Nip01Event event, Uri? nwc) {
  KeyPair temp = Bip340.generatePrivateKey();
  // print('GiftWrap: $to, ${from.publicKey}');
  return GiftWrap.fromNostrEvent(
    Nip01Event(
        pubKey: temp.publicKey,
        kind: NOSTR_KIND_GIFT_WRAP,
        tags: [
          ['p', to]
        ],
        content: Seal.fromNostrEvent(
          Nip01Event(
              kind: NOSTR_KIND_SEAL,
              pubKey: from.publicKey,
              content: jsonEncode(event.toJson()),
              tags: []),
          from,
        ).toString())
      ..sign(temp.privateKey!),
    from,
  );
}
