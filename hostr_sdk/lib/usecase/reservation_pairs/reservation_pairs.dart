import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../escrow/escrow_verification.dart';
import '../evm/evm.dart';
import '../reservations/reservations.dart';

/// Dependencies resolved for a single reservation-pair verification.
class ReservationPairDeps {
  final Listing listing;

  const ReservationPairDeps({required this.listing});
}

/// Use case that groups raw [Reservation] events into seller/buyer pairs
/// per commitment hash and runs validation over them.
///
/// Follows the same `subscribeVerified` / `queryVerified` API shape used by
/// [Reviews] via [CanVerify], but operates on [ReservationPairStatus] rather
/// than a single [Nip01Event].
///
/// Validation rules per pair:
/// 1. Either party cancelled → [Invalid] (no proof check).
/// 2. Seller confirmation exists → [Valid] (host confirmed the trade).
/// 3. Buyer-only (self-signed) → validate payment proof via
///    [Reservation.validate].
@Singleton()
class ReservationPairs {
  final Reservations reservations;
  final CustomLogger logger;
  final Evm evm;

  /// Lazily constructed on-chain escrow verifier.
  late final EscrowVerification escrowVerification = EscrowVerification(
    evm: evm,
    logger: logger,
  );

  ReservationPairs({
    required this.reservations,
    required this.logger,
    required this.evm,
  });

  // ── Public API ──────────────────────────────────────────────────────

  /// Live subscription that emits validated reservation pairs for [listing].
  ///
  /// When [forceValidateSelfSigned] is `true`, buyer-published reservations
  /// are always checked for a valid payment proof — even when a seller
  /// confirmation already exists. This is the mode escrow arbitration uses.
  ValidatedStreamWithStatus<ReservationPairStatus> subscribeVerified({
    required Listing listing,
    Duration debounce = const Duration(milliseconds: 350),
    bool forceValidateSelfSigned = false,
    bool Function(ReservationPairStatus pair)? forceValidatePredicate,
  }) {
    final source = reservations.subscribe(
      Filter(
        tags: {
          kListingRefTag: [listing.anchor!],
        },
      ),
      name: 'ReservationPairs-verified',
    );
    return _buildValidatedStream(
      source: source,
      listing: listing,
      debounce: debounce,
      closeSourceOnClose: true,
      forceValidateSelfSigned: forceValidateSelfSigned,
      forceValidatePredicate: forceValidatePredicate,
    );
  }

  /// One-shot query that emits validated reservation pairs for [listing].
  ///
  /// When [forceValidateSelfSigned] is `true`, buyer-published reservations
  /// are always checked for a valid payment proof — even when a seller
  /// confirmation already exists.
  ValidatedStreamWithStatus<ReservationPairStatus> queryVerified({
    required Listing listing,
    Duration debounce = const Duration(milliseconds: 350),
    bool forceValidateSelfSigned = false,
    bool Function(ReservationPairStatus pair)? forceValidatePredicate,
  }) {
    final source = reservations.query(
      Filter(
        tags: {
          kListingRefTag: [listing.anchor!],
        },
      ),
      name: 'ReservationPairs-query',
    );
    return _buildValidatedStream(
      source: source,
      listing: listing,
      debounce: debounce,
      closeSourceOnClose: true,
      forceValidateSelfSigned: forceValidateSelfSigned,
      forceValidatePredicate: forceValidatePredicate,
    );
  }

  // ── Verification ────────────────────────────────────────────────────

  /// Pure verification of a single pair against its [listing].
  ///
  /// When [forceValidateSelfSigned] is `true` the buyer's payment proof is
  /// validated regardless of whether a seller confirmation exists. This is
  /// the mode used by escrow arbitration to ensure the on-chain amount is
  /// correct before ruling on a dispute.
  ///
  /// This is intentionally static so it can be used in tests or
  /// other contexts without needing the full usecase instance.
  static Validation<ReservationPairStatus> verifyPair(
    ReservationPairStatus pair,
    Listing listing, {
    bool forceValidateSelfSigned = false,
  }) {
    // 1. Cancelled → Valid (cancellation is a legitimate protocol outcome,
    // not a structural error). Callers that must exclude cancelled pairs
    // (availability checks, cancel action) filter on pair.cancelled directly.
    if (pair.cancelled) {
      return Valid(pair);
    }

    // 2. When forcing validation, always check the buyer's proof.
    if (forceValidateSelfSigned) {
      final buyer = pair.buyerReservation;
      if (buyer == null) {
        // Seller-only trade with no buyer reservation to validate.
        if (pair.sellerReservation != null) {
          return Valid(pair);
        }
        return Invalid(pair, 'No reservation found');
      }

      final validation = Reservation.validate(buyer, listing);
      if (validation.isValid) {
        return Valid(pair);
      }

      final reason = validation.fields.values
          .where((f) => !f.ok)
          .map((f) => f.message)
          .join('; ');
      return Invalid(
        pair,
        reason.isNotEmpty ? reason : 'Invalid payment proof',
      );
    }

    // 3. Seller (host) confirmation exists → Valid (default mode).
    if (pair.sellerReservation != null) {
      return Valid(pair);
    }

    // 4. Buyer-only: must have a buyer reservation to validate.
    final buyer = pair.buyerReservation;
    if (buyer == null) {
      return Invalid(pair, 'No reservation found');
    }

    // 5. Validate the buyer's self-signed proof.
    final validation = Reservation.validate(buyer, listing);
    if (validation.isValid) {
      return Valid(pair);
    }

    final reason = validation.fields.values
        .where((f) => !f.ok)
        .map((f) => f.message)
        .join('; ');
    return Invalid(pair, reason.isNotEmpty ? reason : 'Invalid payment proof');
  }

  /// Async verification that includes on-chain escrow amount checks.
  ///
  /// First runs [verifyPair] for Nostr-level validation. If the buyer has
  /// an escrow proof and [escrowVerification] is available, also verifies
  /// the on-chain trade amount covers the listing cost.
  ///
  /// When [forceValidateSelfSigned] is `true` the buyer's escrow proof is
  /// checked regardless of whether a seller confirmation exists.
  static Future<Validation<ReservationPairStatus>> verifyPairOnChain(
    ReservationPairStatus pair,
    Listing listing, {
    bool forceValidateSelfSigned = false,
    EscrowVerification? escrowVerification,
  }) async {
    // Run Nostr-level check first.
    final nostrResult = verifyPair(
      pair,
      listing,
      forceValidateSelfSigned: forceValidateSelfSigned,
    );

    // If Nostr-level already invalid, no need for on-chain check.
    if (nostrResult is Invalid) return nostrResult;

    // Determine which buyer reservation to verify on-chain.
    final buyer = pair.buyerReservation;
    if (buyer == null) return nostrResult;

    // Only check on-chain when:
    // a) escrowVerification is available, AND
    // b) buyer has an escrow proof, AND
    // c) either forceValidateSelfSigned OR no seller confirmation
    final hasEscrowProof = buyer.parsedContent.proof?.escrowProof != null;
    final needsOnChain =
        hasEscrowProof &&
        escrowVerification != null &&
        (forceValidateSelfSigned || pair.sellerReservation == null);

    if (!needsOnChain) return nostrResult;

    final result = await escrowVerification.verify(
      reservation: buyer,
      listing: listing,
    );

    if (result.isValid) return nostrResult;

    return Invalid(
      pair,
      result.reason ?? 'On-chain escrow verification failed',
    );
  }

  // ── Stream plumbing ─────────────────────────────────────────────────

  ValidatedStreamWithStatus<ReservationPairStatus> _buildValidatedStream({
    required StreamWithStatus<Reservation> source,
    required Listing listing,
    required Duration debounce,
    required bool closeSourceOnClose,
    bool forceValidateSelfSigned = false,
    bool Function(ReservationPairStatus pair)? forceValidatePredicate,
  }) {
    late final StreamSubscription<StreamStatus> statusSub;
    late final StreamSubscription<List<Reservation>> listSub;
    late final ValidatedStreamWithStatus<ReservationPairStatus> response;
    Timer? debounceTimer;
    var hasValidatedAtLeastOnce = false;
    var initialQuerySettled = false;
    var validationRunToken = 0;
    StreamStatus? latestSourceStatus;
    List<Reservation> latestRawReservations = const [];
    Map<String, ReservationPairStatus> latestPairs = const {};

    bool pairHasBothSides(ReservationPairStatus pair) {
      return pair.sellerReservation != null && pair.buyerReservation != null;
    }

    bool samePairSnapshot(ReservationPairStatus a, ReservationPairStatus b) {
      return a.sellerReservation?.id == b.sellerReservation?.id &&
          a.buyerReservation?.id == b.buyerReservation?.id;
    }

    Future<void> runValidationNow() async {
      final snapshot = List<Reservation>.unmodifiable(latestRawReservations);
      final token = ++validationRunToken;

      logger.d(
        '[reservation-pairs] validate start '
        'listing=${listing.anchor} '
        'rawReservations=${snapshot.length} '
        'forceValidateSelfSigned=$forceValidateSelfSigned '
        'token=$token',
      );

      response.addStatus(StreamStatusQuerying());

      final pairs = Reservations.toReservationPairs(
        reservations: snapshot,
        listing: listing,
      );

      final results = <Validation<ReservationPairStatus>>[];
      for (final entry in pairs.entries) {
        final tradeId = entry.key;
        final pair = entry.value;
        final hasSeller = pair.sellerReservation != null;
        final hasBuyer = pair.buyerReservation != null;

        logger.d(
          '[reservation-pairs] validating '
          'tradeId=$tradeId '
          'hasSeller=$hasSeller '
          'hasBuyer=$hasBuyer '
          'sellerCancelled=${pair.sellerCancelled} '
          'buyerCancelled=${pair.buyerCancelled}',
        );

        final perPairForce =
            forceValidateSelfSigned ||
            (forceValidatePredicate?.call(pair) ?? false);

        if (pair.cancelled) {
          logger.d(
            '[reservation-pairs] self-signed proof skipped '
            'tradeId=$tradeId reason=cancelled',
          );
        } else if (!hasBuyer) {
          logger.d(
            '[reservation-pairs] self-signed proof skipped '
            'tradeId=$tradeId reason=no-buyer-reservation',
          );
        } else if (!perPairForce && hasSeller) {
          logger.d(
            '[reservation-pairs] self-signed proof skipped '
            'tradeId=$tradeId reason=host-confirmed',
          );
        } else {
          logger.d(
            '[reservation-pairs] validating self-signed payment proof '
            'tradeId=$tradeId '
            'mode=${perPairForce ? 'forced' : 'default'} '
            'buyerId=${pair.buyerReservation?.id}',
          );
        }

        final validation = await verifyPairOnChain(
          pair,
          listing,
          forceValidateSelfSigned: perPairForce,
          escrowVerification: escrowVerification,
        );

        if (validation is Invalid<ReservationPairStatus>) {
          logger.d(
            '[reservation-pairs] invalid '
            'tradeId=$tradeId reason=${validation.reason}',
          );
        } else {
          logger.d('[reservation-pairs] valid tradeId=$tradeId');
        }

        results.add(validation);
      }

      if (token != validationRunToken) {
        // A newer validation run superseded this result.
        return;
      }

      response.setSnapshot(results);
      final invalidCount = results
          .whereType<Invalid<ReservationPairStatus>>()
          .length;
      logger.d(
        '[reservation-pairs] validate done '
        'listing=${listing.anchor} '
        'pairs=${results.length} '
        'valid=${results.length - invalidCount} '
        'invalid=$invalidCount '
        'token=$token',
      );
      hasValidatedAtLeastOnce = true;
      if (latestSourceStatus != null) {
        response.addStatus(latestSourceStatus!);
      }
    }

    void scheduleValidation() {
      debounceTimer?.cancel();
      if (debounce == Duration.zero) {
        unawaited(runValidationNow());
        return;
      }
      debounceTimer = Timer(debounce, () {
        unawaited(runValidationNow());
      });
    }

    response = ValidatedStreamWithStatus<ReservationPairStatus>(
      onClose: () async {
        debounceTimer?.cancel();
        await statusSub.cancel();
        await listSub.cancel();
        if (closeSourceOnClose) {
          await source.close();
        }
      },
    );

    statusSub = source.status.listen((status) {
      latestSourceStatus = status;
      if (status is StreamStatusError) {
        response.addStatus(status);
        return;
      }

      final isQuerySettled =
          status is StreamStatusQueryComplete || status is StreamStatusLive;
      if (!initialQuerySettled && isQuerySettled) {
        initialQuerySettled = true;
        debounceTimer?.cancel();
        // Initial query is done: now we know which pairs have no seller
        // counterpart and must validate buyer self-signed proofs.
        unawaited(runValidationNow());
        return;
      }

      // Don't advertise "live" until first validation snapshot is done.
      if (hasValidatedAtLeastOnce) {
        response.addStatus(status);
      }
    }, onError: response.addError);

    listSub = source.list.listen((rawReservations) {
      latestRawReservations = rawReservations;

      final currentPairs = Reservations.toReservationPairs(
        reservations: rawReservations,
        listing: listing,
      );

      final hasUpdatedSellerBuyerCombo = currentPairs.entries.any((entry) {
        final pair = entry.value;
        if (!pairHasBothSides(pair)) {
          return false;
        }
        final previous = latestPairs[entry.key];
        if (previous == null) {
          return true;
        }
        return !samePairSnapshot(previous, pair);
      });

      latestPairs = currentPairs;

      // Validate immediately when both buyer/seller snapshots are present for
      // a pair (so we can decide quickly if on-chain verification is needed).
      if (hasUpdatedSellerBuyerCombo) {
        debounceTimer?.cancel();
        unawaited(runValidationNow());
        return;
      }

      // Before initial query completion we postpone buyer-only validation,
      // because seller confirmations may still arrive in the same query.
      if (initialQuerySettled) {
        scheduleValidation();
      }
    }, onError: response.addError);

    return response;
  }
}
