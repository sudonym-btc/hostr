import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

ReservationRequest hostInvitesGuestReservationRequest =
    ReservationRequest.fromNostrEvent(Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.hoster.privateKey!,
        event: Nip01Event(
            kind: NOSTR_KIND_RESERVATION_REQUEST,
            tags: [
              [REFERENCE_LISTING_TAG, MOCK_LISTINGS[0].anchor],
            ],
            createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
            content: ReservationRequestContent(
                    start: DateTime(2026),
                    end: DateTime(2026).add(Duration(days: 1)),
                    quantity: 1,
                    amount: Amount(currency: Currency.BTC, value: 0.0001),
                    salt: 'random-salt-1')
                .toString(),
            pubKey: MockKeys.hoster.publicKey)));

ReservationRequest guestInvitesHostReservationRequest =
    ReservationRequest.fromNostrEvent(Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.guest.privateKey!,
        event: Nip01Event(
            kind: NOSTR_KIND_RESERVATION_REQUEST,
            tags: [
              [REFERENCE_LISTING_TAG, MOCK_LISTINGS[0].anchor],
            ],
            createdAt: DateTime(2026).millisecondsSinceEpoch ~/ 1000,
            content: ReservationRequestContent(
                    start: DateTime(2026),
                    end: DateTime(2026).add(Duration(days: 1)),
                    quantity: 1,
                    amount: Amount(currency: Currency.BTC, value: 0.0001),
                    salt: 'random-salt-2')
                .toString(),
            pubKey: MockKeys.guest.publicKey)));

var MOCK_RESERVATION_REQUESTS = [
  hostInvitesGuestReservationRequest,
  guestInvitesHostReservationRequest,
];
