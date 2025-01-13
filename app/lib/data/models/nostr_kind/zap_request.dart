import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

class ZapRequest extends NostrEvent {
  static const List<int> kinds = [NOSTR_KIND_ZAP_RECEIPT];
  ZapRequest.fromNostrEvent(NostrEvent e)
      : super(
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}
