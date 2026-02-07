import 'package:models/main.dart';

ReservationRequest hostInvitesGuestReservationRequest = ReservationRequest(
        tags: [
      [kListingRefTag, MOCK_LISTINGS[0].anchor!],
      ['d', '1'],
    ],
        createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
        content: ReservationRequestContent(
            start: DateTime(2026),
            end: DateTime(2026).add(Duration(days: 1)),
            quantity: 1,
            amount: Amount(currency: Currency.BTC, value: BigInt.from(1000000)),
            salt: 'random-salt-1'),
        pubKey: MockKeys.hoster.publicKey)
    .signAs(MockKeys.hoster, ReservationRequest.fromNostrEvent);

ReservationRequest guestInvitesHostReservationRequest = ReservationRequest(
        tags: [
      [kListingRefTag, MOCK_LISTINGS[0].anchor!],
      ['d', '2'],
    ],
        createdAt: DateTime(2026).millisecondsSinceEpoch ~/ 1000,
        content: ReservationRequestContent(
            start: DateTime(2026),
            end: DateTime(2026).add(Duration(days: 1)),
            quantity: 1,
            amount: Amount(currency: Currency.BTC, value: BigInt.from(1000000)),
            salt: 'random-salt-2'),
        pubKey: MockKeys.guest.publicKey)
    .signAs(MockKeys.guest, ReservationRequest.fromNostrEvent);

var MOCK_RESERVATION_REQUESTS = [
  hostInvitesGuestReservationRequest,
  guestInvitesHostReservationRequest,
];
