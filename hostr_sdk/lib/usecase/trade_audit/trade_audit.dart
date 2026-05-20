import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';

import '../../util/main.dart';
import '../escrow/escrow_verification.dart';
import '../evm/evm.dart';
import '../listings/listings.dart';
import '../order_transitions/order_transitions.dart';
import '../orders/orders.dart';

/// Audit result for one side of a trade (buyer or seller).
class PartyAudit {
  /// Human-readable role label: "BUYER" or "SELLER".
  final String role;

  /// The pubkey of this party.
  final String pubkey;

  /// Live order snapshot(s) published by this party, newest first.
  final List<Order> orders;

  /// Each order paired with its validation result against the listing.
  final List<({Order order, ValidationResult validation})> validatedOrders;

  /// Transition events published by this party, chronological.
  final List<OrderTransition> transitions;

  /// Validation of the transition chain ordering.
  final TransitionValidationResult transitionChainResult;

  /// On-chain escrow verification result, if applicable.
  final EscrowVerificationResult? escrowVerification;

  /// The current stage implied by the last transition (or null if none).
  OrderStage? get currentStage {
    if (transitions.isEmpty) return null;
    return transitions.last.toStage;
  }

  PartyAudit({
    required this.role,
    required this.pubkey,
    required this.orders,
    required this.validatedOrders,
    required this.transitions,
    required this.transitionChainResult,
    this.escrowVerification,
  });

  /// Summarise a single transition for display.
  static String describeTransition(OrderTransition t) {
    return '${t.transitionType.name}(${t.fromStage.name}→${t.toStage.name})';
  }
}

/// Complete audit report for one trade id.
class TradeAuditResult {
  final String tradeId;
  final Listing? listing;
  final PartyAudit? buyer;
  final PartyAudit? seller;
  final PartyAudit? escrow;

  /// One-sentence human-readable explanation of the trade outcome and fault.
  final String explanation;

  TradeAuditResult({
    required this.tradeId,
    this.listing,
    this.buyer,
    this.seller,
    this.escrow,
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
    for (final party in [seller, escrow, buyer]) {
      if (party == null) continue;
      buf.writeln('── ${party.role} (${_short(party.pubkey)}) ──');
      if (party.orders.isEmpty) {
        buf.writeln('  (no order events)');
      }
      for (final vr in party.validatedOrders) {
        final r = vr.order;
        final v = vr.validation;
        buf.writeln(
          '  order  stage=${r.stage.name}'
          '  cancelled=${r.cancelled}'
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
          '  escrow: ${ev.isValid ? "✓ verified on-chain (amount=${ev.fundedEvent?.amount})" : "✗ ${ev.reason}"}',
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
/// Fetches orders and transitions from the relay, resolves the listing,
/// groups by party, validates each piece, and produces a [TradeAuditResult]
/// with a one-sentence fault analysis.
@Singleton()
class TradeAudit {
  final Orders _orders;
  final OrderTransitions _transitions;
  final Listings _listings;
  final CustomLogger _logger;
  final Evm _evm;
  Orders get orders => _orders;
  OrderTransitions get transitions => _transitions;
  Listings get listings => _listings;
  CustomLogger get logger => _logger;
  Evm get evm => _evm;

  /// Lazily constructed on-chain escrow verifier.
  late final EscrowVerification escrowVerification = EscrowVerification(
    evm: evm,
    logger: logger,
  );

  TradeAudit({
    required Orders orders,
    required OrderTransitions transitions,
    required Listings listings,
    required CustomLogger logger,
    required Evm evm,
  }) : _orders = orders,
       _transitions = transitions,
       _listings = listings,
       _logger = logger,
       _evm = evm;

  /// Run the full audit for [tradeId] and return a structured result.
  Future<TradeAuditResult> audit(String tradeId) => logger.span(
    'audit',
    () async {
      // 1. Fetch order snapshots and transitions in parallel.
      final results = await Future.wait([
        orders.getByTradeId(tradeId),
        transitions.getForOrder(tradeId),
      ]);
      final allOrders = results[0] as List<Order>;
      final allTransitions = results[1] as List<OrderTransition>;

      logger.d(
        'Trade $tradeId: ${allOrders.length} orders, '
        '${allTransitions.length} transitions',
      );

      if (allOrders.isEmpty && allTransitions.isEmpty) {
        return TradeAuditResult(
          tradeId: tradeId,
          explanation: 'No records found for this trade id.',
        );
      }

      // 2. Resolve the listing from the first order's anchor tag.
      Listing? listing;
      String? sellerPubkey;
      if (allOrders.isNotEmpty) {
        final anchor = allOrders.first.parsedTags.listingAnchor;
        if (anchor.isNotEmpty) {
          sellerPubkey = getPubKeyFromAnchor(anchor) as String?;
          if (sellerPubkey != null) {
            listing = await listings.getOne(
              Listing.baseFilter(authors: [sellerPubkey]),
            );
          }
        }
      }

      // 3. Resolve escrow pubkey from any order carrying an EscrowProof.
      String? escrowPubkey;
      for (final r in allOrders) {
        final pk = r.proof?.escrowProof?.escrowService.escrowPubkey;
        if (pk != null) {
          escrowPubkey = pk;
          break;
        }
      }

      // 4. Partition orders and transitions by party (seller / escrow / buyer).
      final sellerOrders = <Order>[];
      final escrowOrders = <Order>[];
      final buyerOrders = <Order>[];
      for (final r in allOrders) {
        if (sellerPubkey != null && r.pubKey == sellerPubkey) {
          sellerOrders.add(r);
        } else if (escrowPubkey != null && r.pubKey == escrowPubkey) {
          escrowOrders.add(r);
        } else {
          buyerOrders.add(r);
        }
      }

      final sellerTransitions = <OrderTransition>[];
      final escrowTransitions = <OrderTransition>[];
      final buyerTransitions = <OrderTransition>[];
      for (final t in allTransitions) {
        if (sellerPubkey != null && t.pubKey == sellerPubkey) {
          sellerTransitions.add(t);
        } else if (escrowPubkey != null && t.pubKey == escrowPubkey) {
          escrowTransitions.add(t);
        } else {
          buyerTransitions.add(t);
        }
      }

      // Resolve transition chains by `prev` pointers, not author-supplied time.
      final sellerChain = resolveStateTransitionChain(sellerTransitions);
      final rawEscrowChain = resolveStateTransitionChain(escrowTransitions);
      final escrowChain = TransitionChainResolution(
        transitions: rawEscrowChain.transitions,
        validation: validateEscrowStateTransitions(rawEscrowChain.transitions),
      );
      final buyerChain = resolveStateTransitionChain(buyerTransitions);

      // 5. Validate orders against the listing.
      List<({Order order, ValidationResult validation})> validateOrders(
        List<Order> orders,
      ) {
        return orders.map((r) {
          final validation = listing != null
              ? Order.validate(r)
              : ValidationResult(isValid: true, fields: {});
          return (order: r, validation: validation);
        }).toList();
      }

      final sellerValidated = validateOrders(sellerOrders);
      final escrowValidated = validateOrders(escrowOrders);
      final buyerValidated = validateOrders(buyerOrders);

      // 5b. On-chain escrow verification for buyer's committed order.
      EscrowVerificationResult? buyerEscrowResult;
      if (listing != null) {
        final committedBuyer = buyerOrders
            .where(
              (r) =>
                  r.stage == OrderStage.commit && r.proof?.escrowProof != null,
            )
            .toList();
        if (committedBuyer.isNotEmpty) {
          buyerEscrowResult = await escrowVerification.verify(
            order: committedBuyer.last,
          );
        }
      }

      // 7. Build party audits.
      PartyAudit? buildParty(
        String role,
        String? pubkey,
        List<Order> orders,
        List<({Order order, ValidationResult validation})> validated,
        List<OrderTransition> transitions,
        TransitionValidationResult chainResult, {
        EscrowVerificationResult? escrowResult,
      }) {
        if (pubkey == null && orders.isEmpty && transitions.isEmpty) {
          return null;
        }
        return PartyAudit(
          role: role,
          pubkey:
              pubkey ??
              (orders.isNotEmpty
                  ? orders.first.pubKey
                  : transitions.first.pubKey),
          orders: orders,
          validatedOrders: validated,
          transitions: transitions,
          transitionChainResult: chainResult,
          escrowVerification: escrowResult,
        );
      }

      final sellerAudit = buildParty(
        'SELLER',
        sellerPubkey,
        sellerOrders,
        sellerValidated,
        sellerChain.transitions,
        sellerChain.validation,
      );

      final escrowAudit = buildParty(
        'ESCROW',
        escrowPubkey,
        escrowOrders,
        escrowValidated,
        escrowChain.transitions,
        escrowChain.validation,
      );

      // Determine buyer pubkey.
      String? buyerPubkey;
      if (buyerOrders.isNotEmpty) {
        buyerPubkey = buyerOrders.first.pubKey;
      } else if (buyerChain.transitions.isNotEmpty) {
        buyerPubkey = buyerChain.transitions.first.pubKey;
      }

      final buyerAudit = buildParty(
        'BUYER',
        buyerPubkey,
        buyerOrders,
        buyerValidated,
        buyerChain.transitions,
        buyerChain.validation,
        escrowResult: buyerEscrowResult,
      );

      // 8. Produce the one-sentence explanation.
      final explanation = _explain(
        tradeId: tradeId,
        seller: sellerAudit,
        buyer: buyerAudit,
        escrow: escrowAudit,
        listing: listing,
      );

      return TradeAuditResult(
        tradeId: tradeId,
        listing: listing,
        buyer: buyerAudit,
        seller: sellerAudit,
        escrow: escrowAudit,
        explanation: explanation,
      );
    },
  );

  /// Derive a one-sentence fault analysis from the party audits.
  String _explain({
    required String tradeId,
    PartyAudit? seller,
    PartyAudit? buyer,
    PartyAudit? escrow,
    Listing? listing,
  }) {
    // No data at all.
    if (seller == null && buyer == null) {
      return 'No order or transition data found for trade $tradeId.';
    }

    final sellerCancelled = seller?.currentStage == OrderStage.cancel;
    final buyerCancelled = buyer?.currentStage == OrderStage.cancel;
    final escrowCancelled = escrow?.currentStage == OrderStage.cancel;

    // Chain integrity issues must outrank claimed terminal states. A malformed
    // chain cannot safely prove that a party reached cancel/commit.
    if (seller != null && !seller.transitionChainResult.isValid) {
      return 'The seller\'s transition chain is invalid (${seller.transitionChainResult.reason}); seller published malformed state transitions.';
    }
    if (buyer != null && !buyer.transitionChainResult.isValid) {
      return 'The buyer\'s transition chain is invalid (${buyer.transitionChainResult.reason}); buyer published malformed state transitions.';
    }
    if (escrow != null && !escrow.transitionChainResult.isValid) {
      return 'The escrow\'s transition chain is invalid (${escrow.transitionChainResult.reason}); escrow published malformed state transitions.';
    }

    // Escrow cancelled — escrow service withdrew from the trade.
    if (escrowCancelled) {
      return 'The escrow service cancelled the trade; escrow refused to proceed.';
    }

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

    // Order validity issues.
    final buyerInvalid = buyer?.validatedOrders
        .where((vr) => !vr.validation.isValid)
        .toList();
    final sellerInvalid = seller?.validatedOrders
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
      return 'The buyer\'s order is invalid (${reasons.join('; ')}); buyer is at fault.';
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
      return 'The seller\'s order is invalid (${reasons.join('; ')}); seller is at fault.';
    }

    // Escrow involvement expected but missing.
    final buyerClaimsEscrow =
        buyer?.orders.any((r) => r.proof?.escrowProof != null) == true;
    if (buyerClaimsEscrow && escrow == null) {
      return 'Buyer claims escrow involvement but the escrow service never confirmed; escrow is unresponsive.';
    }

    // Missing seller confirmation.
    if (seller == null || seller.orders.isEmpty) {
      if (buyer != null && buyer.orders.isNotEmpty) {
        return 'The buyer published a order but the seller never confirmed; seller is unresponsive.';
      }
    }

    // Missing buyer.
    if (buyer == null || buyer.orders.isEmpty) {
      if (seller != null && seller.orders.isNotEmpty) {
        return 'The seller published a order but no buyer order exists; buyer never committed.';
      }
    }

    // Both committed, no cancellation — active/completed trade.
    final sellerCommitted =
        seller?.currentStage == OrderStage.commit ||
        seller?.orders.any((r) => r.stage == OrderStage.commit) == true;
    final buyerCommitted =
        buyer?.currentStage == OrderStage.commit ||
        buyer?.orders.any((r) => r.stage == OrderStage.commit) == true;
    final escrowConfirmed =
        escrow?.currentStage == OrderStage.commit ||
        escrow?.orders.any((r) => r.stage == OrderStage.commit) == true;

    if (sellerCommitted && buyerCommitted) {
      final escrowNote = escrowConfirmed
          ? ' Escrow service confirmed.'
          : (buyerClaimsEscrow ? ' Escrow service has not yet confirmed.' : '');
      return 'Both parties committed to the trade; no dispute — trade is active or completed.$escrowNote';
    }

    // Still negotiating.
    if (seller?.currentStage == OrderStage.negotiate ||
        buyer?.currentStage == OrderStage.negotiate) {
      return 'The trade is still in the negotiation stage; no fault yet.';
    }

    return 'Trade state is ambiguous; manual review recommended.';
  }
}
