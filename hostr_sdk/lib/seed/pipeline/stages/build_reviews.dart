import 'package:models/main.dart';

import '../seed_context.dart';
import '../seed_pipeline_models.dart';

/// Stage 7: Build review events for completed threads.
///
/// Respects per-thread [ThreadStageSpec.reviewRatio].
List<Review> buildReviews({
  required SeedContext ctx,
  required List<SeedThread> threads,
}) {
  final reviews = <Review>[];

  for (var i = 0; i < threads.length; i++) {
    final thread = threads[i];
    if (thread.reservation == null) continue;
    if (!ctx.pickByRatio(thread.stageSpec.reviewRatio)) continue;

    final rating = _pickReviewRating(ctx);

    final review = Review(
      pubKey: thread.guest.keyPair.publicKey,
      tags: ReviewTags([
        [kReservationRefTag, thread.reservation!.anchor!],
        [kListingRefTag, thread.listing.anchor!],
        ['d', 'seed-review-${i + 1}'],
      ]),
      createdAt: ctx.timestampDaysAfter(90 + i),
      content: ReviewContent(
        rating: rating,
        content: _buildReviewContentForRating(
          ctx: ctx,
          rating: rating,
          paidViaEscrow: thread.paidViaEscrow,
        ),
        proof: ParticipationProof(salt: thread.id),
      ),
    ).signAs(thread.guest.keyPair, Review.fromNostrEvent);

    reviews.add(review);
  }

  return reviews;
}

// ─── Review templates ───────────────────────────────────────────────────────

const Map<int, List<String>> _reviewTemplatesByRating = {
  1: [
    'Unfortunately the stay did not match the listing photos and we had several issues during check-in.',
    'Communication was difficult and the space was not as clean as expected.',
    'This booking did not work out for us due to maintenance issues and poor responsiveness.',
    'The location was fine, but overall comfort and cleanliness were below expectations.',
  ],
  2: [
    'The place was acceptable for one night, but we ran into a few avoidable issues.',
    'Some parts of the stay were okay, but check-in and communication could be much better.',
    'Decent location, though the apartment needed better upkeep and clearer instructions.',
    'Not terrible, but the stay felt overpriced for the quality we received.',
  ],
  3: [
    'Solid stay overall with a convenient location, though there is room for improvement.',
    'The listing mostly matched expectations and we had a comfortable visit.',
    'Good value for a short trip, with a few minor issues that were manageable.',
    'A generally pleasant experience with straightforward check-in and decent amenities.',
  ],
  4: [
    'Very good stay with a clean space, easy check-in, and quick host communication.',
    'Great location and comfortable setup; we would happily book again.',
    'Everything went smoothly and the home felt welcoming throughout our trip.',
    'A really enjoyable stay with thoughtful touches and clear instructions.',
  ],
  5: [
    'Excellent stay from start to finish, exactly as described and beautifully prepared.',
    'Fantastic host and a wonderful space. One of our best booking experiences.',
    'Perfect for our trip: spotless, comfortable, and in an ideal location.',
    'Absolutely loved this place. Check-in was seamless and the stay exceeded expectations.',
  ],
};

const Map<int, List<String>> _reviewPaymentNotesByRating = {
  1: [
    'Payment worked, but it did not make up for the problems during the stay.',
    'Transaction was completed, but our hosting experience was disappointing.',
  ],
  2: [
    'Payment was straightforward, though the stay itself needed improvement.',
    'No payment issues, but the hosting experience felt inconsistent.',
  ],
  3: [
    'Payment and booking flow were smooth and uncomplicated.',
    'The payment process was easy and matched what we expected.',
  ],
  4: [
    'Payment was smooth and the overall booking experience felt reliable.',
    'Everything from payment to check-out was clear and easy.',
  ],
  5: [
    'Flawless booking and payment experience from start to finish.',
    'Payment was instant and the whole process felt premium and stress-free.',
  ],
};

int _pickReviewRating(SeedContext ctx) {
  final roll = ctx.random.nextDouble();
  if (roll < 0.06) return 1;
  if (roll < 0.15) return 2;
  if (roll < 0.35) return 3;
  if (roll < 0.70) return 4;
  return 5;
}

String _buildReviewContentForRating({
  required SeedContext ctx,
  required int rating,
  required bool paidViaEscrow,
}) {
  final clampedRating = rating.clamp(1, 5);
  final base = ctx.pickFrom(_reviewTemplatesByRating[clampedRating]!);
  final paymentNote = ctx.pickFrom(_reviewPaymentNotesByRating[clampedRating]!);
  final paymentKind = paidViaEscrow ? 'Escrow' : 'Zap';
  return '$base $paymentKind payment: $paymentNote';
}
