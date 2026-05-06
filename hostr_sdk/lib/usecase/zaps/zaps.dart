import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' hide Nwc, Requests;

import '../../config.dart';
import '../../injection.dart';
import '../../util/stream_status.dart';
import '../nwc/nwc.dart';
import '../requests/requests.dart';

@Singleton(env: Env.allButTestAndMock)
class Zaps {
  final Nwc nwc;
  final Ndk ndk;
  final HostrConfig? _config;
  final Requests? _requests;

  Zaps({
    required this.nwc,
    required this.ndk,
    HostrConfig? config,
    Requests? requests,
  }) : _config = config,
       _requests = requests;

  List<String> _zapReceiptRelays() => _config?.bootstrapRelays ?? const [];

  Future<ZapResponse> zap({required String lnurl, required int amountSats}) {
    return ndk.zaps.zap(
      nwcConnection: nwc.connections[0].connection!,
      lnurl: lnurl,
      amountSats: amountSats,
    );
  }

  Future<InvoiceResponse?> fetchInvoice({
    required String lud16Link,
    required int amountSats,
    ZapRequest? zapRequest,
  }) {
    return ndk.zaps.fetchInvoice(
      lud16Link: lud16Link,
      amountSats: amountSats,
      zapRequest: zapRequest,
    );
  }

  StreamWithStatus<Nip01Event> subscribeZapReceipts({
    required String pubkey,
    String? eventId,
    String? addressableId,
    int? limit,
  }) {
    if (limit != null && limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }

    final requests = _requests;
    if (requests == null) {
      throw StateError('Cannot subscribe to zap receipts without Requests');
    }
    return requests.subscribe<Nip01Event>(
      filter: Filter(
        kinds: [ZapReceipt.kKind],
        eTags: eventId != null ? [eventId] : null,
        aTags: addressableId != null ? [addressableId] : null,
        pTags: [pubkey],
        limit: limit,
      ),
      relays: _zapReceiptRelays(),
      name: 'ZapReceipts-sub',
    );
  }
}

@Singleton(as: Zaps, env: [Env.test, Env.mock])
class MockZaps extends Zaps {
  MockZaps({
    required super.nwc,
    required super.ndk,
    super.config,
    super.requests,
  });

  @override
  fetchInvoice({
    required String lud16Link,
    required int amountSats,
    ZapRequest? zapRequest,
  }) async {
    return InvoiceResponse(invoice: '', amountSats: amountSats);
  }
}

// generateZapRequestEvent({
//   required String recipientPubkey,
//   required String lnurl,
//   required int amountSats,
//   required List<String> relays,
//   String? content,
//   String? eventId,
// }) async {
//   KeyPair? keyPairs = await keyStorage.getActiveKeyPair();
//   return Nip01EventModel.fromJson({
//     "kind": 9734,
//     "tags": [
//       ["relays", ...relays],
//       ["amount", (amountSats * 1000).toString()],
//       ["lnurl", lnurl],
//       ["p", recipientPubkey],
//       if (eventId != null) ["e", eventId],
//     ],
//     "content": content ?? "",
//     "keyPairs": keyPairs!,
//   });
// }

// getZapInvoice({
//   required String callback,
//   required String recipientPubkey,
//   required String lnurl,
//   required int amountSats,
//   required List<String> relays,
//   String? content,
//   String? eventId,
// }) async {
//   Nip01Event event = generateZapRequestEvent(
//     recipientPubkey: recipientPubkey,
//     lnurl: lnurl,
//     amountSats: amountSats,
//     relays: relays,
//     content: content,
//     eventId: eventId,
//   );

//   var result = await getIt<Dio>().get(
//     "$callback?amount=${amountSats * 1000}&nostr=$event&lnurl=$lnurl",
//   );

//   if (result.statusCode! >= 300) {
//     throw Exception("Failed to get invoice");
//   }
//   String? pr = result.data['pr'];
//   if (pr == null) {
//     throw Exception("Failed to get invoice");
//   }
//   return pr;
// }
