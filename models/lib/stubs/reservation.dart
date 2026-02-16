import 'package:models/main.dart';
import 'package:models/stubs/main.dart';

var MOCK_RESERVATIONS = [
  Reservation(
      pubKey: MockKeys.hoster.publicKey,
      content: ReservationContent(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 5, 1),
        commitmentHash: ParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          hostInvitesGuestReservationRequest.parsedContent.salt,
        ),
      ),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: [
        [kListingRefTag, MOCK_LISTINGS[0].anchor!],
        [kThreadRefTag, hostInvitesGuest.threadAnchor],
        ['d', '1'],
        [
          'guestCommitmentHash',
          ParticipationProof.computeCommitmentHash(
            MockKeys.guest.publicKey,
            hostInvitesGuestReservationRequest.parsedContent.salt,
          )
        ]
      ]).signAs(MockKeys.hoster, Reservation.fromNostrEvent),
  Reservation(
      pubKey: MockKeys.hoster.publicKey,
      content: ReservationContent(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 5, 1),
        commitmentHash: ParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          guestInvitesHostReservationRequest.parsedContent.salt,
        ),
      ),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: [
        [kListingRefTag, MOCK_LISTINGS[1].anchor!],
        [kThreadRefTag, guestRequest.threadAnchor],
        ['d', '2'],
        [
          'guestCommitmentHash',
          ParticipationProof.computeCommitmentHash(
            MockKeys.guest.publicKey,
            guestInvitesHostReservationRequest.parsedContent.salt,
          )
        ]
      ]).signAs(MockKeys.hoster, Reservation.fromNostrEvent),
].toList();

final FAKED_RESERVATIONS = List.generate(10, (count) {
  return Reservation(
      pubKey: mockKeys[count].publicKey,
      content: ReservationContent(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 5, 1),
        commitmentHash: ParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          guestInvitesHostReservationRequest.parsedContent.salt,
        ),
      ),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: [
        [kListingRefTag, FAKED_LISTINGS[count].anchor!],
        [kThreadRefTag, guestRequest.threadAnchor],
        ['d', count.toString()],
        [
          'guestCommitmentHash',
          ParticipationProof.computeCommitmentHash(
            MockKeys.guest.publicKey,
            guestInvitesHostReservationRequest.parsedContent.salt,
          )
        ]
      ]).signAs(mockKeys[count], Reservation.fromNostrEvent);
});
