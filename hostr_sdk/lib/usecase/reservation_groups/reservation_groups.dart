import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../escrow/escrow_verification.dart';
import '../evm/evm.dart';
import '../reservations/reservations.dart';

/// Dependencies resolved for a single reservation-group verification.
class ReservationGroupDeps {
  final Listing listing;

  const ReservationGroupDeps({required this.listing});
}

/// Use case that groups raw [Reservation] events into [ReservationGroup]s
/// per trade id (d-tag) and runs validation over them.
///
/// Follows the same `subscribeVerified` / `queryVerified` API shape used by
/// [Reviews] via [CanVerify], but operates on [ReservationGroup] rather
/// than a single [Nip01Event].
///
/// Validation rules per group:
/// 1. Either party cancelled → [Valid] (cancellation is a legitimate protocol
///    outcome, not a structural error).
/// 2. Seller confirmation exists → [Valid] (host confirmed the trade).
/// 3. Buyer-only (self-signed) → validate payment proof via
///    [Reservation.validate].
@Singleton()
class ReservationGroups {
  final Reservations _reservations;
  final CustomLogger _logger;
  final Evm _evm;

  /// Lazily constructed on-chain escrow verifier.
  late final EscrowVerification escrowVerification = EscrowVerification(
    evm: _evm,
    logger: _logger,
  );

  ReservationGroups({
    required Reservations reservations,
    required CustomLogger logger,
    required Evm evm,
  }) : _reservations = reservations,
       _logger = logger.scope('reservation-groups'),
       _evm = evm;

  // ── Public API ──────────────────────────────────────────────────────

  /// Validates reservation groups from an **external** [source] stream.
  ///
  /// Unlike [subscribeVerified], the caller owns the [source] lifetime —
  /// passing `closeSourceOnClose: false` (the default) keeps the shared
  /// stream alive when this view is closed.
  StreamWithStatus<List<Validation<ReservationGroup>>> verifyFromSource({
    required StreamWithStatus<Reservation> source,
    Duration debounce = const Duration(milliseconds: 350),
    bool closeSourceOnClose = false,
    bool forceValidateSelfSigned = false,
    bool Function(ReservationGroup group)? forceValidatePredicate,
  }) => _logger.spanSync('verifyFromSource', () {
    return _buildValidatedStream(
      source: source,
      debounce: debounce,
      closeSourceOnClose: closeSourceOnClose,
      forceValidateSelfSigned: forceValidateSelfSigned,
      forceValidatePredicate: forceValidatePredicate,
    );
  });

  /// Live subscription that emits validated reservation groups for [listing].
  ///
  /// When [forceValidateSelfSigned] is `true`, buyer-published reservations
  /// are always checked for a valid payment proof — even when a seller
  /// confirmation already exists. This is the mode escrow arbitration uses.
  StreamWithStatus<List<Validation<ReservationGroup>>> subscribeVerified({
    required String listingAnchor,
    Duration debounce = const Duration(milliseconds: 350),
    bool forceValidateSelfSigned = false,
    bool Function(ReservationGroup group)? forceValidatePredicate,
  }) => _logger.spanSync('subscribeVerified', () {
    final source = _reservations.subscribe(
      Filter(
        tags: {
          kListingRefTag: [listingAnchor],
        },
      ),
      name: 'ReservationGroups-verified',
    );
    return _buildValidatedStream(
      source: source,
      debounce: debounce,
      closeSourceOnClose: true,
      forceValidateSelfSigned: forceValidateSelfSigned,
      forceValidatePredicate: forceValidatePredicate,
    );
  });

  /// One-shot query that emits validated reservation groups for [listing].
  ///
  /// When [forceValidateSelfSigned] is `true`, buyer-published reservations
  /// are always checked for a valid payment proof — even when a seller
  /// confirmation already exists.
  StreamWithStatus<List<Validation<ReservationGroup>>> queryVerified({
    required String listingAnchor,
    Duration debounce = const Duration(milliseconds: 350),
    bool forceValidateSelfSigned = false,
    bool Function(ReservationGroup group)? forceValidatePredicate,
  }) => _logger.spanSync('queryVerified', () {
    final source = _reservations.query(
      Filter(
        tags: {
          kListingRefTag: [listingAnchor],
        },
      ),
      name: 'ReservationGroups-query',
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
  static Validation<ReservationGroup> verifyGroup(
    ReservationGroup group, {
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
      final buyer = group.buyerReservation;
      if (buyer == null) {
        // Seller-only trade with no buyer reservation to validate.
        if (group.sellerReservation != null) {
          return Valid(group);
        }
        return Invalid(group, 'No reservation found');
      }

      final validation = Reservation.validate(buyer);
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

    // 3. Seller (host) confirmation exists → Valid (default mode).
    if (group.sellerReservation != null) {
      return Valid(group);
    }

    // 4. Buyer-only: must have a buyer reservation to validate.
    final buyer = group.buyerReservation;
    if (buyer == null) {
      return Invalid(group, 'No reservation found');
    }

    // 5. Validate the buyer's self-signed proof.
    final validation = Reservation.validate(buyer);
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
  static Future<Validation<ReservationGroup>> verifyGroupOnChain(
    ReservationGroup group, {
    bool forceValidateSelfSigned = false,
    EscrowVerification? escrowVerification,
  }) async {
    // Run Nostr-level check first.
    final nostrResult = verifyGroup(
      group,
      forceValidateSelfSigned: forceValidateSelfSigned,
    );

    // If Nostr-level already invalid, no need for on-chain check.
    if (nostrResult is Invalid) return nostrResult;

    // Determine which buyer reservation to verify on-chain.
    final buyer = group.buyerReservation;
    if (buyer == null) return nostrResult;

    // Only check on-chain when:
    // a) escrowVerification is available, AND
    // b) buyer has an escrow proof, AND
    // c) either forceValidateSelfSigned OR no seller confirmation
    final hasEscrowProof = buyer.proof?.escrowProof != null;
    final needsOnChain =
        hasEscrowProof &&
        escrowVerification != null &&
        (forceValidateSelfSigned || group.sellerReservation == null);

    if (!needsOnChain) return nostrResult;

    final result = await escrowVerification.verify(reservation: buyer);

    if (result.isValid) return nostrResult;

    return Invalid(
      group,
      result.reason ?? 'On-chain escrow verification failed',
    );
  }

  // ── Stream plumbing ─────────────────────────────────────────────────

  StreamWithStatus<List<Validation<ReservationGroup>>> _buildValidatedStream({
    required StreamWithStatus<Reservation> source,
    required Duration debounce,
    required bool closeSourceOnClose,
    bool forceValidateSelfSigned = false,
    bool Function(ReservationGroup group)? forceValidatePredicate,
  }) {
    final groups = <String, Validation<ReservationGroup>>{};
    final snapshots = source.asyncMap<List<Validation<ReservationGroup>>>((
      item,
    ) async {
      final tradeId = item.getDtag() ?? item.id; // for logging only
      final groupId = ReservationGroup.groupIdFromEvent(item);
      final existing = groups[groupId];
      final updated = existing != null
          ? existing.event.addReservation(item)
          : ReservationGroup.fromReservation(item);
      final shouldForceValidate =
          forceValidatePredicate?.call(updated) ?? forceValidateSelfSigned;

      groups[groupId] = await verifyGroupOnChain(
        updated,
        forceValidateSelfSigned: shouldForceValidate,
        escrowVerification: escrowVerification,
      );

      if (groups[groupId] is Invalid) {
        _logger.w(
          'Group for trade $tradeId is invalid: ${(groups[groupId] as Invalid).reason}',
        );
        _logger.w('Buyer reservation: ${updated.buyerReservation}');
        _logger.w(
          'Buyer reservation proof: ${updated.buyerReservation?.proof}',
        );
        _logger.w('Seller reservation: ${updated.sellerReservation}');
        _logger.w('Escrow reservation: ${updated.escrowReservation}');
      } else {
        _logger.d('Group for trade $tradeId is valid');
      }

      return groups.values.toList();
    });

    if (closeSourceOnClose) {
      snapshots.onClose = () => source.close();
    }

    final response = StreamWithStatus<List<Validation<ReservationGroup>>>(
      onClose: () => snapshots.close(),
    );

    final latest = snapshots.items.lastOrNull;
    if (latest != null) {
      response.replaceAll([latest]);
    }

    response.addSubscription(
      snapshots.latestItemsStream.listen(
        (latest) => response.replaceAll([latest]),
        onError: response.addError,
      ),
    );
    response.addSubscription(
      snapshots.status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(response.addStatus, onError: response.addError),
    );

    return response;
  }
}
