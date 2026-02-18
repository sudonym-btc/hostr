import 'package:models/main.dart';
import 'package:models/stubs/main.dart';

var MOCK_RESERVATIONS = [
  Reservation(
      pubKey: MockKeys.hoster.publicKey,
      content: ReservationContent(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 5, 1),
      ),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: ReservationTags([
        [kListingRefTag, MOCK_LISTINGS[0].anchor!],
        [kThreadRefTag, hostInvitesGuest.parsedTags.threadAnchor],
        ['d', '1'],
        [
          kCommitmentHashTag,
          ParticipationProof.computeCommitmentHash(
            MockKeys.guest.publicKey,
            hostInvitesGuestReservationRequest.parsedContent.salt,
          )
        ]
      ])).signAs(MockKeys.hoster, Reservation.fromNostrEvent),
  Reservation(
      pubKey: MockKeys.hoster.publicKey,
      content: ReservationContent(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 5, 1),
      ),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: ReservationTags([
        [kListingRefTag, MOCK_LISTINGS[1].anchor!],
        [kThreadRefTag, guestRequest.parsedTags.threadAnchor],
        ['d', '2'],
        [
          kCommitmentHashTag,
          ParticipationProof.computeCommitmentHash(
            MockKeys.guest.publicKey,
            guestInvitesHostReservationRequest.parsedContent.salt,
          )
        ]
      ])).signAs(MockKeys.hoster, Reservation.fromNostrEvent),
].toList();
