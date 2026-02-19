import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

ReservationRequest buildReservationRequest({
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

Message<ReservationRequest> buildReservationRequestMessage({
  required ReservationRequest request,
  required KeyPair sender,
  required String recipientPubkey,
  DateTime? createdAt,
}) {
  return Message<ReservationRequest>(
    pubKey: sender.publicKey,
    tags: MessageTags([
      ['p', recipientPubkey],
      [kThreadRefTag, request.anchor!],
    ]),
    createdAt: (createdAt ?? DateTime(2026)).millisecondsSinceEpoch ~/ 1000,
    child: request,
  );
}

PaymentProof buildSelfSignedZapProof({
  required Listing listing,
}) {
  return PaymentProof(
    hoster: MOCK_PROFILES.first,
    listing: listing,
    zapProof: null,
    escrowProof: null,
  );
}

Reservation buildReservation({
  required Listing listing,
  required ReservationRequest request,
  required KeyPair signer,
  required String dTag,
  PaymentProof? proof,
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
      ['d', dTag],
      [kCommitmentHashTag, commitment],
      if (status != null) ['status', status],
    ]),
  ).signAs(signer, Reservation.fromNostrEvent);
}

ThreadScenario buildPendingGuestToHostScenario() {
  final listing = MOCK_LISTINGS.first;
  final reservationRequest = buildReservationRequest(
    listing: listing,
    sender: MockKeys.guest,
    dTag: 'thread-pending',
  );

  final requestMessage = buildReservationRequestMessage(
    request: reservationRequest,
    sender: MockKeys.guest,
    recipientPubkey: MockKeys.hoster.publicKey,
  );

  return ThreadScenario(
    id: 'thread-pending',
    description: 'Pending reservation request from guest to host',
    listing: listing,
    reservationRequest: reservationRequest,
    requestMessage: requestMessage,
    reservations: const [],
    paid: false,
    refunded: false,
    cancelled: false,
  );
}

ThreadScenario buildPaidGuestToHostScenario() {
  final listing = MOCK_LISTINGS.first;
  final reservationRequest = buildReservationRequest(
    listing: listing,
    sender: MockKeys.guest,
    dTag: 'thread-paid',
  );

  final requestMessage = buildReservationRequestMessage(
    request: reservationRequest,
    sender: MockKeys.guest,
    recipientPubkey: MockKeys.hoster.publicKey,
  );

  return ThreadScenario(
    id: 'thread-paid',
    description: 'Paid reservation request from guest to host',
    listing: listing,
    reservationRequest: reservationRequest,
    requestMessage: requestMessage,
    reservations: const [],
    paid: true,
    refunded: false,
    cancelled: false,
  );
}

ThreadScenario buildSelfSignedGuestToHostScenario() {
  final listing = MOCK_LISTINGS.first;
  final reservationRequest = buildReservationRequest(
    listing: listing,
    sender: MockKeys.guest,
    dTag: 'thread-self-signed',
  );

  final requestMessage = buildReservationRequestMessage(
    request: reservationRequest,
    sender: MockKeys.guest,
    recipientPubkey: MockKeys.hoster.publicKey,
  );

  final reservation = buildReservation(
    listing: listing,
    request: reservationRequest,
    signer: MockKeys.guest,
    dTag: 'reservation-self-signed',
    proof: buildSelfSignedZapProof(listing: listing),
  );

  return ThreadScenario(
    id: 'thread-self-signed',
    description: 'Guest self-signed proof of reservation',
    listing: listing,
    reservationRequest: reservationRequest,
    requestMessage: requestMessage,
    reservations: [reservation],
    paid: true,
    refunded: false,
    cancelled: false,
  );
}

ThreadScenario buildConfirmedGuestToHostScenario() {
  final listing = MOCK_LISTINGS.first;
  final reservationRequest = buildReservationRequest(
    listing: listing,
    sender: MockKeys.guest,
    dTag: 'thread-confirmed',
  );

  final requestMessage = buildReservationRequestMessage(
    request: reservationRequest,
    sender: MockKeys.guest,
    recipientPubkey: MockKeys.hoster.publicKey,
  );

  final reservation = buildReservation(
    listing: listing,
    request: reservationRequest,
    signer: MockKeys.hoster,
    dTag: 'reservation-confirmed',
  );

  return ThreadScenario(
    id: 'thread-confirmed',
    description: 'Host confirmed reservation for guest',
    listing: listing,
    reservationRequest: reservationRequest,
    requestMessage: requestMessage,
    reservations: [reservation],
    paid: true,
    refunded: false,
    cancelled: false,
  );
}

ThreadScenario buildCancelledGuestToHostScenario() {
  final listing = MOCK_LISTINGS.first;
  final reservationRequest = buildReservationRequest(
    listing: listing,
    sender: MockKeys.guest,
    dTag: 'thread-cancelled',
  );

  final requestMessage = buildReservationRequestMessage(
    request: reservationRequest,
    sender: MockKeys.guest,
    recipientPubkey: MockKeys.hoster.publicKey,
  );

  final reservation = buildReservation(
    listing: listing,
    request: reservationRequest,
    signer: MockKeys.hoster,
    dTag: 'reservation-cancelled',
    status: 'cancelled',
  );

  return ThreadScenario(
    id: 'thread-cancelled',
    description: 'Cancelled reservation by host',
    listing: listing,
    reservationRequest: reservationRequest,
    requestMessage: requestMessage,
    reservations: [reservation],
    paid: true,
    refunded: false,
    cancelled: true,
  );
}
