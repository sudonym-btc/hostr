import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../util/main.dart';
import '../can_verify.dart';
import '../crud.usecase.dart';
import '../listings/listings.dart';
import '../reservations/reservations.dart';

/// Dependencies resolved for a single review verification.
class ReviewDeps {
  final List<Reservation> reservations;
  final Listing? listing;

  const ReviewDeps({required this.reservations, this.listing});
}

@Singleton()
class Reviews extends CrudUseCase<Review> with CanVerify<Review, ReviewDeps> {
  final Reservations reservations;
  final Listings listings;

  Reviews({
    required super.requests,
    required super.logger,
    required this.reservations,
    required this.listings,
  }) : super(kind: Review.kinds[0]);

  @override
  Future<ReviewDeps> resolve(Review review) async {
    final hash = ParticipationProof.computeCommitmentHash(
      review.pubKey,
      review.parsedContent.proof.salt,
    );

    // Both calls drop into their respective batch queues. When multiple
    // reviews resolve concurrently, these merge into 1 findByTag query +
    // 1 getOne batch query.
    final results = await Future.wait([
      reservations.findByTag(kCommitmentHashTag, hash),
      listings.getOneByAnchor(review.parsedTags.listingAnchor),
    ]);

    return ReviewDeps(
      reservations: results[0] as List<Reservation>,
      listing: results[1] as Listing?,
    );
  }

  @override
  Validation<Review> verify(Review review, ReviewDeps deps) {
    logger.d(
      "Verifying review ${review.id} with ${deps.reservations.length} "
      "matching reservations and listing ${deps.listing?.id}",
    );
    if (deps.reservations.isEmpty) {
      return Invalid(review, 'No matching reservation found');
    }

    final listing = deps.listing;
    if (listing == null) {
      return Invalid(review, 'Listing not found');
    }

    // Verify the participation proof itself.
    final proofValid = Review.validateProof(
      deps.reservations.first,
      review.pubKey,
      review.parsedContent.proof,
    );
    if (!proofValid) {
      return Invalid(review, 'Participation proof does not match');
    }

    // Host-confirmed reservation: no payment proof needed.
    final hostConfirmed = deps.reservations.any(
      (r) => r.pubKey == listing.pubKey && !r.parsedContent.cancelled,
    );
    if (hostConfirmed) {
      return Valid(review);
    }

    // Self-signed: validate payment proof on the senior reservation.
    final senior = Reservation.getSeniorReservation(
      reservations: deps.reservations,
      listing: listing,
    );
    if (senior == null) {
      return Invalid(review, 'No valid reservation in group');
    }

    final validation = Reservation.validate(senior, listing);
    if (!validation.isValid) {
      final reason = validation.fields.values
          .where((f) => !f.ok)
          .map((f) => f.message)
          .join('; ');
      return Invalid(
        review,
        reason.isNotEmpty ? reason : 'Invalid payment proof',
      );
    }

    return Valid(review);
  }
}
