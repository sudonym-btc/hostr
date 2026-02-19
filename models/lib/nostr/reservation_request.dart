import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class ReservationRequestTags extends EventTags
    with ReferencesListing<ReservationRequestTags> {
  ReservationRequestTags(super.tags);
}

class ReservationRequest extends JsonContentNostrEvent<
    ReservationRequestContent, ReservationRequestTags> {
  static const List<int> kinds = [kNostrKindReservationRequest];
  static final EventTagsParser<ReservationRequestTags> _tagParser =
      ReservationRequestTags.new;
  static final EventContentParser<ReservationRequestContent> _contentParser =
      ReservationRequestContent.fromJson;

  ReservationRequest(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
            kind: kNostrKindReservationRequest,
            tagParser: _tagParser,
            contentParser: _contentParser);

  ReservationRequest.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  static bool canAttemptPay(
      {required ReservationRequest request,
      required Listing listing,
      required KeyPair ourKey}) {
    return listing.pubKey != ourKey.publicKey;
  }

  static bool wasSentByHost(
      {required ReservationRequest request, required Listing listing}) {
    return request.pubKey == listing.pubKey;
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

  static bool hasHostReservationForCommitment({
    required List<Reservation> reservations,
    required Listing listing,
    required String commitmentHash,
  }) {
    return reservations.any(
      (reservation) =>
          reservation.pubKey == listing.pubKey &&
          reservation.parsedTags.commitmentHash == commitmentHash &&
          Reservation.validate(reservation, listing).isValid,
    );
  }

  static bool hasAnyReservationForCommitment({
    required List<Reservation> reservations,
    required Listing listing,
    required String commitmentHash,
  }) {
    return reservations.any(
      (reservation) =>
          reservation.parsedTags.commitmentHash == commitmentHash &&
          Reservation.validate(reservation, listing).isValid,
    );
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
