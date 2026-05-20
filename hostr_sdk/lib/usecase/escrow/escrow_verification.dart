import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';

import '../../util/main.dart';
import '../evm/evm.dart';
import 'supported_escrow_contract/supported_escrow_contract.dart';

/// Result of on-chain escrow verification for a single order.
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

/// Verifies that a self-signed order with an escrow proof has a
/// matching on-chain trade with the correct amount.
///
/// This is a stateless utility that can be used by:
/// - [OrderGroups] when validating buyer-only groups
/// - [TradeAudit] when auditing a specific trade
///
/// It does NOT validate Nostr-level proof structure (signatures, listing
/// anchors, etc.) — that is handled by [Order.validate]. This class
/// only handles the EVM on-chain portion.
@Singleton()
class EscrowVerification {
  final Evm _evm;
  final CustomLogger _logger;
  Evm get evm => _evm;
  CustomLogger get logger => _logger;

  EscrowVerification({required Evm evm, required CustomLogger logger})
    : _evm = evm,
      _logger = logger.scope('escrow-verify');

  /// Verify the on-chain escrow for [order] against [listing].
  ///
  /// Returns [EscrowVerificationResult.valid] when the on-chain trade
  /// was created, and the escrowed amount covers the order cost.
  ///
  /// Returns [EscrowVerificationResult.invalid] with a reason string when
  /// any check fails or no escrow proof is present.
  Future<EscrowVerificationResult> verify({required Order order}) =>
      logger.span('verify', () async {
        final proof = order.proof;
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

        final proofError = _validateEscrowProof(escrowProof, order);
        if (proofError != null) return proofError;

        final contract = _resolveContract(escrowProof);

        final tradeId = order.getDtag();
        if (tradeId == null || tradeId.isEmpty) {
          return const EscrowVerificationResult.invalid(
            'Order has no trade id (d-tag)',
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
          order: order,
          proof: proof,
          escrowProof: escrowProof,
        );
      });

  // ── Private helpers ─────────────────────────────────────────────

  /// Validates the escrow proof structure: pubkey match, signature, contract
  /// and service inclusion in the host's escrow methods.
  EscrowVerificationResult? _validateEscrowProof(
    EscrowProof escrowProof,
    Order order,
  ) {
    if (escrowProof.sellerEscrowMethods.pubKey !=
        getPubKeyFromAnchor(order.parsedTags.listingAnchor)) {
      return const EscrowVerificationResult.invalid(
        'Escrow proof is for a different listing (pubkey mismatch)',
      );
    }

    if (!escrowProof.sellerEscrowMethods.valid()) {
      return const EscrowVerificationResult.invalid(
        'Invalid signature on escrow methods',
      );
    }

    final escrowService = escrowProof.escrowService;
    if (escrowService.escrowType != EscrowType.EVM ||
        escrowProof.params is! EvmEscrowProofParams) {
      return const EscrowVerificationResult.invalid(
        'Escrow proof params are not valid EVM params',
      );
    }

    final supportedContractHashes = escrowProof.sellerEscrowMethods
        .getTags('c')
        .map((element) => element.toLowerCase());

    if (!supportedContractHashes.contains(
      escrowService.contractBytecodeHash.toLowerCase(),
    )) {
      return EscrowVerificationResult.invalid(
        'Host does not support escrow contract ${escrowService.contractBytecodeHash}',
      );
    }

    if (escrowProof.sellerEscrowMethods
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

  /// Queries the proof transaction receipt for [tradeId] and returns the
  /// [EscrowFundedEvent] matching [txHash], or an invalid result.
  Future<Object> _queryFundedEvent(
    SupportedEscrowContract contract,
    String tradeId,
    String txHash,
  ) async {
    logger.d('Verifying escrow for trade $tradeId with contract $contract');

    try {
      final fundedEvent = await contract.fundedEventFromTransaction(
        tradeId: tradeId,
        txHash: txHash,
      );
      if (fundedEvent == null) {
        return EscrowVerificationResult.invalid(
          'Escrow transaction receipt does not contain a funding event for trade $tradeId in $txHash',
        );
      }
      return fundedEvent;
    } catch (error) {
      return EscrowVerificationResult.invalid(
        'Failed to query escrow transaction receipt for trade $tradeId in $txHash: $error',
      );
    }
  }

  /// Compares the on-chain funded amount to the expected order cost,
  /// and verifies the security deposit (bond) when the listing requires one.
  EscrowVerificationResult _verifyAmount({
    required EscrowFundedEvent fundedEvent,
    required Order order,
    required PaymentProof proof,
    required EscrowProof escrowProof,
  }) {
    final expectedAmount = order.resolveExpectedAmount(listing: proof.listing);

    final onChainAmount = fundedEvent.amount;
    final expected = expectedAmount.expectedAmount;
    final denomination = expected.denomination;

    final bindingError = _verifyFundedEventBinding(
      fundedEvent: fundedEvent,
      escrowProof: escrowProof,
      onChainAmount: onChainAmount,
    );
    if (bindingError != null) return bindingError;

    // Verify the host accepts this on-chain token for the denomination.
    if (!escrowProof.sellerEscrowMethods.acceptsToken(
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
        '${order.start} – ${order.end}'
        '${overrideReason != null ? ' ($overrideReason)' : ''}',
      );
    }

    // ── Security deposit (bond) verification ──────────────────────────
    final listingDeposit = proof.listing.securityDeposit;
    if (listingDeposit != null && listingDeposit.value > BigInt.zero) {
      final onChainBond = fundedEvent.bondAmount;
      if (onChainBond == null || onChainBond.value <= BigInt.zero) {
        return EscrowVerificationResult.invalid(
          'Listing requires a security deposit of ${listingDeposit.value} '
          '${listingDeposit.denomination} but no bond was escrowed',
        );
      }

      final bondDecimalDiff =
          onChainBond.token.decimals - listingDeposit.decimals;
      final scaledExpectedBond = bondDecimalDiff <= 0
          ? listingDeposit.value
          : listingDeposit.value * BigInt.from(10).pow(bondDecimalDiff);

      if (onChainBond.value < scaledExpectedBond) {
        return EscrowVerificationResult.invalid(
          'Onchain bond (${onChainBond.value}) is less than required '
          'security deposit ($scaledExpectedBond)',
        );
      }
    }

    // ── Max claim period verification ─────────────────────────────────
    // Ensure the on-chain unlockAt matches the committed order end
    // date plus the listing's maxDisputePeriod.
    final orderEnd = order.end;
    if (orderEnd != null) {
      final maxDisputePeriod = proof.listing.maxDisputePeriod;
      final expectedUnlockAt =
          orderEnd.millisecondsSinceEpoch ~/ 1000 + maxDisputePeriod;
      if (fundedEvent.unlockAt != expectedUnlockAt) {
        return EscrowVerificationResult.invalid(
          'Escrow unlockAt (${fundedEvent.unlockAt}) does not match '
          'order end + maxDisputePeriod ($expectedUnlockAt)',
        );
      }
    }

    logger.d(
      'Escrow verified for trade ${order.getDtag()}: '
      'funded event ${fundedEvent.transactionHash}, '
      'on-chain=${onChainAmount.value}, expected=${comparableExpected.value}'
      '${fundedEvent.bondAmount != null ? ', bond=${fundedEvent.bondAmount!.value}' : ''}',
    );

    return EscrowVerificationResult.valid(fundedEvent: fundedEvent);
  }

  EscrowVerificationResult? _verifyFundedEventBinding({
    required EscrowFundedEvent fundedEvent,
    required EscrowProof escrowProof,
    required TokenAmount onChainAmount,
  }) {
    final service = escrowProof.escrowService;

    if (fundedEvent.chainId != service.chainId) {
      return EscrowVerificationResult.invalid(
        'Escrow funding chain ${fundedEvent.chainId} does not match selected '
        'service chain ${service.chainId}',
      );
    }

    if (!_sameAddress(fundedEvent.contractAddress, service.contractAddress)) {
      return EscrowVerificationResult.invalid(
        'Escrow funding contract ${fundedEvent.contractAddress} does not match '
        'selected service contract ${service.contractAddress}',
      );
    }

    final arbiter = fundedEvent.arbiter?.eip55With0x;
    if (arbiter == null || !_sameAddress(arbiter, service.evmAddress)) {
      return EscrowVerificationResult.invalid(
        'Escrow funding arbiter ${arbiter ?? 'missing'} does not match '
        'selected service arbiter ${service.evmAddress}',
      );
    }

    final tokenAddress = onChainAmount.token.isERC20
        ? onChainAmount.token.address
        : 'native';
    final expectedFee = service.escrowFee(
      onChainAmount.value,
      tokenAddress: tokenAddress,
    );
    final actualFee = fundedEvent.escrowFee?.value ?? BigInt.zero;
    if (actualFee != expectedFee) {
      return EscrowVerificationResult.invalid(
        'Escrow fee $actualFee does not match selected service fee '
        '$expectedFee',
      );
    }

    return null;
  }

  bool _sameAddress(String left, String right) =>
      left.toLowerCase() == right.toLowerCase();
}
