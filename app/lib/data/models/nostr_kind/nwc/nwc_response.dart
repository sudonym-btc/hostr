import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/util/nip04.dart';
import 'package:hostr/logic/services/nwc.dart';

import '../type_json_content.dart';
import 'nwc_info.dart';
import 'nwc_method_types.dart';

class NwcResponse extends JsonContentNostrEvent<NwcResponseContent> {
  static const List<int> kinds = [NOSTR_KIND_NWC_RESPONSE];
  NwcResponse.fromNostrEvent(NostrEvent e, Uri nwc)
      : super(
            parsedContent: NwcResponseContent.fromJson(json.decode(Nip04()
                .decrypt(parseSecret(nwc), parsePubkey(nwc), e.content!))),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);

  static NwcResponse create(
      String requestEventId, String to, NwcResponseContent content, Uri nwc) {
    String contentStr = content.toString();
    String encryptedContent =
        Nip04().encrypt(parseSecret(nwc), parsePubkey(nwc), contentStr);
    return NwcResponse.fromNostrEvent(
        NostrEvent.fromPartialData(
            tags: [
              ['e', requestEventId]
            ],
            kind: NOSTR_KIND_NWC_RESPONSE,
            content: encryptedContent,
            keyPairs: Nostr.instance.keysService
                .generateKeyPairFromExistingPrivateKey(parseSecret(nwc))),
        nwc);
  }
}

class NwcResponseContent extends EventContent {
  final NwcMethods result_type;
  final NwcMethodResponse result;

  NwcResponseContent({required this.result_type, required this.result});

  static NwcResponseContent fromJson(Map<String, dynamic> json) {
    NwcMethods m = NwcMethods.values
        .firstWhere((e) => e.toString().split('.').last == json['result_type']);

    switch (m) {
      case NwcMethods.pay_invoice:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodPayInvoiceResponse.fromJson(json['result']),
        );
      case NwcMethods.make_invoice:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodMakeInvoiceResponse.fromJson(json['result']),
        );
      case NwcMethods.lookup_invoice:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodLookupInvoiceResponse.fromJson(json['result']),
        );
      case NwcMethods.get_balance:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodGetBalanceResponse.fromJson(json['result']),
        );
      case NwcMethods.get_info:
        return NwcResponseContent(
          result_type: m,
          result: NwcMethodGetInfoResponse.fromJson(json['result']),
        );
      default:
        throw Exception('Unknown method');
    }
  }

  @override
  toJson() {
    return {
      'result_type': result_type.toString().split('.').last,
      'result': result.toJson()
    };
  }
}
