import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_REVIEWS = [
  Review.fromNostrEvent(
    Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.guest.privateKey!,
        event: Nip01Event(
            pubKey: MockKeys.guest.publicKey,
            content: json.encode(
              ReviewContent(
                rating: 5,
                content: 'I had a great time staying here!',
                proof: GuestParticipationProof(
                  salt: guestInvitesHostReservationRequest.parsedContent.salt,
                ),
                reservationId: MOCK_RESERVATIONS[0].id,
              ).toJson(),
            ),
            createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
            kind: NOSTR_KIND_REVIEW,
            tags: [
              [REFERENCE_RESERVATION_TAG, MOCK_RESERVATIONS[0].id],
              [REFERENCE_LISTING_TAG, MOCK_LISTINGS[0].anchor]
            ])),
  ),
].toList();
