import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

class Seal extends NostrEvent {
  static List<int> kinds = [NOSTR_KIND_SEAL];
  Seal.fromNostrEvent(NostrEvent e)
      : super(
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}
