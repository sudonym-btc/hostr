import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../type_json_content.dart';

/// As well as this being a valid method (get_info), the content is also broadcastable on nostr to everyone as a different kind than a DM
class NwcInfo extends JsonContentNostrEvent<NwcInfoContent> {
  static const List<int> kinds = [NOSTR_KIND_NWC_INFO];
  NwcInfo.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: NwcInfoContent.fromJson(json.decode(e.content!)),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

class NwcInfoContent extends EventContent {
  final List<NwcMethods> supportedRequests;
  final List<NwcNotifications> supportedNotifications;

  NwcInfoContent(
      {required this.supportedRequests, required this.supportedNotifications});

  static NwcInfoContent fromJson(Map<String, dynamic> json) {
    return NwcInfoContent(
        supportedRequests: json['content'].split(' ').map(
            (cmd) => NwcMethods.values.firstWhere((e) => e.toString() == cmd)),
        supportedNotifications: json['tags']
            .firstWhere((e) => e[0] == 'notifications')
            .map((e) => e[1])
            .split(' ')
            .map((cmd) => NwcNotifications.values
                .firstWhere((e) => e.toString() == cmd)));
  }
}

enum NwcMethods {
  pay_invoice,
  multi_pay_invoice,
  pay_keysend,
  multi_pay_keysend,
  make_invoice,
  lookup_invoice,
  list_transactions,
  get_balance,
  get_info,
  sign_message
}

enum NwcNotifications {
  payment_received,
  payment_sent,
}

enum NwcErrors {
  RATE_LIMITED,
  NOT_IMPLEMENTED,
  INSUFFICIENT_BALANCE,
  QUOTA_EXCEEDED,
  RESTRICTED,
  UNAUTHORIZED,
  INTERNAL,
  OTHER,
  NOT_FOUND
}
