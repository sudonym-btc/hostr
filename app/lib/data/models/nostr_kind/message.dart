import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/constants.dart';

import 'event.dart';

class Message extends Event {
  static const List<int> kinds = [NOSTR_KIND_DM];

  Message.fromNostrEvent(NostrEvent e, NostrKeyPairs? key, Uri? nwc)
      : super(
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}
