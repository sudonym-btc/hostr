import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../type_json_content.dart';
import 'nwc_method_types.dart';

/// As well as this being a valid method (get_info), the content is also broadcastable on nostr to everyone as a different kind than a DM
/// The info is split between notification tag and raw content though, so has to be parsed differently
class NwcInfo extends JsonContentNostrEvent<NwcMethodGetInfoResponse> {
  static const List<int> kinds = [NOSTR_KIND_NWC_INFO];
  NwcInfo.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: NwcMethodGetInfoResponse(
                methods: e.content!
                    .split(' ')
                    .where((m) => NwcMethods.values
                        .any((e) => e.toString().split('.').last == m))
                    .map((m) => NwcMethods.values
                        .firstWhere((e) => e.toString().split('.').last == m))
                    .toList(),
                notifications: e.tags
                        ?.firstWhere((e) => e[0] == 'notifications')
                        .map((e) => e[1])
                        .toString()
                        .split(' ')
                        .where((m) => NwcNotifications.values
                            .any((e) => e.toString().split('.').last == m))
                        .map((m) => NwcNotifications.values.firstWhere(
                            (e) => e.toString().split('.').last == m))
                        .toList() ??
                    <NwcNotifications>[]),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
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
