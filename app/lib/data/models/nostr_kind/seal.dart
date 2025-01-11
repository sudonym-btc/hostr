import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/models/nostr_kind/type_parent.dart';

class Seal extends ParentTypeNostrEvent {
  static List<int> kinds = [NOSTR_KIND_SEAL];
  Seal.fromNostrEvent(NostrEvent e)
      : super(
            content: e.content,
            child: NostrEvent.deserialized(e.content!),
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}
