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
/// - [ReservationPairs] when validating buyer-only pairs
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
  Future<EscrowVerificationResult> verify({
    required Reservation reservation,
  }) => logger.span('verify', () async {
    final proof = reservation.proof;
    if (proof == null) {
      return const EscrowVerificationResult.invalid(
        'No payment proof attached',
      );
    }

    final escrowProof = proof.escrowProof;
    if (escrowProof == null) {
      // Not an escrow-backed reservation — skip on-chain check.
      return const EscrowVerificationResult.invalid(
        'No escrow proof in payment proof',
      );
    }

    if (escrowProof.hostsEscrowMethods.pubKey !=
        getPubKeyFromAnchor(reservation.parsedTags.listingAnchor)) {
      return const EscrowVerificationResult.invalid(
        'Escrow proof is for a different listing (pubkey mismatch)',
      );
    }
    if (escrowProof.hostsTrustedEscrows.pubKey !=
        getPubKeyFromAnchor(reservation.parsedTags.listingAnchor)) {
      return const EscrowVerificationResult.invalid(
        'Escrow proof is for a different listing (trusted escrows pubkey mismatch)',
      );
    }

    if (!escrowProof.hostsEscrowMethods.valid()) {
      return const EscrowVerificationResult.invalid(
        'Invalid signature on escrow methods',
      );
    }
    if (!escrowProof.hostsTrustedEscrows.valid()) {
      return const EscrowVerificationResult.invalid(
        'Invalid signature on trusted escrows',
      );
    }

    // Resolve the chain and contract from the escrow service.
    final escrowService = escrowProof.escrowService;
    final chain = evm.getChainForEscrowService(escrowService);
    final contract = chain.getSupportedEscrowContract(escrowService);

    final chosenEscrowType = escrowService.escrowType
        .toString()
        .split('.')
        .last
        .toLowerCase();

    if (escrowProof.hostsEscrowMethods
        .getTags('t')
        .where((element) => element == chosenEscrowType)
        .isEmpty) {
      return EscrowVerificationResult.invalid(
        'Host does not support escrow method type $chosenEscrowType',
      );
    }

    // @todo: validate that host trusts the contract bytecodehash
    // if (escrowProof.hostsEscrowMethods
    //     .getTags('c')
    //     .where(
    //       (element) =>
    //           element == escrowService.contractBytecodeHash,
    //     )
    //     .isEmpty) {
    //   return EscrowVerificationResult.invalid(
    //     'Host does not support escrow contract ${escrowService.contractBytecodeHash}',
    //   );
    // }

    if (escrowProof.hostsTrustedEscrows
        .getTags('p')
        .where((element) => element == escrowService.pubKey)
        .isEmpty) {
      return const EscrowVerificationResult.invalid(
        'Escrow proof does not include selected escrow service in trusted escrows',
      );
    }

    // Use the trade id (d-tag) as the on-chain trade identifier.
    final tradeId = reservation.getDtag();
    if (tradeId == null || tradeId.isEmpty) {
      return const EscrowVerificationResult.invalid(
        'Reservation has no trade id (d-tag)',
      );
    }
    logger.d(
      'Verifying escrow for trade $tradeId on chain ${chain} with contract ${contract}',
    );

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
        if (event is EscrowFundedEvent &&
            event.transactionHash == escrowProof.txHash) {
          fundedEvent = event;
          break;
        }
      }
      if (fundedEvent == null) {
        return EscrowVerificationResult.invalid(
          'Escrow logs do not contain a funding event for trade $tradeId in ${escrowProof.txHash}',
        );
      }

      final expectedAmount = reservation.resolveExpectedAmount(
        listing: proof.listing,
      );

      // Compare on-chain funded amount against the expected amount.
      //
      // For native RBTC: both amounts carry 18-decimal precision.
      // For ERC-20 tokens: both amounts carry the token's native precision
      // (e.g. 6 for USDT). The on-chain amount comes from
      // `_tokenAmountFromTrade` which resolves the token from the trade's
      // token address, so the comparison is apples-to-apples.
      //
      // If the tokens differ (e.g. funded in RBTC but expected USDT), the
      // TokenAmount >= operator will throw — which is correct: a token
      // mismatch should fail verification.
      final onChainAmount = fundedEvent.amount;
      final expectedTokenAmount = expectedAmount.expectedAmount;

      // When the expected amount is in a different unit system (e.g. BTC
      // Lightning sats) we need to normalise to the on-chain token's
      // precision before comparing.
      final TokenAmount comparableExpected;
      if (expectedTokenAmount.token == onChainAmount.token) {
        comparableExpected = expectedTokenAmount;
      } else if (expectedTokenAmount.token.isLightning &&
          onChainAmount.token.isNative) {
        // Lightning BTC (8 dec) → RBTC (18 dec): 1 sat = 10^10 wei
        comparableExpected = rbtcFromSats(expectedTokenAmount.value);
      } else {
        // For ERC-20 tokens the expected amount should already be
        // denominated in the same token. If it isn't, treat as mismatch.
        return EscrowVerificationResult.invalid(
          'Token mismatch: on-chain token ${onChainAmount.token} '
          'does not match expected token ${expectedTokenAmount.token}',
        );
      }

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
        'Escrow verified for trade $tradeId: funded event ${fundedEvent.transactionHash}, '
        'on-chain=${onChainAmount.value}, expected=${comparableExpected.value}',
      );

      return EscrowVerificationResult.valid(fundedEvent: fundedEvent);
    } finally {
      await events.close();
    }
  });
}
