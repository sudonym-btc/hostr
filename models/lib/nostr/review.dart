import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

const kReviewRatingTag = 'rating';
const kReviewPrimaryRatingLabel = 'thumb';
const kReviewProofTag = 'review_proof';

class ReviewTags extends EventTags
    with ReferencesListing<ReviewTags>, ReferencesOrder<ReviewTags> {
  ReviewTags(super.tags);

  double get normalizedRating {
    final primary = tags.where(
      (tag) =>
          tag.length >= 3 &&
          tag[0] == kReviewRatingTag &&
          tag[2] == kReviewPrimaryRatingLabel,
    );
    final value =
        primary.isNotEmpty ? primary.first[1] : getTagValue(kReviewRatingTag);
    return _parseNormalizedRating(value);
  }

  ParticipationProof? get participationProof {
    for (final tag in tags) {
      if (tag.length >= 4 && tag[0] == kReviewProofTag) {
        return ParticipationProof(
          role: tag[1],
          participantPubkey: tag[2],
          authorizationPayload: tag[3],
        );
      }
    }
    return null;
  }

  static List<String> primaryRatingTag(num normalizedRating) => [
        kReviewRatingTag,
        normalizedRatingTagValue(normalizedRating),
        kReviewPrimaryRatingLabel,
      ];

  static List<String> primaryRatingTagFromStars(int rating) =>
      primaryRatingTag(rating.clamp(0, 5) / 5);

  static List<String> proofTag(ParticipationProof proof) => [
        kReviewProofTag,
        proof.role,
        proof.participantPubkey,
        proof.authorizationPayload,
      ];

  static String normalizedRatingTagValue(num rating) {
    final clamped = rating.clamp(0, 1).toDouble();
    final fixed = clamped.toStringAsFixed(3);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static double _parseNormalizedRating(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return 0;
    return parsed.clamp(0, 1).toDouble();
  }
}

class Review extends Event<ReviewTags> {
  static const List<int> kinds = [kNostrKindReview];
  static final EventTagsParser<ReviewTags> _tagParser = ReviewTags.new;
  static const requiredTags = [
    ['d'],
    [kListingRefTag],
    [kReviewRatingTag, '', kReviewPrimaryRatingLabel],
  ];

  double get normalizedRating => parsedTags.normalizedRating;

  /// UI-friendly 0..5 star rating derived from the NIP-85/Gamma 0..1 score.
  int get rating => (normalizedRating * 5).round().clamp(0, 5).toInt();

  String get reviewText => content;

  ParticipationProof? get proof => parsedTags.participationProof;

  Review({
    required super.pubKey,
    required super.tags,
    required super.content,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(kind: kNostrKindReview, tagParser: _tagParser);

  Review.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          requiredTags: requiredTags,
        );
}
