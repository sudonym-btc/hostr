import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';

import '../can_verify.dart';
import '../crud.usecase.dart';
import '../escrow/escrow_verification.dart';
import '../listings/listings.dart';
import '../order_groups/order_groups.dart';
import '../orders/order_participant_tags.dart';
import '../orders/orders.dart';

/// Dependencies resolved for a single review verification.
class ReviewDeps {
  final List<Order> orders;
  final List<Order> proofMatchedOrders;
  final Listing? listing;
  final Validation<OrderGroup>? validatedGroup;

  const ReviewDeps({
    required this.orders,
    required this.proofMatchedOrders,
    this.listing,
    this.validatedGroup,
  });
}

@Singleton()
class Reviews extends CrudUseCase<Review> with CanVerify<Review, ReviewDeps> {
  final Orders _orders;
  final Listings _listings;
  final EscrowVerification _escrowVerification;

  Reviews({
    required super.requests,
    required super.logger,
    required Orders orders,
    required Listings listings,
    required EscrowVerification escrowVerification,
  }) : _orders = orders,
       _listings = listings,
       _escrowVerification = escrowVerification,
       super(kind: Review.kinds[0]);

  bool _proofMatchesOrder({required Review review, required Order order}) {
    final tradeId = order.getDtag();
    if (tradeId == null || tradeId.isEmpty) return false;

    final reviewProof = review.proof;
    final authorization = reviewProof.authorization;
    if (authorization == null) return false;
    if (authorization.pubkey != review.pubKey) return false;

    final rawParticipantMatches =
        reviewProof.participantPubkey == review.pubKey &&
        order.parsedTags.getTagValueByMarker('p', reviewProof.role) ==
            reviewProof.participantPubkey;
    final matchingHashExists = orderParticipantProofsByPubkey(order).values
        .expand((proofs) => proofs)
        .any(
          (proof) =>
              proof.role == reviewProof.role &&
              proof.participantPubkey == reviewProof.participantPubkey &&
              proof.payloadHash == reviewProof.authorizationPayloadHash,
        );
    if (!matchingHashExists && !rawParticipantMatches) return false;

    return authorization.verifiesForOrder(
      tradeId: tradeId,
      listingAnchor: order.parsedTags.listingAnchor,
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
      _orders.getListingOrders(listingAnchor: review.parsedTags.listingAnchor),
      _listings.getOneByAnchor(review.parsedTags.listingAnchor),
    ]);

    var candidateOrders = results[0] as List<Order>;
    final orderAnchor = review.getFirstTag(kOrderRefTag);
    if (orderAnchor != null && orderAnchor.isNotEmpty) {
      final anchorMatched = candidateOrders
          .where((order) => order.anchor == orderAnchor)
          .toList();
      if (anchorMatched.isNotEmpty) {
        final tradeIds = anchorMatched
            .map((r) => r.getDtag())
            .whereType<String>();
        candidateOrders = candidateOrders
            .where((order) => tradeIds.contains(order.getDtag()))
            .toList();
      } else {
        candidateOrders = const [];
      }
    }

    final proofMatches = await Future.wait(
      candidateOrders.map((order) async {
        return _proofMatchesOrder(review: review, order: order) ? order : null;
      }),
    );
    final proofMatchedOrders = proofMatches.whereType<Order>().toList();
    final proofMatchedTradeIds = proofMatchedOrders
        .map((order) => order.getDtag())
        .whereType<String>()
        .toSet();
    final groupOrders = proofMatchedTradeIds.isEmpty
        ? const <Order>[]
        : candidateOrders
              .where((order) => proofMatchedTradeIds.contains(order.getDtag()))
              .toList();

    final validatedGroup = groupOrders.isEmpty
        ? null
        : await OrderGroups.verifyGroupOnChain(
            OrderGroup(orders: groupOrders),
            escrowVerification: _escrowVerification,
          );

    return ReviewDeps(
      orders: candidateOrders,
      proofMatchedOrders: proofMatchedOrders,
      listing: results[1] as Listing?,
      validatedGroup: validatedGroup,
    );
  });

  @override
  Validation<Review> verify(Review review, ReviewDeps deps) =>
      logger.spanSync('verify', () {
        logger.d(
          "Verifying review ${review.id} with ${deps.orders.length} "
          "matching orders and listing ${deps.listing?.id}",
        );
        if (deps.orders.isEmpty) {
          return Invalid(review, 'No matching order found');
        }

        final listing = deps.listing;
        if (listing == null) {
          return Invalid(review, 'Listing not found');
        }

        final proofMatchedOrders = deps.proofMatchedOrders;
        if (proofMatchedOrders.isEmpty) {
          return Invalid(review, 'Participation proof does not match');
        }

        // @todo: potentially include block time to prove that a comment was
        // written after the trade was completed?
        final validatedGroup = deps.validatedGroup;
        if (validatedGroup is Valid<OrderGroup> &&
            validatedGroup.event.confirmedCommitted) {
          return Valid(review);
        }
        if (validatedGroup is Invalid<OrderGroup>) {
          return Invalid(review, validatedGroup.reason);
        }
        if (validatedGroup is Valid<OrderGroup>) {
          return Invalid(review, 'Order was never confirmed committed');
        }
        return Invalid(review, 'No valid order in group');
      });
}
