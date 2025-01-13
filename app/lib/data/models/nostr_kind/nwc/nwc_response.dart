import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../type_json_content.dart';
import 'nwc_info.dart';
import 'nwc_method_types.dart';

class NwcResponse extends JsonContentNostrEvent<NwcResponseContent> {
  static const List<int> kinds = [NOSTR_KIND_NWC_RESPONSE];
  NwcResponse.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: NwcResponseContent.fromJson(json.decode(e.content!)),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

class NwcResponseContent extends EventContent {
  final NwcMethods result_type;
  final NwcMethodParams result;

  NwcResponseContent({required this.result_type, required this.result});

  static NwcResponseContent fromJson(Map<String, dynamic> json) {
    NwcMethods m =
        NwcMethods.values.firstWhere((e) => e.toString() == json['method']);

    switch (m) {
      case NwcMethods.pay_invoice:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodPayInvoiceParams.fromJson(json['params']),
        );
      case NwcMethods.make_invoice:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodMakeInvoiceParams.fromJson(json['params']),
        );
      case NwcMethods.lookup_invoice:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodLookupInvoiceParams.fromJson(json['params']),
        );
      case NwcMethods.get_balance:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodGetBalanceParams.fromJson(json['params']),
        );
      case NwcMethods.get_info:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodGetInfoParams.fromJson(json['params']),
        );
      default:
        throw Exception('Unknown method');
    }
  }
}
