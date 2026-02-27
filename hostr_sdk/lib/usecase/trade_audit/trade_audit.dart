import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../escrow/escrow_verification.dart';
import '../evm/evm.dart';
import '../listings/listings.dart';
import '../reservation_transitions/reservation_transitions.dart';
import '../reservations/reservations.dart';

/// Audit result for one side of a trade (buyer or seller).
class PartyAudit {
  /// Human-readable role label: "BUYER" or "SELLER".
  final String role;

  /// The pubkey of this party.
  final String pubkey;

  /// Live reservation snapshot(s) published by this party, newest first.
  final List<Reservation> reservations;

  /// Each reservation paired with its validation result against the listing.
  final List<({Reservation reservation, ValidationResult validation})>
  validatedReservations;

  /// Transition events published by this party, chronological.
  final List<ReservationTransition> transitions;

  /// Validation of the transition chain ordering.
  final TransitionValidationResult transitionChainResult;

  /// On-chain escrow verification result, if applicable.
  final EscrowVerificationResult? escrowVerification;

  /// The current stage implied by the last transition (or null if none).
  ReservationStage? get currentStage {
    if (transitions.isEmpty) return null;
    return transitions.last.parsedContent.toStage;
  }

  PartyAudit({
    required this.role,
    required this.pubkey,
    required this.reservations,
    required this.validatedReservations,
    required this.transitions,
    required this.transitionChainResult,
    this.escrowVerification,
  });

  /// Summarise a single transition for display.
  static String describeTransition(ReservationTransition t) {
    final c = t.parsedContent;
    return '${c.transitionType.name}(${c.fromStage.name}→${c.toStage.name})';
  }
}

/// Complete audit report for one trade id.
class TradeAuditResult {
  final String tradeId;
  final Listing? listing;
  final PartyAudit? buyer;
  final PartyAudit? seller;

  /// One-sentence human-readable explanation of the trade outcome and fault.
  final String explanation;

  TradeAuditResult({
    required this.tradeId,
    this.listing,
    this.buyer,
    this.seller,
    required this.explanation,
  });

  /// Pretty-print the full audit report.
  String format() {
    final buf = StringBuffer();
    buf.writeln('═══ Trade Audit: $tradeId ═══');
    if (listing != null) {
      buf.writeln(
        'Listing: ${listing!.anchor} (host: ${_short(listing!.pubKey)})',
      );
    }
    buf.writeln();
    for (final party in [seller, buyer]) {
      if (party == null) continue;
      buf.writeln('── ${party.role} (${_short(party.pubkey)}) ──');
      if (party.reservations.isEmpty) {
        buf.writeln('  (no reservation events)');
      }
      for (final vr in party.validatedReservations) {
        final r = vr.reservation;
        final v = vr.validation;
        buf.writeln(
          '  reservation  stage=${r.parsedContent.stage.name}'
          '  cancelled=${r.parsedContent.cancelled}'
          '  valid=${v.isValid}',
        );
        if (!v.isValid) {
          for (final f in v.fields.entries.where((e) => !e.value.ok)) {
            buf.writeln('    ✗ ${f.key}: ${f.value.message}');
          }
        }
      }
      if (party.transitions.isEmpty) {
        buf.writeln('  (no transition events)');
      }
      for (final t in party.transitions) {
        buf.writeln('  transition  ${PartyAudit.describeTransition(t)}');
      }
      buf.writeln(
        '  chain: ${party.transitionChainResult.isValid ? "✓ valid" : "✗ ${party.transitionChainResult.reason}"}',
      );
      if (party.escrowVerification != null) {
        final ev = party.escrowVerification!;
        buf.writeln(
          '  escrow: ${ev.isValid ? "✓ verified on-chain (amount=${ev.trade?.value.getInWei} wei)" : "✗ ${ev.reason}"}',
        );
      }
      buf.writeln();
    }
    buf.writeln('Summary: $explanation');
    return buf.toString();
  }

  static String _short(String hex) => hex.length > 12
      ? '${hex.substring(0, 6)}…${hex.substring(hex.length - 6)}'
      : hex;
}

/// Use-case that assembles a full audit report for a given trade id.
///
/// Fetches reservations and transitions from the relay, resolves the listing,
/// groups by party, validates each piece, and produces a [TradeAuditResult]
/// with a one-sentence fault analysis.
@Singleton()
class TradeAudit {
  final Reservations reservations;
  final ReservationTransitions transitions;
  final Listings listings;
  final CustomLogger logger;
  final Evm evm;

  /// Lazily constructed on-chain escrow verifier.
  late final EscrowVerification escrowVerification = EscrowVerification(
    evm: evm,
    logger: logger,
  );

  TradeAudit({
    required this.reservations,
    required this.transitions,
    required this.listings,
    required this.logger,
    required this.evm,
  });

  /// Run the full audit for [tradeId] and return a structured result.
  Future<TradeAuditResult> audit(String tradeId) async {
    // 1. Fetch reservation snapshots and transitions in parallel.
    final results = await Future.wait([
      reservations.getByTradeId(tradeId),
      transitions.getForReservation(tradeId),
    ]);
    final allReservations = results[0] as List<Reservation>;
    final allTransitions = results[1] as List<ReservationTransition>;

    logger.d(
      'Trade $tradeId: ${allReservations.length} reservations, '
      '${allTransitions.length} transitions',
    );

    if (allReservations.isEmpty && allTransitions.isEmpty) {
      return TradeAuditResult(
        tradeId: tradeId,
        explanation: 'No records found for this trade id.',
      );
    }

    // 2. Resolve the listing from the first reservation's anchor tag.
    Listing? listing;
    String? sellerPubkey;
    if (allReservations.isNotEmpty) {
      final anchor = allReservations.first.parsedTags.listingAnchor;
      if (anchor.isNotEmpty) {
        sellerPubkey = getPubKeyFromAnchor(anchor) as String?;
        if (sellerPubkey != null) {
          listing = await listings.getOne(
            Filter(kinds: Listing.kinds, authors: [sellerPubkey]),
          );
        }
      }
    }

    // 3. Partition reservations and transitions by party.
    final sellerReservations = <Reservation>[];
    final buyerReservations = <Reservation>[];
    for (final r in allReservations) {
      if (sellerPubkey != null && r.pubKey == sellerPubkey) {
        sellerReservations.add(r);
      } else {
        buyerReservations.add(r);
      }
    }

    final sellerTransitions = <ReservationTransition>[];
    final buyerTransitions = <ReservationTransition>[];
    for (final t in allTransitions) {
      if (sellerPubkey != null && t.pubKey == sellerPubkey) {
        sellerTransitions.add(t);
      } else {
        buyerTransitions.add(t);
      }
    }

    // Sort transitions chronologically.
    int byCreatedAt(ReservationTransition a, ReservationTransition b) =>
        a.createdAt.compareTo(b.createdAt);
    sellerTransitions.sort(byCreatedAt);
    buyerTransitions.sort(byCreatedAt);

    // 4. Validate reservations against the listing.
    List<({Reservation reservation, ValidationResult validation})>
    validateReservations(List<Reservation> reservations) {
      return reservations.map((r) {
        final validation = listing != null
            ? Reservation.validate(r, listing)
            : ValidationResult(isValid: true, fields: {});
        return (reservation: r, validation: validation);
      }).toList();
    }

    final sellerValidated = validateReservations(sellerReservations);
    final buyerValidated = validateReservations(buyerReservations);

    // 4b. On-chain escrow verification for buyer's committed reservation.
    EscrowVerificationResult? buyerEscrowResult;
    if (listing != null) {
      final committedBuyer = buyerReservations
          .where(
            (r) =>
                r.parsedContent.stage == ReservationStage.commit &&
                r.parsedContent.proof?.escrowProof != null,
          )
          .toList();
      if (committedBuyer.isNotEmpty) {
        buyerEscrowResult = await escrowVerification.verify(
          reservation: committedBuyer.last,
          listing: listing,
        );
      }
    }

    // 5. Validate transition chains.
    final sellerChain = validateStateTransitions(sellerTransitions);
    final buyerChain = validateStateTransitions(buyerTransitions);

    // 6. Build party audits.
    PartyAudit? buildParty(
      String role,
      String? pubkey,
      List<Reservation> reservations,
      List<({Reservation reservation, ValidationResult validation})> validated,
      List<ReservationTransition> transitions,
      TransitionValidationResult chainResult, {
      EscrowVerificationResult? escrowResult,
    }) {
      if (pubkey == null && reservations.isEmpty && transitions.isEmpty) {
        return null;
      }
      return PartyAudit(
        role: role,
        pubkey:
            pubkey ??
            (reservations.isNotEmpty
                ? reservations.first.pubKey
                : transitions.first.pubKey),
        reservations: reservations,
        validatedReservations: validated,
        transitions: transitions,
        transitionChainResult: chainResult,
        escrowVerification: escrowResult,
      );
    }

    final sellerAudit = buildParty(
      'SELLER',
      sellerPubkey,
      sellerReservations,
      sellerValidated,
      sellerTransitions,
      sellerChain,
    );

    // Determine buyer pubkey.
    String? buyerPubkey;
    if (buyerReservations.isNotEmpty) {
      buyerPubkey = buyerReservations.first.pubKey;
    } else if (buyerTransitions.isNotEmpty) {
      buyerPubkey = buyerTransitions.first.pubKey;
    }

    final buyerAudit = buildParty(
      'BUYER',
      buyerPubkey,
      buyerReservations,
      buyerValidated,
      buyerTransitions,
      buyerChain,
      escrowResult: buyerEscrowResult,
    );

    // 7. Produce the one-sentence explanation.
    final explanation = _explain(
      tradeId: tradeId,
      seller: sellerAudit,
      buyer: buyerAudit,
      listing: listing,
    );

    return TradeAuditResult(
      tradeId: tradeId,
      listing: listing,
      buyer: buyerAudit,
      seller: sellerAudit,
      explanation: explanation,
    );
  }

  /// Derive a one-sentence fault analysis from the party audits.
  String _explain({
    required String tradeId,
    PartyAudit? seller,
    PartyAudit? buyer,
    Listing? listing,
  }) {
    // No data at all.
    if (seller == null && buyer == null) {
      return 'No reservation or transition data found for trade $tradeId.';
    }

    final sellerCancelled = seller?.currentStage == ReservationStage.cancel;
    final buyerCancelled = buyer?.currentStage == ReservationStage.cancel;

    // Both cancelled.
    if (sellerCancelled && buyerCancelled) {
      return 'Both parties cancelled the trade; no fault — mutual withdrawal.';
    }

    // Seller cancelled.
    if (sellerCancelled && !buyerCancelled) {
      return 'The seller cancelled the trade; fault lies with the seller for withdrawing after the buyer acted in good faith.';
    }

    // Buyer cancelled.
    if (buyerCancelled && !sellerCancelled) {
      return 'The buyer cancelled the trade; fault lies with the buyer for withdrawing.';
    }

    // Chain integrity issues.
    if (seller != null && !seller.transitionChainResult.isValid) {
      return 'The seller\'s transition chain is invalid (${seller.transitionChainResult.reason}); seller published malformed state transitions.';
    }
    if (buyer != null && !buyer.transitionChainResult.isValid) {
      return 'The buyer\'s transition chain is invalid (${buyer.transitionChainResult.reason}); buyer published malformed state transitions.';
    }

    // Reservation validity issues.
    final buyerInvalid = buyer?.validatedReservations
        .where((vr) => !vr.validation.isValid)
        .toList();
    final sellerInvalid = seller?.validatedReservations
        .where((vr) => !vr.validation.isValid)
        .toList();

    // On-chain escrow verification failure.
    if (buyer?.escrowVerification != null &&
        !buyer!.escrowVerification!.isValid) {
      return 'The buyer\'s on-chain escrow is invalid (${buyer.escrowVerification!.reason}); buyer is at fault.';
    }

    if (buyerInvalid != null && buyerInvalid.isNotEmpty) {
      final reasons = buyerInvalid
          .expand(
            (vr) => vr.validation.fields.entries
                .where((e) => !e.value.ok)
                .map((e) => e.value.message),
          )
          .where((m) => m != null)
          .toSet();
      return 'The buyer\'s reservation is invalid (${reasons.join('; ')}); buyer is at fault.';
    }
    if (sellerInvalid != null && sellerInvalid.isNotEmpty) {
      final reasons = sellerInvalid
          .expand(
            (vr) => vr.validation.fields.entries
                .where((e) => !e.value.ok)
                .map((e) => e.value.message),
          )
          .where((m) => m != null)
          .toSet();
      return 'The seller\'s reservation is invalid (${reasons.join('; ')}); seller is at fault.';
    }

    // Missing seller confirmation.
    if (seller == null || seller.reservations.isEmpty) {
      if (buyer != null && buyer.reservations.isNotEmpty) {
        return 'The buyer published a reservation but the seller never confirmed; seller is unresponsive.';
      }
    }

    // Missing buyer.
    if (buyer == null || buyer.reservations.isEmpty) {
      if (seller != null && seller.reservations.isNotEmpty) {
        return 'The seller published a reservation but no buyer reservation exists; buyer never committed.';
      }
    }

    // Both committed, no cancellation — active/completed trade.
    final sellerCommitted =
        seller?.currentStage == ReservationStage.commit ||
        seller?.reservations.any(
              (r) => r.parsedContent.stage == ReservationStage.commit,
            ) ==
            true;
    final buyerCommitted =
        buyer?.currentStage == ReservationStage.commit ||
        buyer?.reservations.any(
              (r) => r.parsedContent.stage == ReservationStage.commit,
            ) ==
            true;

    if (sellerCommitted && buyerCommitted) {
      return 'Both parties committed to the trade; no dispute — trade is active or completed.';
    }

    // Still negotiating.
    if (seller?.currentStage == ReservationStage.negotiate ||
        buyer?.currentStage == ReservationStage.negotiate) {
      return 'The trade is still in the negotiation stage; no fault yet.';
    }

    return 'Trade state is ambiguous; manual review recommended.';
  }
}
