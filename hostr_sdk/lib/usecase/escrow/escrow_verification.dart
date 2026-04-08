import 'package:models/main.dart';

import '../../util/main.dart';
import '../evm/evm.dart';
import 'supported_escrow_contract/supported_escrow_contract.dart';

/// Result of on-chain escrow verification for a single reservation.
class EscrowVerificationResult {
  final bool isValid;
  final String? reason;

  /// The on-chain trade data, if found.
  final EscrowFundedEvent? fundedEvent;

  const EscrowVerificationResult.valid({this.fundedEvent})
    : isValid = true,
      reason = null;

  const EscrowVerificationResult.invalid(this.reason)
    : isValid = false,
      fundedEvent = null;

  @override
  String toString() => isValid
      ? 'EscrowVerificationResult(valid, amount=${fundedEvent?.amount} wei)'
      : 'EscrowVerificationResult(invalid: $reason)';
}

/// Verifies that a self-signed reservation with an escrow proof has a
/// matching on-chain trade with the correct amount.
///
/// This is a stateless utility that can be used by:
/// - [ReservationGroups] when validating buyer-only groups
/// - [TradeAudit] when auditing a specific trade
///
/// It does NOT validate Nostr-level proof structure (signatures, listing
/// anchors, etc.) — that is handled by [Reservation.validate]. This class
/// only handles the EVM on-chain portion.
class EscrowVerification {
  final Evm _evm;
  final CustomLogger _logger;
  Evm get evm => _evm;
  CustomLogger get logger => _logger;

  EscrowVerification({required Evm evm, required CustomLogger logger})
    : _evm = evm,
      _logger = logger.scope('escrow-verify');

  /// Verify the on-chain escrow for [reservation] against [listing].
  ///
  /// Returns [EscrowVerificationResult.valid] when the on-chain trade
  /// was created, and the escrowed amount covers the reservation cost.
  ///
  /// Returns [EscrowVerificationResult.invalid] with a reason string when
  /// any check fails or no escrow proof is present.
  Future<EscrowVerificationResult> verify({required Reservation reservation}) =>
      logger.span('verify', () async {
        final proof = reservation.proof;
        if (proof == null) {
          return const EscrowVerificationResult.invalid(
            'No payment proof attached',
          );
        }

        final escrowProof = proof.escrowProof;
        if (escrowProof == null) {
          return const EscrowVerificationResult.invalid(
            'No escrow proof in payment proof',
          );
        }

        final proofError = _validateEscrowProof(escrowProof, reservation);
        if (proofError != null) return proofError;

        final contract = _resolveContract(escrowProof);

        final tradeId = reservation.getDtag();
        if (tradeId == null || tradeId.isEmpty) {
          return const EscrowVerificationResult.invalid(
            'Reservation has no trade id (d-tag)',
          );
        }

        final fundedOrError = await _queryFundedEvent(
          contract,
          tradeId,
          escrowProof.txHash,
        );
        if (fundedOrError is EscrowVerificationResult) return fundedOrError;
        final fundedEvent = fundedOrError as EscrowFundedEvent;

        return _verifyAmount(
          fundedEvent: fundedEvent,
          reservation: reservation,
          proof: proof,
          escrowProof: escrowProof,
        );
      });

  // ── Private helpers ─────────────────────────────────────────────

  /// Validates the escrow proof structure: pubkey match, signature, contract
  /// and service inclusion in the host's escrow methods.
  EscrowVerificationResult? _validateEscrowProof(
    EscrowProof escrowProof,
    Reservation reservation,
  ) {
    if (escrowProof.hostsEscrowMethods.pubKey !=
        getPubKeyFromAnchor(reservation.parsedTags.listingAnchor)) {
      return const EscrowVerificationResult.invalid(
        'Escrow proof is for a different listing (pubkey mismatch)',
      );
    }

    if (!escrowProof.hostsEscrowMethods.valid()) {
      return const EscrowVerificationResult.invalid(
        'Invalid signature on escrow methods',
      );
    }

    final escrowService = escrowProof.escrowService;

    if (escrowProof.hostsEscrowMethods
        .getTags('c')
        .where((element) => element == escrowService.contractBytecodeHash)
        .isEmpty) {
      return EscrowVerificationResult.invalid(
        'Host does not support escrow contract ${escrowService.contractBytecodeHash}',
      );
    }

    if (escrowProof.hostsEscrowMethods
        .getTags('p')
        .where((element) => element == escrowService.pubKey)
        .isEmpty) {
      return const EscrowVerificationResult.invalid(
        'Escrow proof does not include selected escrow service in trusted escrows',
      );
    }

    return null; // valid
  }

  /// Resolves the on-chain contract from the escrow proof's service selection.
  SupportedEscrowContract _resolveContract(EscrowProof escrowProof) {
    final escrowService = escrowProof.escrowService;
    final configuredChain = evm.getChainForEscrowService(escrowService);
    return configuredChain.escrow.getSupportedEscrowContract(escrowService);
  }

  /// Queries on-chain events for [tradeId] and returns the
  /// [EscrowFundedEvent] matching [txHash], or an invalid result.
  Future<Object> _queryFundedEvent(
    SupportedEscrowContract contract,
    String tradeId,
    String txHash,
  ) async {
    logger.d('Verifying escrow for trade $tradeId with contract $contract');

    final events = contract.allEvents(
      ContractEventsParams(tradeId: tradeId),
      null,
      includeLive: false,
    );
    try {
      final status = await events.status.firstWhere(
        (status) =>
            status is StreamStatusQueryComplete ||
            status is StreamStatusLive ||
            status is StreamStatusError,
      );
      if (status is StreamStatusError) {
        return EscrowVerificationResult.invalid(
          'Failed to query escrow logs for trade $tradeId: ${status.error}',
        );
      }

      EscrowFundedEvent? fundedEvent;
      for (final event in events.items) {
        if (event is EscrowFundedEvent && event.transactionHash == txHash) {
          fundedEvent = event;
          break;
        }
      }
      if (fundedEvent == null) {
        return EscrowVerificationResult.invalid(
          'Escrow logs do not contain a funding event for trade $tradeId in $txHash',
        );
      }

      return fundedEvent;
    } finally {
      await events.close();
    }
  }

  /// Compares the on-chain funded amount to the expected reservation cost.
  EscrowVerificationResult _verifyAmount({
    required EscrowFundedEvent fundedEvent,
    required Reservation reservation,
    required PaymentProof proof,
    required EscrowProof escrowProof,
  }) {
    final expectedAmount = reservation.resolveExpectedAmount(
      listing: proof.listing,
    );

    final onChainAmount = fundedEvent.amount;
    final expected = expectedAmount.expectedAmount;
    final denomination = expected.denomination;

    // Verify the host accepts this on-chain token for the denomination.
    if (!escrowProof.hostsEscrowMethods.acceptsToken(
      denomination,
      onChainAmount.token.tagId,
    )) {
      return EscrowVerificationResult.invalid(
        'Host does not accept token ${onChainAmount.token.tagId} '
        'for $denomination-denominated payments',
      );
    }

    // Scale the expected value from the denomination's decimals to the
    // on-chain token's decimals.
    final decimalDiff = onChainAmount.token.decimals - expected.decimals;
    final scaledExpectedValue = decimalDiff <= 0
        ? expected.value
        : expected.value * BigInt.from(10).pow(decimalDiff);
    final comparableExpected = TokenAmount(
      value: scaledExpectedValue,
      token: onChainAmount.token,
    );

    if (onChainAmount < comparableExpected) {
      final expectedAmountLabel = expectedAmount.usesNegotiatedAmount
          ? 'negotiated'
          : 'listing';
      final overrideReason = expectedAmount.overrideFailureReason;
      return EscrowVerificationResult.invalid(
        'Onchain escrowed amount (${onChainAmount.value}) is less than expected '
        '$expectedAmountLabel amount (${comparableExpected.value}) for '
        '${reservation.start} – ${reservation.end}'
        '${overrideReason != null ? ' ($overrideReason)' : ''}',
      );
    }

    logger.d(
      'Escrow verified for trade ${reservation.getDtag()}: '
      'funded event ${fundedEvent.transactionHash}, '
      'on-chain=${onChainAmount.value}, expected=${comparableExpected.value}',
    );

    return EscrowVerificationResult.valid(fundedEvent: fundedEvent);
  }
}
