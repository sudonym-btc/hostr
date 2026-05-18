import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../can_verify.dart';
import '../crud.usecase.dart';
import '../escrow/escrow_verification.dart';
import '../listings/listings.dart';
import '../reservation_groups/reservation_groups.dart';
import '../reservations/reservation_participant_tags.dart';
import '../reservations/reservations.dart';

/// Dependencies resolved for a single review verification.
class ReviewDeps {
  final List<Reservation> reservations;
  final List<Reservation> proofMatchedReservations;
  final Listing? listing;
  final Validation<ReservationGroup>? validatedGroup;

  const ReviewDeps({
    required this.reservations,
    required this.proofMatchedReservations,
    this.listing,
    this.validatedGroup,
  });
}

@Singleton()
class Reviews extends CrudUseCase<Review> with CanVerify<Review, ReviewDeps> {
  final Reservations _reservations;
  final Listings _listings;
  final EscrowVerification _escrowVerification;

  Reviews({
    required super.requests,
    required super.logger,
    required Reservations reservations,
    required Listings listings,
    required EscrowVerification escrowVerification,
  }) : _reservations = reservations,
       _listings = listings,
       _escrowVerification = escrowVerification,
       super(kind: Review.kinds[0]);

  bool _proofMatchesReservation({
    required Review review,
    required Reservation reservation,
  }) {
    final tradeId = reservation.getDtag();
    if (tradeId == null || tradeId.isEmpty) return false;

    final reviewProof = review.proof;
    final authorization = reviewProof.authorization;
    if (authorization == null) return false;
    if (authorization.pubkey != review.pubKey) return false;

    final rawParticipantMatches =
        reviewProof.participantPubkey == review.pubKey &&
        reservation.parsedTags.getTagValueByMarker('p', reviewProof.role) ==
            reviewProof.participantPubkey;
    final matchingHashExists = reservationParticipantProofsByPubkey(reservation)
        .values
        .expand((proofs) => proofs)
        .any(
          (proof) =>
              proof.role == reviewProof.role &&
              proof.participantPubkey == reviewProof.participantPubkey &&
              proof.payloadHash == reviewProof.authorizationPayloadHash,
        );
    if (!matchingHashExists && !rawParticipantMatches) return false;

    return authorization.verifiesForReservation(
      tradeId: tradeId,
      listingAnchor: reservation.parsedTags.listingAnchor,
      participantPubkey: reviewProof.participantPubkey,
      role: reviewProof.role,
    );
  }

  @override
  Future<ReviewDeps> resolve(Review review) => logger.span('resolve', () async {
    // Both calls drop into their respective batch queues. When multiple
    // reviews resolve concurrently, these merge into 1 findByTag query +
    // 1 getOne batch query.
    final results = await Future.wait([
      _reservations.getListingReservations(
        listingAnchor: review.parsedTags.listingAnchor,
      ),
      _listings.getOneByAnchor(review.parsedTags.listingAnchor),
    ]);

    var candidateReservations = results[0] as List<Reservation>;
    final reservationAnchor = review.getFirstTag(kReservationRefTag);
    if (reservationAnchor != null && reservationAnchor.isNotEmpty) {
      final anchorMatched = candidateReservations
          .where((reservation) => reservation.anchor == reservationAnchor)
          .toList();
      if (anchorMatched.isNotEmpty) {
        final tradeIds = anchorMatched
            .map((r) => r.getDtag())
            .whereType<String>();
        candidateReservations = candidateReservations
            .where((reservation) => tradeIds.contains(reservation.getDtag()))
            .toList();
      } else {
        candidateReservations = const [];
      }
    }

    final proofMatches = await Future.wait(
      candidateReservations.map((reservation) async {
        return _proofMatchesReservation(
              review: review,
              reservation: reservation,
            )
            ? reservation
            : null;
      }),
    );
    final proofMatchedReservations = proofMatches
        .whereType<Reservation>()
        .toList();
    final proofMatchedTradeIds = proofMatchedReservations
        .map((reservation) => reservation.getDtag())
        .whereType<String>()
        .toSet();
    final groupReservations = proofMatchedTradeIds.isEmpty
        ? const <Reservation>[]
        : candidateReservations
              .where(
                (reservation) =>
                    proofMatchedTradeIds.contains(reservation.getDtag()),
              )
              .toList();

    final validatedGroup = groupReservations.isEmpty
        ? null
        : await ReservationGroups.verifyGroupOnChain(
            ReservationGroup(reservations: groupReservations),
            escrowVerification: _escrowVerification,
          );

    return ReviewDeps(
      reservations: candidateReservations,
      proofMatchedReservations: proofMatchedReservations,
      listing: results[1] as Listing?,
      validatedGroup: validatedGroup,
    );
  });

  @override
  Validation<Review> verify(Review review, ReviewDeps deps) =>
      logger.spanSync('verify', () {
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

        final proofMatchedReservations = deps.proofMatchedReservations;
        if (proofMatchedReservations.isEmpty) {
          return Invalid(review, 'Participation proof does not match');
        }

        // @todo: potentially include block time to prove that a comment was
        // written after the trade was completed?
        final validatedGroup = deps.validatedGroup;
        if (validatedGroup is Valid<ReservationGroup> &&
            validatedGroup.event.confirmedCommitted) {
          return Valid(review);
        }
        if (validatedGroup is Invalid<ReservationGroup>) {
          return Invalid(review, validatedGroup.reason);
        }
        if (validatedGroup is Valid<ReservationGroup>) {
          return Invalid(review, 'Reservation was never confirmed committed');
        }
        return Invalid(review, 'No valid reservation in group');
      });
}
