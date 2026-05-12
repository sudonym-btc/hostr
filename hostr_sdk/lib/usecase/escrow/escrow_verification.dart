import 'package:injectable/injectable.dart';
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
@Singleton()
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
    final supportedContractHashes = escrowProof.hostsEscrowMethods
        .getTags('c')
        .map((element) => element.toLowerCase());

    if (!supportedContractHashes.contains(
      escrowService.contractBytecodeHash.toLowerCase(),
    )) {
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

  /// Compares the on-chain funded amount to the expected reservation cost,
  /// and verifies the security deposit (bond) when the listing requires one.
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

    final bindingError = _verifyFundedEventBinding(
      fundedEvent: fundedEvent,
      escrowProof: escrowProof,
      onChainAmount: onChainAmount,
    );
    if (bindingError != null) return bindingError;

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
    // Ensure the on-chain unlockAt matches the committed reservation end
    // date plus the listing's maxDisputePeriod.
    final reservationEnd = reservation.end;
    if (reservationEnd != null) {
      final maxDisputePeriod = proof.listing.maxDisputePeriod;
      final expectedUnlockAt =
          reservationEnd.millisecondsSinceEpoch ~/ 1000 + maxDisputePeriod;
      if (fundedEvent.unlockAt != expectedUnlockAt) {
        return EscrowVerificationResult.invalid(
          'Escrow unlockAt (${fundedEvent.unlockAt}) does not match '
          'reservation end + maxDisputePeriod ($expectedUnlockAt)',
        );
      }
    }

    logger.d(
      'Escrow verified for trade ${reservation.getDtag()}: '
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
    if (escrowProof.chainId != null &&
        escrowProof.chainId != fundedEvent.chainId) {
      return EscrowVerificationResult.invalid(
        'Escrow proof chain ${escrowProof.chainId} does not match funding '
        'event chain ${fundedEvent.chainId}',
      );
    }

    if (!_sameAddress(fundedEvent.contractAddress, service.contractAddress)) {
      return EscrowVerificationResult.invalid(
        'Escrow funding contract ${fundedEvent.contractAddress} does not match '
        'selected service contract ${service.contractAddress}',
      );
    }
    if (escrowProof.contractAddress != null &&
        !_sameAddress(
          escrowProof.contractAddress!,
          fundedEvent.contractAddress,
        )) {
      return EscrowVerificationResult.invalid(
        'Escrow proof contract ${escrowProof.contractAddress} does not match '
        'funding event contract ${fundedEvent.contractAddress}',
      );
    }

    final arbiter = fundedEvent.arbiter?.eip55With0x;
    if (arbiter == null || !_sameAddress(arbiter, service.evmAddress)) {
      return EscrowVerificationResult.invalid(
        'Escrow funding arbiter ${arbiter ?? 'missing'} does not match '
        'selected service arbiter ${service.evmAddress}',
      );
    }
    if (escrowProof.arbiterEvmAddress != null &&
        !_sameAddress(escrowProof.arbiterEvmAddress!, arbiter)) {
      return EscrowVerificationResult.invalid(
        'Escrow proof arbiter ${escrowProof.arbiterEvmAddress} does not match '
        'funding event arbiter $arbiter',
      );
    }

    final seller = fundedEvent.seller?.eip55With0x;
    if (escrowProof.sellerEvmAddress != null &&
        (seller == null ||
            !_sameAddress(escrowProof.sellerEvmAddress!, seller))) {
      return EscrowVerificationResult.invalid(
        'Escrow proof seller ${escrowProof.sellerEvmAddress} does not match '
        'funding event seller ${seller ?? 'missing'}',
      );
    }

    final buyer = fundedEvent.buyer?.eip55With0x;
    if (escrowProof.buyerEvmAddress != null &&
        (buyer == null || !_sameAddress(escrowProof.buyerEvmAddress!, buyer))) {
      return EscrowVerificationResult.invalid(
        'Escrow proof buyer ${escrowProof.buyerEvmAddress} does not match '
        'funding event buyer ${buyer ?? 'missing'}',
      );
    }

    if (escrowProof.tokenTagId != null &&
        AcceptedPaymentForm.canonicalTokenTagId(escrowProof.tokenTagId!) !=
            AcceptedPaymentForm.canonicalTokenTagId(
              onChainAmount.token.tagId,
            )) {
      return EscrowVerificationResult.invalid(
        'Escrow proof token ${escrowProof.tokenTagId} does not match funding '
        'event token ${onChainAmount.token.tagId}',
      );
    }

    if (escrowProof.unlockAt != null &&
        escrowProof.unlockAt != fundedEvent.unlockAt) {
      return EscrowVerificationResult.invalid(
        'Escrow proof unlockAt ${escrowProof.unlockAt} does not match funding '
        'event unlockAt ${fundedEvent.unlockAt}',
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
    if (escrowProof.escrowFee != null && escrowProof.escrowFee != actualFee) {
      return EscrowVerificationResult.invalid(
        'Escrow proof fee ${escrowProof.escrowFee} does not match funding '
        'event fee $actualFee',
      );
    }

    return null;
  }

  bool _sameAddress(String left, String right) =>
      left.toLowerCase() == right.toLowerCase();
}
