import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@Injectable(env: Env.allButTestAndMock)
class ZapService {
  CustomLogger logger = CustomLogger();
  KeyStorage keyStorage = getIt<KeyStorage>();

  generateZapRequestEvent({
    required String recipientPubkey,
    required String lnurl,
    required int amountSats,
    required List<String> relays,
    String? content,
    String? eventId,
  }) async {
    NostrKeyPairs? keyPairs = await keyStorage.getActiveKeyPair();
    return NostrEvent.fromPartialData(
        kind: 9734,
        tags: [
          ["relays", ...relays],
          ["amount", (amountSats * 1000).toString()],
          ["lnurl", lnurl],
          ["p", recipientPubkey],
          if (eventId != null) ["e", eventId]
        ],
        content: content ?? "",
        keyPairs: keyPairs!);
  }

  getZapInvoice({
    required String callback,
    required String recipientPubkey,
    required String lnurl,
    required int amountSats,
    required List<String> relays,
    String? content,
    String? eventId,
  }) async {
    NostrEvent event = generateZapRequestEvent(
        recipientPubkey: recipientPubkey,
        lnurl: lnurl,
        amountSats: amountSats,
        relays: relays,
        content: content,
        eventId: eventId);

    String eventString = Uri.encodeQueryComponent(json.encode(event));

    var result = await http.get(Uri.parse(
        "$callback?amount=${amountSats * 1000}&nostr=$event&lnurl=$lnurl"));

    if (result.statusCode >= 300) {
      throw Exception("Failed to get invoice");
    }
    String? pr = json.decode(result.body)['pr'];
    if (pr == null) {
      throw Exception("Failed to get invoice");
    }
    return pr;
  }
}
