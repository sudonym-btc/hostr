import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_ZAP_RECEIPTS = [
  // ZapReceipt.fromEvent(event)
  Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.hoster.publicKey,
          kind: NOSTR_KIND_ZAP_RECEIPT,
          tags: [
            ['bolt11', 'lnbc1m1p0zv9zvpp5'],
            ['preimage', 'preimage'],
            // recipient
            ['p', MockKeys.hoster.publicKey],
            // ['a', ]
            ['e', 'eventId'],
            ['anon', '0'],
            // Sender
            ['P', MockKeys.guest.publicKey],
            // ['description', ZapRequestJson]
          ],
          content: 'Tip for thee!')),
].toList();
