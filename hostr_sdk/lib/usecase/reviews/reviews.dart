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
    // Both calls drop into their respective batch queues. When multiple
    // reviews resolve concurrently, these merge into 1 findByTag query +
    // 1 getOne batch query.
    final results = await Future.wait([
      reservations.getListingReservations(
        listingAnchor: review.parsedTags.listingAnchor,
      ),
      listings.getOneByAnchor(review.parsedTags.listingAnchor),
    ]);

    var candidateReservations = results[0] as List<Reservation>;
    final reservationAnchor = review.getFirstTag(kReservationRefTag);
    if (reservationAnchor != null && reservationAnchor.isNotEmpty) {
      candidateReservations = candidateReservations
          .where((reservation) => reservation.anchor == reservationAnchor)
          .toList();
    }

    return ReviewDeps(
      reservations: candidateReservations,
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

    // Verify participation proof against candidate reservations.
    final proofMatchedReservations = deps.reservations
        .where(
          (reservation) => Review.validateProof(
            reservation,
            review.pubKey,
            review.parsedContent.proof,
          ),
        )
        .toList();
    if (proofMatchedReservations.isEmpty) {
      return Invalid(review, 'Participation proof does not match');
    }

    // Host-confirmed reservation: no payment proof needed.
    final hostConfirmed = proofMatchedReservations.any(
      (r) => r.pubKey == listing.pubKey && !r.parsedContent.cancelled,
    );
    if (hostConfirmed) {
      return Valid(review);
    }

    // Self-signed: validate payment proof on the senior reservation.
    final senior = Reservation.getSeniorReservation(
      reservations: proofMatchedReservations,
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
