import 'dart:convert';
import 'dart:core';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../nostr_kinds.dart';
import 'event.dart';
import 'guest_participation_proof.dart';
import 'reservation.dart';

class Review extends Event {
  static const List<int> kinds = [NOSTR_KIND_REVIEW];

  Review.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e);

  /// Validate that a review's proof matches the reservation's guest commitment
  ///
  /// Parameters:
  /// - reservation: The reservation being reviewed
  /// - reviewerPubKey: The public key of the person posting the review (should be the guest)
  /// - proof: The proof of participation being revealed
  ///
  /// Returns true if proof.verify(reviewerPubKey, reservation.guestCommitmentHash) is valid
  static bool validateProof(
    Reservation reservation,
    String reviewerPubKey,
    GuestParticipationProof proof,
  ) {
    return proof.verify(
        reviewerPubKey, reservation.parsedContent.guestCommitmentHash);
  }
}

/// Content of a review event, which includes proof of reservation participation
class ReviewContent {
  /// Rating from 1-5
  final int rating;

  /// Review text
  final String content;

  /// Proof that the reviewer (guest) was a participant in the reservation
  /// When revealed here, only this specific reservation can be linked to the reviewer
  /// since the salt is unique per reservation
  final GuestParticipationProof proof;

  /// The ID (e-tag) of the reservation being reviewed
  final String reservationId;

  ReviewContent({
    required this.rating,
    required this.content,
    required this.proof,
    required this.reservationId,
  }) : assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5');

  Map<String, dynamic> toJson() {
    return {
      "rating": rating,
      "content": content,
      "proof": proof.toJson(),
      "reservationId": reservationId,
    };
  }

  static ReviewContent fromJson(Map<String, dynamic> json) {
    return ReviewContent(
      rating: json["rating"],
      content: json["content"],
      proof: GuestParticipationProof.fromJson(json["proof"]),
      reservationId: json["reservationId"],
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
