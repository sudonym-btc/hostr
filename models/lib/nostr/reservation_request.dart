import 'dart:convert';
import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class ReservationRequest
    extends JsonContentNostrEvent<ReservationRequestContent>
    with
        ReferencesListing<ReservationRequest>,
        ReferencesThread<ReservationRequest> {
  static const List<int> kinds = [NOSTR_KIND_RESERVATION_REQUEST];
  static const requiredTags = [
    [THREAD_REFERENCE_TAG],
    [LISTING_REFERENCE_TAG]
  ];
  ReservationRequest(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(kind: NOSTR_KIND_RESERVATION_REQUEST);

  ReservationRequest.fromNostrEvent(Nip01Event e)
      : assert(hasRequiredTags(e.tags, ReservationRequest.requiredTags)),
        super.fromNostrEvent(e) {
    parsedContent = ReservationRequestContent.fromJson(json.decode(content));
  }

  static bool canAttemptPay(
      {required ReservationRequest request,
      required Listing listing,
      required KeyPair ourKey}) {
    return listing.pubKey != ourKey.publicKey;
  }

  static bool canPayWithZapReceipt(
      LnurlResponse hostLnurlResponse, Listing listing) {
    return hostLnurlResponse.doesAllowsNostr &&
        hostLnurlResponse.nostrPubkey == listing.pubKey;
  }

  static bool canPayDirectly(ProfileMetadata hostProfile, Listing listing) {
    return hostProfile.metadata.lud16 != null;
  }

  static bool canUseEscrow(ProfileMetadata hostProfile,
      ProfileMetadata guestProfile, Nip51List hostEscrowList) {
    return hostProfile.evmAddress != null &&
        guestProfile.evmAddress != null &&
        hostEscrowList.elements.length > 0;
  }

  static bool isAvailableForReservation(
      {required ReservationRequest reservationRequest,
      required List<Reservation> reservations}) {
    return Listing.isAvailable(reservationRequest.parsedContent.start,
        reservationRequest.parsedContent.end, reservations);
  }

  static bool canAccept(
      {required ReservationRequest request,
      required Listing listing,
      required KeyPair ourKey}) {
    return request.pubKey != ourKey.publicKey &&
        listing.pubKey == ourKey.publicKey;
  }

  static bool isReservationValid(Reservation reservation, Listing listing) {
    final result = Reservation.validate(reservation, listing);
    return result == true;
  }

  static bool hasHostReservationForThread({
    required List<Reservation> reservations,
    required Listing listing,
    required String threadAnchor,
  }) {
    return reservations.any(
      (reservation) =>
          reservation.pubKey == listing.pubKey &&
          reservation.threadAnchor == threadAnchor &&
          isReservationValid(reservation, listing),
    );
  }

  static bool hasAnyReservationForThread({
    required List<Reservation> reservations,
    required Listing listing,
    required String threadAnchor,
  }) {
    return reservations.any(
      (reservation) =>
          reservation.threadAnchor == threadAnchor &&
          isReservationValid(reservation, listing),
    );
  }

  static ReservationRequestStatus resolveStatus({
    required ReservationRequest request,
    required Listing listing,
    required List<Reservation> reservations,
    required String threadAnchor,
    required bool paid,
    required bool refunded,
  }) {
    final hostReservationExists = hasHostReservationForThread(
      reservations: reservations,
      listing: listing,
      threadAnchor: threadAnchor,
    );
    final available = isAvailableForReservation(
      reservationRequest: request,
      reservations: reservations,
    );

    if (refunded) {
      return ReservationRequestStatus.refunded;
    }

    if (hostReservationExists) {
      return ReservationRequestStatus.confirmed;
    }

    if (paid && !hostReservationExists) {
      return ReservationRequestStatus.unconfirmed;
    }

    if (!available) {
      return ReservationRequestStatus.unavailable;
    }

    return ReservationRequestStatus.unconfirmed;
  }

  static ReservationRequestHostAction resolveHostAction({
    required ReservationRequestStatus status,
  }) {
    switch (status) {
      case ReservationRequestStatus.unconfirmed:
        return ReservationRequestHostAction.accept;
      case ReservationRequestStatus.pendingPublish:
        return ReservationRequestHostAction.publish;
      case ReservationRequestStatus.confirmed:
        return ReservationRequestHostAction.refund;
      default:
        return ReservationRequestHostAction.none;
    }
  }

  static ReservationRequestGuestAction resolveGuestAction({
    required ReservationRequestStatus status,
  }) {
    switch (status) {
      case ReservationRequestStatus.unconfirmed:
        return ReservationRequestGuestAction.pay;
      case ReservationRequestStatus.pendingPublish:
        return ReservationRequestGuestAction.publish;
      default:
        return ReservationRequestGuestAction.none;
    }
  }
}

class ReservationRequestContent extends EventContent {
  final DateTime start;
  final DateTime end;
  final int quantity;
  final Amount amount;
  final String salt;

  ReservationRequestContent(
      {required this.start,
      required this.end,
      required this.quantity,
      required this.amount,
      required this.salt});

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
      "quantity": quantity,
      "amount": amount.toJson(),
      "salt": salt,
    };
  }

  static ReservationRequestContent fromJson(Map<String, dynamic> json) {
    return ReservationRequestContent(
      start: DateTime.parse(json["start"]),
      end: DateTime.parse(json["end"]),
      quantity: json["quantity"],
      amount: Amount.fromJson(json["amount"]),
      salt: json["salt"],
    );
  }
}

enum ReservationStatus {
  pending,
  accepted,
  cancelled,
  completed,
  paid,
  refunded
}

enum ReservationRequestStatus {
  unconfirmed,
  pendingPublish,
  refunded,
  unavailable,
  confirmed
}

enum ReservationRequestHostAction { accept, publish, refund, none }

enum ReservationRequestGuestAction { pay, publish, none }
