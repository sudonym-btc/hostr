import 'dart:convert';
import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class ReservationRequest
    extends JsonContentNostrEvent<ReservationRequestContent> {
  static const List<int> kinds = [NOSTR_KIND_RESERVATION_REQUEST];

  ReservationRequest.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e) {
    parsedContent = ReservationRequestContent.fromJson(json.decode(content));
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

  static bool canAccept(
      {required ReservationRequest request,
      required Listing listing,
      required KeyPair ourKey}) {
    return request.pubKey != ourKey.publicKey &&
        listing.pubKey == ourKey.publicKey;
  }

  static ReservationStatus getStatus({
    required String anchor,
    required Listing listing,
    // List of reservations associated with this request (salt must be validated before to check it's definitely assigned to our user)
    required List<Reservation> reservations,
    required KeyPair ourKey,
  }) {
    final reservationByHost = reservations.where(
      (reservation) => reservation.pubKey == listing.pubKey,
    );
    if (reservationByHost.any((r) => Reservation.validate(r, listing))) {
      return ReservationStatus.accepted;
    } else if (reservations.any((r) => Reservation.validate(r, listing))) {
      return ReservationStatus.paid;
    } else if (reservations.any((r) => r.anchor == anchor)) {
      return ReservationStatus.pending;
    }
    return ReservationStatus.pending;
  }
}

enum ReservationStatus { pending, accepted, cancelled, completed, paid }
