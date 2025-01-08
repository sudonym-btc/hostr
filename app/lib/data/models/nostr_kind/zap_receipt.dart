import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../event.dart';

class ZapReceipt extends Event<NostrEvent> {
  static List<int> kinds = [NOSTR_KIND_ZAP_RECEIPT];
  ZapReceipt.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: NostrEvent.deserialized(e.content!),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}
