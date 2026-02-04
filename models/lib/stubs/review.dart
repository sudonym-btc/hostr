import 'package:models/main.dart';

var MOCK_REVIEWS = [
  Review(
    pubKey: MockKeys.guest.publicKey,
    content: ReviewContent(
      rating: 5,
      content: 'I had a great time staying here!',
      proof: GuestParticipationProof(
        salt: guestInvitesHostReservationRequest.parsedContent.salt,
      ),
      reservationId: MOCK_RESERVATIONS[0].id,
    ),
    tags: [
      [kListingRefTag, MOCK_LISTINGS[0].anchor!],
      [kReservationRefTag, MOCK_RESERVATIONS[0].anchor!],
    ],
    createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
  ).signAs(MockKeys.guest, Review.fromNostrEvent)
].toList();
