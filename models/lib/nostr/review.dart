import 'dart:convert';
import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

class Review extends JsonContentNostrEvent<ReviewContent>
    with ReferencesListing<Review>, ReferencesReservation<Review> {
  static const List<int> kinds = [kNostrKindReview];
  static const requiredTags = [
    [kReservationRefTag],
    [kListingRefTag]
  ];

  Review(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(kind: kNostrKindReview);

  Review.fromNostrEvent(Nip01Event e)
      : assert(hasRequiredTags(e.tags, Review.requiredTags)),
        super.fromNostrEvent(e) {
    parsedContent = ReviewContent.fromJson(json.decode(content));
  }

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
    ParticipationProof proof,
  ) {
    return proof.verify(
        reviewerPubKey, reservation.parsedContent.guestCommitmentHash);
  }
}

/// Content of a review event, which includes proof of reservation participation
class ReviewContent extends EventContent {
  /// Rating from 1-5
  final int rating;

  /// Review text
  final String content;

  /// Proof that the reviewer (guest) was a participant in the reservation
  /// When revealed here, only this specific reservation can be linked to the reviewer
  /// since the salt is unique per reservation
  final ParticipationProof proof;

  ReviewContent({
    required this.rating,
    required this.content,
    required this.proof,
  }) : assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5');

  Map<String, dynamic> toJson() {
    return {
      "rating": rating,
      "content": content,
      "proof": proof.toJson(),
    };
  }

  static ReviewContent fromJson(Map<String, dynamic> json) {
    return ReviewContent(
      rating: json["rating"],
      content: json["content"],
      proof: ParticipationProof.fromJson(json["proof"]),
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
