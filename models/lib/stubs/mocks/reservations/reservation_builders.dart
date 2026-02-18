import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

ReservationRequest buildReservationRequestForScenario({
  required Listing listing,
  required KeyPair sender,
  required String dTag,
  DateTime? start,
  DateTime? end,
  Amount? amount,
  int createdAtYear = 2026,
}) {
  final content = ReservationRequestContent(
    start: start ?? DateTime(createdAtYear, 1, 10),
    end: end ?? DateTime(createdAtYear, 1, 12),
    quantity: 1,
    amount: amount ?? listing.parsedContent.price.first.amount,
    salt: 'salt-$dTag',
  );

  return ReservationRequest(
    tags: ReservationRequestTags([
      [kListingRefTag, listing.anchor!],
      ['d', dTag],
    ]),
    createdAt: DateTime(createdAtYear).millisecondsSinceEpoch ~/ 1000,
    content: content,
    pubKey: sender.publicKey,
  ).signAs(sender, ReservationRequest.fromNostrEvent);
}

Reservation buildReservationForScenario({
  required Listing listing,
  required ReservationRequest request,
  required KeyPair signer,
  required String dTag,
  SelfSignedProof? proof,
  String? status,
  DateTime? createdAt,
}) {
  final commitment = ParticipationProof.computeCommitmentHash(
    request.pubKey,
    request.parsedContent.salt,
  );

  return Reservation(
    pubKey: signer.publicKey,
    content: ReservationContent(
      start: request.parsedContent.start,
      end: request.parsedContent.end,
      proof: proof,
    ),
    createdAt:
        (createdAt ?? DateTime(2026, 1, 11)).millisecondsSinceEpoch ~/ 1000,
    tags: ReservationTags([
      [kListingRefTag, listing.anchor!],
      [kThreadRefTag, request.anchor!],
      [kCommitmentHashTag, commitment],
      ['d', dTag],
      if (status != null) ['status', status],
    ]),
  ).signAs(signer, Reservation.fromNostrEvent);
}

SelfSignedProof buildSelfSignedProof({
  required Listing listing,
  ZapProof? zapProof,
  EscrowProof? escrowProof,
}) {
  return SelfSignedProof(
    hoster: MOCK_PROFILES.first,
    listing: listing,
    zapProof: zapProof,
    escrowProof: escrowProof,
  );
}
