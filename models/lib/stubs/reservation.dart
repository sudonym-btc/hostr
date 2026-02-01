import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_RESERVATIONS = [
  Reservation.fromNostrEvent(Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.hoster.publicKey,
          content: json.encode(ReservationContent(
            start: DateTime(2025, 1, 1),
            end: DateTime(2025, 5, 1),
            guestCommitmentHash: GuestParticipationProof.computeCommitmentHash(
              MockKeys.guest.publicKey,
              hostInvitesGuestReservationRequest.parsedContent.salt,
            ),
          ).toJson()),
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          kind: NOSTR_KIND_RESERVATION,
          tags: [
            [REFERENCE_LISTING_TAG, MOCK_LISTINGS[0].anchor],
            [
              'guestCommitmentHash',
              GuestParticipationProof.computeCommitmentHash(
                MockKeys.guest.publicKey,
                hostInvitesGuestReservationRequest.parsedContent.salt,
              )
            ]
          ]))),
  Reservation.fromNostrEvent(Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.hoster.publicKey,
          content: json.encode(ReservationContent(
            start: DateTime(2025, 1, 1),
            end: DateTime(2025, 5, 1),
            guestCommitmentHash: GuestParticipationProof.computeCommitmentHash(
              MockKeys.guest.publicKey,
              guestInvitesHostReservationRequest.parsedContent.salt,
            ),
          ).toJson()),
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          kind: NOSTR_KIND_RESERVATION,
          tags: [
            [REFERENCE_LISTING_TAG, MOCK_LISTINGS[1].anchor],
            [
              'guestCommitmentHash',
              GuestParticipationProof.computeCommitmentHash(
                MockKeys.guest.publicKey,
                guestInvitesHostReservationRequest.parsedContent.salt,
              )
            ]
          ]))),
].toList();
