import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:ndk/ndk.dart';

Nip01Event hostInvitesGuest = Nip01Event(
    pubKey: MockKeys.hoster.publicKey,
    kind: NOSTR_KIND_DM,
    tags: [
      ['a', 'random-topic-id'],
      [
        'p',
        MockKeys.guest.publicKey,
      ]
    ],
    content: ReservationRequest.fromNostrEvent(Nip01Event(
            kind: NOSTR_KIND_RESERVATION_REQUEST,
            tags: [
              ['a', MOCK_LISTINGS[0].anchor],
            ],
            content: ReservationRequestContent(
                    start: DateTime.now(),
                    end: DateTime.now().add(Duration(days: 1)),
                    quantity: 1,
                    amount: Amount(currency: Currency.BTC, value: 0.0001),
                    commitmentHash: 'hash',
                    commitmentHashPreimageEnc: 'does')
                .toString(),
            pubKey: MockKeys.hoster.publicKey)
          ..sign(MockKeys.hoster.privateKey!))
        .toString());

var MOCK_GIFT_WRAPS = [
  /// Must send GiftWraps to yourself and recipient
  ...[
    // giftWrapAndSeal(
    //     MockKeys.guest.public,
    //     MockKeys.hoster,
    //     Message.fromNostrEvent(
    //         NostrEvent.fromPartialData(
    //             kind: NOSTR_KIND_DM,
    //             keyPairs: MockKeys.guest,
    //             content: 'YOLO',
    //             tags: [
    //               ['a', 'random-anchor']
    //             ]),
    //         null,
    //         null),
    //     null),
    // giftWrapAndSeal(
    //     MockKeys.hoster.public,
    //     MockKeys.hoster,
    //     Message.fromNostrEvent(
    //         NostrEvent.fromPartialData(
    //             kind: NOSTR_KIND_DM,
    //             keyPairs: MockKeys.guest,
    //             content: 'YOLO',
    //             tags: [
    //               ['a', 'random-anchor']
    //             ]),
    //         null,
    //         null),
    //     null)
  ],
  ...[
    giftWrapAndSeal(
        MockKeys.guest.publicKey, MockKeys.hoster, hostInvitesGuest, null),
    giftWrapAndSeal(
        MockKeys.hoster.publicKey, MockKeys.hoster, hostInvitesGuest, null)
  ]
].toList();
// var MOCK_GIFT_WRAPS = [
//   giftWrapAndSeal(
//       MockKeys.guest.public,
//       MockKeys.hoster,
//       NostrEvent.fromPartialData(
//         kind: NOSTR_KIND_DM,

//         /// Should unsigned if the Nostr lib would allow
//         keyPairs: NostrKeyPairs.generate(),
//         content: 'YOLO',
//       )),
// ].toList();
