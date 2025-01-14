import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/core/constants.dart';
import 'package:hostr/config/main.dart';

import 'type_parent.dart';

class Seal extends ParentTypeNostrEvent {
  static const List<int> kinds = [NOSTR_KIND_SEAL];
  Seal.fromNostrEvent(NostrEvent e, NostrKeyPairs key, parser)
      : super(
            content: e.content,
            child: parser<NostrEvent>(NostrEvent.deserialized(jsonEncode(
                [NostrConstants.event, '', jsonDecode(e.content!)]))),
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}
