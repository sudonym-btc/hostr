import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../util/main.dart';
import '../evm/evm.dart';

/// Result of on-chain escrow verification for a single reservation.
class EscrowVerificationResult {
  final bool isValid;
  final String? reason;

  /// The on-chain trade data, if found.
  final TransactionInformation? trade;

  const EscrowVerificationResult.valid({this.trade})
    : isValid = true,
      reason = null;

  const EscrowVerificationResult.invalid(this.reason)
    : isValid = false,
      trade = null;

  @override
  String toString() => isValid
      ? 'EscrowVerificationResult(valid, amount=${trade?.value.getInWei} wei)'
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
  final Evm evm;
  final CustomLogger logger;

  EscrowVerification({required this.evm, required this.logger});

  /// Verify the on-chain escrow for [reservation] against [listing].
  ///
  /// Returns [EscrowVerificationResult.valid] when the on-chain trade
  /// exists, is active, and the escrowed amount covers the reservation cost.
  ///
  /// Returns [EscrowVerificationResult.invalid] with a reason string when
  /// any check fails or no escrow proof is present.
  Future<EscrowVerificationResult> verify({
    required Reservation reservation,
    required Listing listing,
  }) async {
    final proof = reservation.parsedContent.proof;
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

    if (escrowProof.hostsEscrowMethods.pubKey != listing.pubKey) {
      return const EscrowVerificationResult.invalid(
        'Escrow proof is for a different listing (pubkey mismatch)',
      );
    }
    if (escrowProof.hostsTrustedEscrows.pubKey != listing.pubKey) {
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

    final chosenEscrowType = escrowService.parsedContent.type
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
    //           element == escrowService.parsedContent.contractBytecodeHash,
    //     )
    //     .isEmpty) {
    //   return EscrowVerificationResult.invalid(
    //     'Host does not support escrow contract ${escrowService.parsedContent.contractBytecodeHash}',
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

    final fundTx = await contract.client.getTransactionByHash(
      escrowProof.txHash,
    );
    if (fundTx == null) {
      return EscrowVerificationResult.invalid(
        'Escrow proof transaction not found on chain: ${escrowProof.txHash}',
      );
    }
    if (fundTx.to != contract.address) {
      return EscrowVerificationResult.invalid(
        'Escrow proof transaction was sent to ${fundTx.to}, expected ${contract.address}',
      );
    }

    // Compute the expected cost from the listing.
    final expectedAmount = listing.cost(
      reservation.parsedContent.start,
      reservation.parsedContent.end,
    );

    // The on-chain amount is in wei. Compare against the expected amount.
    // We accept >= because escrowFee may be included in the deposit.
    final onChainWei = BitcoinAmount.fromBigInt(
      BitcoinUnit.wei,
      fundTx.value.getInWei,
    );
    final expectedWei = BitcoinAmount.fromAmount(expectedAmount);

    if (onChainWei < expectedWei) {
      return EscrowVerificationResult.invalid(
        'On-chain escrow amount ($onChainWei wei) is less than expected '
        '($expectedWei wei) for ${reservation.parsedContent.start} – '
        '${reservation.parsedContent.end}',
      );
    }

    logger.d(
      'Escrow verified for trade $tradeId: on-chain=$onChainWei wei, '
      'expected=$expectedWei wei',
    );

    return EscrowVerificationResult.valid(trade: fundTx);
  }
}
