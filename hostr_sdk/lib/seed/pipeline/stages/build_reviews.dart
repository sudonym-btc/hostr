import 'dart:math';

import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../entity_factory.dart';
import '../seed_context.dart';
import '../seed_pipeline_models.dart';

/// Returns a deterministic, per-review [Random] seeded exclusively from
/// [seed] and [threadIndex].
///
/// Using a large offset (200 000) keeps this namespace well clear of the
/// `_listingRng` namespace (`seed * 10 000 + listingIndex`) for any
/// realistic listing count.  The result is that every review's content,
/// rating, and even whether it is emitted at all are stable across re-runs
/// regardless of changes to `userCount` or other pipeline parameters.
Random _reviewRng(int seed, int threadIndex) =>
    Random(seed * 10000 + 200000 + threadIndex);

/// Stage 7: Build review events for completed threads.
///
/// Respects per-thread [ThreadStageSpec.reviewRatio].
///
/// All randomness is drawn from an isolated [_reviewRng] seeded by
/// `(ctx.seed, threadIndex)`, so reviews are stable across re-runs even
/// when [SeedPipelineConfig.userCount] changes.
List<Review> buildReviews({
  required SeedContext ctx,
  required List<SeedThread> threads,
  EntityFactory? factory,
}) {
  final f = factory ?? EntityFactory(ctx: ctx);
  final reviews = <Review>[];

  for (var i = 0; i < threads.length; i++) {
    final thread = threads[i];
    if (thread.reservation == null) continue;

    // Isolated per-review RNG — all draws below come from here.
    final rr = _reviewRng(ctx.seed, i);

    if (rr.nextDouble() >= thread.stageSpec.reviewRatio) continue;

    final review = f.review(
      signer: thread.guest.keyPair,
      reservationAnchor: thread.reservation!.anchor!,
      listingAnchor: thread.listing.anchor!,
      reservation: thread.reservation!,
      reservationAuthorKeyPair: _reservationAuthorKeyPair(thread),
      dTag: 'seed-review-${i + 1}',
      paidViaEscrow: thread.paidViaEscrow,
      createdAt: ctx.timestampDaysAfter(90 + i),
      rng: rr,
    );

    reviews.add(review);
  }

  return reviews;
}

KeyPair _reservationAuthorKeyPair(SeedThread thread) {
  final reservation = thread.reservation;
  if (reservation == null) {
    throw StateError('Cannot resolve review proof key without a reservation');
  }

  if (reservation.pubKey == thread.host.keyPair.publicKey) {
    return thread.host.keyPair;
  }

  if (reservation.pubKey == thread.guest.keyPair.publicKey) {
    return thread.guest.keyPair;
  }

  if (reservation.pubKey == thread.requestAuthorKeyPair.publicKey) {
    return thread.requestAuthorKeyPair;
  }

  throw StateError(
    'Unable to resolve reservation author key for seeded review: '
    'reservation pubkey ${reservation.pubKey}',
  );
}
