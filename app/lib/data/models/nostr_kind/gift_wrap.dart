import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/core/constants.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/models/nostr_kind/type_parent.dart';
import 'package:hostr/data/sources/nostr/nostr_provider/nostr_provider.dart';

class GiftWrap<T extends NostrEvent> extends ParentTypeNostrEvent<T> {
  static List<int> kinds = [NOSTR_KIND_GIFT_WRAP];
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
