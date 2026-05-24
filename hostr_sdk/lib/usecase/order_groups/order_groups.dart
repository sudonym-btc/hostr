import 'dart:async';
import 'dart:collection';

import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../escrow/escrow_verification.dart';
import '../evm/evm.dart';
import '../orders/order_participant_tags.dart';
import '../orders/orders.dart';

/// Dependencies resolved for a single order-group verification.
class OrderGroupDeps {
  final Listing listing;

  const OrderGroupDeps({required this.listing});
}

/// Use case that groups raw [Order] events into [OrderGroup]s
/// per trade id (d-tag) and runs validation over them.
///
/// Follows the same `subscribeVerified` / `queryVerified` API shape used by
/// [Reviews] via [CanVerify], but operates on [OrderGroup] rather
/// than a single [Nip01Event].
///
/// Validation rules per group:
/// 1. Either party cancelled → [Valid] (cancellation is a legitimate protocol
///    outcome, not a structural error).
/// 2. Seller confirmation exists → [Valid] (host confirmed the trade).
/// 3. Buyer-only (self-signed) → validate payment proof via
///    [Order.validate].
@Singleton()
class OrderGroups {
  final Orders _orders;
  final CustomLogger _logger;
  final Evm _evm;

  /// Lazily constructed on-chain escrow verifier.
  late final EscrowVerification escrowVerification = EscrowVerification(
    evm: _evm,
    logger: _logger,
  );

  OrderGroups({
    required Orders orders,
    required CustomLogger logger,
    required Evm evm,
  }) : _orders = orders,
       _logger = logger.scope('order-groups'),
       _evm = evm;

  // ── Public API ──────────────────────────────────────────────────────

  /// Validates order groups from an **external** [source] stream.
  ///
  /// Unlike [subscribeVerified], the caller owns the [source] lifetime —
  /// passing `closeSourceOnClose: false` (the default) keeps the shared
  /// stream alive when this view is closed.
  StreamWithStatus<Validation<OrderGroup>> verifyFromSource({
    required StreamWithStatus<Order> source,
    Duration debounce = Duration.zero,
    bool closeSourceOnClose = false,
    bool validate = true,
    bool forceValidateSelfSigned = false,
    bool Function(OrderGroup group)? forceValidatePredicate,
  }) => _logger.spanSync('verifyFromSource', () {
    return _buildValidatedStream(
      source: source,
      debounce: debounce,
      closeSourceOnClose: closeSourceOnClose,
      validate: validate,
      forceValidateSelfSigned: forceValidateSelfSigned,
      forceValidatePredicate: forceValidatePredicate,
    );
  });

  /// Live subscription that emits validated order groups for [listing].
  ///
  /// When [forceValidateSelfSigned] is `true`, buyer-published orders
  /// are always checked for a valid payment proof — even when a seller
  /// confirmation already exists. This is the mode escrow arbitration uses.
  StreamWithStatus<Validation<OrderGroup>> subscribeVerified({
    required String listingAnchor,
    Duration debounce = Duration.zero,
    bool forceValidateSelfSigned = false,
    bool Function(OrderGroup group)? forceValidatePredicate,
  }) => _logger.spanSync('subscribeVerified', () {
    final source = _orders.subscribe(
      Filter(
        tags: {
          kListingRefTag: [listingAnchor],
        },
      ),
      name: 'OrderGroups-verified',
    );
    return _buildValidatedStream(
      source: source,
      debounce: debounce,
      closeSourceOnClose: true,
      forceValidateSelfSigned: forceValidateSelfSigned,
      forceValidatePredicate: forceValidatePredicate,
    );
  });

  /// One-shot query that emits validated order groups for [listing].
  ///
  /// When [forceValidateSelfSigned] is `true`, buyer-published orders
  /// are always checked for a valid payment proof — even when a seller
  /// confirmation already exists.
  StreamWithStatus<Validation<OrderGroup>> queryVerified({
    required String listingAnchor,
    Duration debounce = Duration.zero,
    bool forceValidateSelfSigned = false,
    bool Function(OrderGroup group)? forceValidatePredicate,
  }) => _logger.spanSync('queryVerified', () {
    final source = _orders.query(
      Filter(
        tags: {
          kListingRefTag: [listingAnchor],
        },
      ),
      name: 'OrderGroups-query',
    );
    return _buildValidatedStream(
      source: source,
      debounce: debounce,
      closeSourceOnClose: true,
      forceValidateSelfSigned: forceValidateSelfSigned,
      forceValidatePredicate: forceValidatePredicate,
    );
  });

  // ── Verification ────────────────────────────────────────────────────

  /// Pure verification of a single group against its [listing].
  ///
  /// When [forceValidateSelfSigned] is `true` the buyer's payment proof is
  /// validated regardless of whether a seller confirmation exists. This is
  /// the mode used by escrow arbitration to ensure the on-chain amount is
  /// correct before ruling on a dispute.
  ///
  /// This is intentionally static so it can be used in tests or
  /// other contexts without needing the full usecase instance.
  static Validation<OrderGroup> verifyGroup(
    OrderGroup group, {
    Listing? listing,
    bool forceValidateSelfSigned = false,
  }) {
    // 1. Cancelled → Valid (cancellation is a legitimate protocol outcome,
    // not a structural error). Callers that must exclude cancelled groups
    // (availability checks, cancel action) filter on group.cancelled directly.
    if (group.cancelled) {
      return Valid(group);
    }

    // 2. When forcing validation, always check the buyer's proof.
    if (forceValidateSelfSigned) {
      final buyer = group.buyerOrder;
      if (buyer == null) {
        // Seller-only trade with no buyer order to validate.
        if (group.sellerOrder != null) {
          return Valid(group);
        }
        return Invalid(group, 'No order found');
      }

      if (group.sellerOrder == null && listing != null && !listing.autoAccept) {
        return Invalid(group, 'Listing does not allow auto-accepted orders');
      }

      final validation = Order.validate(buyer);
      if (validation.isValid) {
        return Valid(group);
      }

      final reason = validation.fields.values
          .where((f) => !f.ok)
          .map((f) => f.message)
          .join('; ');
      return Invalid(
        group,
        reason.isNotEmpty ? reason : 'Invalid payment proof',
      );
    }

    // 3. Seller-published orders are valid by authority; escrow commit
    // also counts as a valid confirmation in default mode.
    if (group.sellerOrder != null ||
        group.escrowOrder?.stage == OrderStage.commit) {
      return Valid(group);
    }

    // 4. Buyer-only: must have a buyer order to validate.
    final buyer = group.buyerOrder;
    if (buyer == null) {
      return Invalid(group, 'No order found');
    }

    // 5. Buyer-only commits require seller pre-authorization.
    if (listing != null && !listing.autoAccept) {
      return Invalid(group, 'Listing does not allow auto-accepted orders');
    }

    // 6. Validate the buyer's self-signed proof.
    final validation = Order.validate(buyer);
    if (validation.isValid) {
      return Valid(group);
    }

    final reason = validation.fields.values
        .where((f) => !f.ok)
        .map((f) => f.message)
        .join('; ');
    return Invalid(group, reason.isNotEmpty ? reason : 'Invalid payment proof');
  }

  /// Async verification that includes on-chain escrow amount checks.
  ///
  /// First runs [verifyGroup] for Nostr-level validation. If the buyer has
  /// an escrow proof and [escrowVerification] is available, also verifies
  /// the on-chain trade amount covers the listing cost.
  ///
  /// When [forceValidateSelfSigned] is `true` the buyer's escrow proof is
  /// checked regardless of whether a seller confirmation exists.
  static Future<Validation<OrderGroup>> verifyGroupOnChain(
    OrderGroup group, {
    Listing? listing,
    bool forceValidateSelfSigned = false,
    EscrowVerification? escrowVerification,
  }) async {
    // Run Nostr-level check first.
    final nostrResult = verifyGroup(
      group,
      listing: listing,
      forceValidateSelfSigned: forceValidateSelfSigned,
    );

    // If Nostr-level already invalid, no need for on-chain check.
    if (nostrResult is Invalid) return nostrResult;

    final baseGroup = nostrResult.event;

    // Determine which buyer order to verify on-chain.
    final buyer = group.buyerOrder;
    var confirmedCommitted = group.hasCommitConfirmation;
    if (buyer == null) {
      return Valid(baseGroup.copyWith(confirmedCommitted: confirmedCommitted));
    }
    if (confirmedCommitted && !forceValidateSelfSigned) {
      return Valid(baseGroup.copyWith(confirmedCommitted: confirmedCommitted));
    }

    // Only check on-chain when:
    // a) escrowVerification is available, AND
    // b) buyer has an escrow proof.
    final hasEscrowProof = buyer.proof?.hasEscrowPaymentProof == true;
    final needsOnChain = hasEscrowProof && escrowVerification != null;

    if (!needsOnChain) {
      return Valid(baseGroup.copyWith(confirmedCommitted: confirmedCommitted));
    }

    final result = await escrowVerification.verify(order: buyer);

    if (result.isValid) {
      confirmedCommitted = true;
      return Valid(baseGroup.copyWith(confirmedCommitted: confirmedCommitted));
    }

    if (forceValidateSelfSigned || group.sellerOrder == null) {
      return Invalid(
        group,
        result.reason ?? 'On-chain escrow verification failed',
      );
    }

    return Valid(baseGroup.copyWith(confirmedCommitted: confirmedCommitted));
  }

  // ── Stream plumbing ─────────────────────────────────────────────────

  StreamWithStatus<Validation<OrderGroup>> _buildValidatedStream({
    required StreamWithStatus<Order> source,
    required Duration debounce,
    required bool closeSourceOnClose,
    bool validate = true,
    bool forceValidateSelfSigned = false,
    bool Function(OrderGroup group)? forceValidatePredicate,
  }) {
    final groups = <String, OrderGroup>{};
    final listingCache = <String, Listing?>{};
    final pendingItems = <Order>[];
    final validationQueue = Queue<({String groupId, String tradeId})>();
    final queuedGroupIds = <String>{};
    Timer? debounceTimer;
    StreamStatus? deferredStatus;
    var processing = false;
    var closed = false;

    late final StreamSubscription<Order> itemSub;
    late final StreamSubscription<StreamStatus> statusSub;

    late final StreamWithStatus<Validation<OrderGroup>> result;

    Future<Listing?> listingFor(OrderGroup group) async {
      final listingAnchor = group.listingAnchor;
      if (listingCache.containsKey(listingAnchor)) {
        return listingCache[listingAnchor];
      }
      final listing = await _orders.listings.getOneByAnchor(listingAnchor);
      listingCache[listingAnchor] = listing;
      return listing;
    }

    Future<Validation<OrderGroup>> validateGroup({
      required OrderGroup group,
      required String tradeId,
    }) async {
      final Validation<OrderGroup> validated;
      if (validate) {
        final shouldForceValidate =
            forceValidatePredicate?.call(group) ?? forceValidateSelfSigned;
        final listing = await listingFor(group);

        validated = await verifyGroupOnChain(
          group,
          listing: listing,
          forceValidateSelfSigned: shouldForceValidate,
          escrowVerification: escrowVerification,
        );
      } else {
        validated = Valid(group);
      }

      if (validated is Invalid) {
        _logger.w(
          'Group for trade $tradeId is invalid: ${(validated as Invalid).reason}',
        );
        _logger.w('Buyer order: ${group.buyerOrder}');
        _logger.w('Buyer order proof: ${group.buyerOrder?.proof}');
        _logger.w('Seller order: ${group.sellerOrder}');
        _logger.w('Escrow order: ${group.escrowOrder}');
      } else {
        _logger.d(
          validate
              ? 'Group for trade $tradeId is valid'
              : 'Group for trade $tradeId accepted without validation',
        );
      }

      return validated;
    }

    void maybeForwardDeferredStatus() {
      if (!processing &&
          pendingItems.isEmpty &&
          validationQueue.isEmpty &&
          debounceTimer == null &&
          deferredStatus != null) {
        result.addStatus(deferredStatus!);
        deferredStatus = null;
      }
    }

    void enqueueValidation(String groupId, String tradeId) {
      if (!queuedGroupIds.add(groupId)) return;
      validationQueue.add((groupId: groupId, tradeId: tradeId));
    }

    Future<void> processQueue() async {
      if (processing) return;
      processing = true;

      try {
        while (!closed && validationQueue.isNotEmpty) {
          final job = validationQueue.removeFirst();
          queuedGroupIds.remove(job.groupId);

          // Always yield between group validations. The debounce window
          // coalesces replay bursts; this yield keeps validation cooperative.
          await Future<void>.delayed(Duration.zero);
          if (closed) return;

          final group = groups[job.groupId];
          if (group == null) continue;

          try {
            result.add(await validateGroup(group: group, tradeId: job.tradeId));
          } catch (error, stackTrace) {
            result.addError(error, stackTrace);
          }
        }
      } finally {
        processing = false;
        maybeForwardDeferredStatus();

        if (!closed && validationQueue.isNotEmpty) {
          unawaited(processQueue());
        }
      }
    }

    void flushPendingItems() {
      debounceTimer = null;
      if (closed) return;

      final items = List<Order>.of(pendingItems);
      pendingItems.clear();

      for (final item in items) {
        final tradeId = item.getDtag() ?? item.id; // for logging only
        final groupId = rawOrderGroupId(item);
        final existing = groups[groupId];
        groups[groupId] = existing != null
            ? existing.addOrder(item)
            : OrderGroup.fromOrder(item);
        enqueueValidation(groupId, tradeId);
      }

      unawaited(processQueue());
      maybeForwardDeferredStatus();
    }

    result = StreamWithStatus<Validation<OrderGroup>>(
      onClose: () async {
        closed = true;
        debounceTimer?.cancel();
        await itemSub.cancel();
        await statusSub.cancel();
        if (closeSourceOnClose) {
          await source.close();
        }
      },
    );

    itemSub = source.replayStream.listen((item) {
      pendingItems.add(item);
      debounceTimer?.cancel();
      debounceTimer = Timer(debounce, flushPendingItems);
    }, onError: result.addError);

    statusSub = source.status.listen((status) {
      if (status is StreamStatusError) {
        result.addStatus(status);
        return;
      }

      if (status is StreamStatusQueryComplete || status is StreamStatusLive) {
        deferredStatus = status;
        maybeForwardDeferredStatus();
        return;
      }

      result.addStatus(status);
    }, onError: result.addError);

    return result;
  }
}
