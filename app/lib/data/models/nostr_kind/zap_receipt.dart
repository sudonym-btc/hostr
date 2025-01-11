import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import 'type_json_content.dart';
import 'zap_request.dart';

class ZapReceipt extends JsonContentNostrEvent<ZapReceiptContent> {
  static List<int> kinds = [NOSTR_KIND_ZAP_RECEIPT];
  ZapReceipt.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: ZapReceiptContent.fromJson(json.decode(e.content!)),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

class ZapReceiptContent extends EventContent {
  final ZapRequest zapRequest;

  ZapReceiptContent({required this.zapRequest});

  static ZapReceiptContent fromJson(Map<String, dynamic> json) {
    return ZapReceiptContent(
      zapRequest:
          ZapRequest.fromNostrEvent(NostrEvent.deserialized(json.toString())),
    );
  }
}
