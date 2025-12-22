import 'package:dio/dio.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

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
    KeyPair? keyPairs = await keyStorage.getActiveKeyPair();
    return Nip01Event.fromJson({
      "kind": 9734,
      "tags": [
        ["relays", ...relays],
        ["amount", (amountSats * 1000).toString()],
        ["lnurl", lnurl],
        ["p", recipientPubkey],
        if (eventId != null) ["e", eventId],
      ],
      "content": content ?? "",
      "keyPairs": keyPairs!,
    });
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
    Nip01Event event = generateZapRequestEvent(
      recipientPubkey: recipientPubkey,
      lnurl: lnurl,
      amountSats: amountSats,
      relays: relays,
      content: content,
      eventId: eventId,
    );

    var result = await getIt<Dio>().get(
      "$callback?amount=${amountSats * 1000}&nostr=$event&lnurl=$lnurl",
    );

    if (result.statusCode! >= 300) {
      throw Exception("Failed to get invoice");
    }
    String? pr = result.data['pr'];
    if (pr == null) {
      throw Exception("Failed to get invoice");
    }
    return pr;
  }
}
