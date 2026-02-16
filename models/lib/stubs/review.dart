import 'package:models/main.dart';
import 'package:models/stubs/main.dart';

var MOCK_REVIEWS = [
  Review(
    pubKey: MockKeys.guest.publicKey,
    content: ReviewContent(
      rating: 5,
      content: 'I had a great time staying here!',
      proof: ParticipationProof(
        salt: guestInvitesHostReservationRequest.parsedContent.salt,
      ),
    ),
    tags: [
      [kListingRefTag, MOCK_LISTINGS[0].anchor!],
      [kReservationRefTag, MOCK_RESERVATIONS[0].anchor!],
    ],
    createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
  ).signAs(MockKeys.guest, Review.fromNostrEvent)
].toList();
