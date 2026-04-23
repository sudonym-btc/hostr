import 'dart:convert';
import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

class ReviewTags extends EventTags
    with ReferencesListing<ReviewTags>, ReferencesReservation<ReviewTags> {
  ReviewTags(super.tags);
}

class Review extends JsonContentNostrEvent<ReviewContent, ReviewTags> {
  static const List<int> kinds = [kNostrKindReview];
  static final EventTagsParser<ReviewTags> _tagParser = ReviewTags.new;
  static final EventContentParser<ReviewContent> _contentParser =
      ReviewContent.fromJson;

  // ── Convenience getters ─────────────────────────────────────────────
  int get rating => parsedContent.rating;
  String get reviewText => parsedContent.content;
  ParticipationProof get proof => parsedContent.proof;

  Review(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
            kind: kNostrKindReview,
            tagParser: _tagParser,
            contentParser: _contentParser);

  Review.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );
}

/// Content of a review event, which includes proof of reservation participation.
class ReviewContent extends EventContent {
  /// Rating from 1-5
  final int rating;

  /// Review text
  final String content;

  /// Proof that reveals the private key needed to decrypt the reservation's
  /// identity authorization capsule for this review.
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
