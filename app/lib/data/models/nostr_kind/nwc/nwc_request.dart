import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/util/nip04.dart';
import 'package:hostr/logic/services/nwc.dart';

import '../type_json_content.dart';
import 'nwc_info.dart';
import 'nwc_method_types.dart';

class NwcRequest extends JsonContentNostrEvent<NwcRequestContent> {
  static const List<int> kinds = [NOSTR_KIND_NWC_REQUEST];
  NwcRequest.fromNostrEvent(NostrEvent e, Uri nwc)
      : super(
            parsedContent: NwcRequestContent.fromJson(json.decode(Nip04()
                .decrypt(parseSecret(nwc), parsePubkey(nwc), e.content!))),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

class NwcRequestContent extends EventContent {
  final NwcMethods method;
  final NwcMethodParams params;

  NwcRequestContent({required this.method, required this.params});

  static NwcRequestContent fromJson(Map<String, dynamic> json) {
    NwcMethods m = NwcMethods.values
        .firstWhere((e) => e.toString().split('.').last == json['method']);

    switch (m) {
      case NwcMethods.pay_invoice:
        return NwcRequestContent(
          method: m,
          params: NwcMethodPayInvoiceParams.fromJson(json['params']),
        );
      case NwcMethods.make_invoice:
        return NwcRequestContent(
          method: m,
          params: NwcMethodMakeInvoiceParams.fromJson(json['params']),
        );
      case NwcMethods.lookup_invoice:
        return NwcRequestContent(
          method: m,
          params: NwcMethodLookupInvoiceParams.fromJson(json['params']),
        );
      case NwcMethods.get_balance:
        return NwcRequestContent(
          method: m,
          params: NwcMethodGetBalanceParams.fromJson(json['params']),
        );
      case NwcMethods.get_info:
        return NwcRequestContent(
          method: m,
          params: NwcMethodGetInfoParams.fromJson(json['params']),
        );
      default:
        throw Exception('Unknown method');
    }
  }

  toJson() {
    return {
      'method': method.toString(),
      'params': params.toJson(),
    };
  }
}
