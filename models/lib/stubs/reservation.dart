import 'package:models/main.dart';

var MOCK_RESERVATIONS = [
  Reservation(
      pubKey: MockKeys.hoster.publicKey,
      content: ReservationContent(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 5, 1),
        guestCommitmentHash: GuestParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          hostInvitesGuestReservationRequest.parsedContent.salt,
        ),
      ),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: [
        ['d', '1'],
        ['a', MOCK_LISTINGS[0].anchor!],
        ['a', hostInvitesGuest.reservationRequestAnchor!],
        [
          'guestCommitmentHash',
          GuestParticipationProof.computeCommitmentHash(
            MockKeys.guest.publicKey,
            hostInvitesGuestReservationRequest.parsedContent.salt,
          )
        ]
      ]).signAs(MockKeys.hoster, Reservation.fromNostrEvent),
  Reservation(
      pubKey: MockKeys.hoster.publicKey,
      content: ReservationContent(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 5, 1),
        guestCommitmentHash: GuestParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          guestInvitesHostReservationRequest.parsedContent.salt,
        ),
      ),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: [
        ['d', '2'],
        ['a', MOCK_LISTINGS[1].anchor!],
        ['a', guestRequest.reservationRequestAnchor!],
        [
          'guestCommitmentHash',
          GuestParticipationProof.computeCommitmentHash(
            MockKeys.guest.publicKey,
            guestInvitesHostReservationRequest.parsedContent.salt,
          )
        ]
      ]).signAs(MockKeys.hoster, Reservation.fromNostrEvent),
].toList();
