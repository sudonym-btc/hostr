import 'dart:async';
import 'dart:math';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../../../../datasources/swagger_generated/boltz.swagger.dart';
import '../../../../../util/main.dart';
import '../../../../payments/operations/pay_models.dart';
import '../../../../payments/operations/pay_operation.dart';
import '../../../../payments/operations/pay_state.dart';
import '../../../main.dart';

class EvmSwapInOperation extends SwapInOperation {
  @override
  final EvmChain chain;

  EthereumAddress? get _requestedTokenAddress => params.amount.token.isERC20
      ? EthereumAddress.fromHex(params.amount.token.address)
      : null;

  BoltzEventScanner get _scanner =>
      BoltzEventScanner(swaps: chain.swaps!, chain: chain, logger: logger);

  EvmSwapInOperation({
    required this.chain,
    required super.auth,
    required super.logger,
    required super.params,
    super.initialState,
  });

  @override
  Future<({DenominatedAmount min, DenominatedAmount max})> getSwapLimits() =>
      logger.span(
        'getSwapLimits',
        () =>
            chain.swaps!.getSwapInLimits(tokenAddress: _requestedTokenAddress),
      );

  @override
  Map<String, Object?> get telemetryAttributes => {
    ...super.telemetryAttributes,
    'hostr.chain.id': chain.config.chainId,
  };

  // ── State machine ─────────────────────────────────────────────────────

  @override
  Future<SwapInState> executeStep(SwapInStep step) =>
      logger.span('executeStep', () async {
        applyTelemetry({'hostr.operation.step': step.name});
        return switch (step) {
          SwapInStep.createSwap => await _stepCreateSwap(),
          SwapInStep.dispatchPayment => await _stepDispatchPayment(),
          SwapInStep.ensureFunded => await _stepEnsureFunded(),
          SwapInStep.claimRelay => await _stepClaim(),
          SwapInStep.checkMempool => await _stepCheckClaimInMempool(),
          SwapInStep.confirmClaim => await _stepConfirmClaim(),
        };
      });

  // ── Step 1: Create the Boltz reverse-submarine swap ───────────────────

  Future<SwapInState> _stepCreateSwap() =>
      logger.span('stepCreateSwap', () async {
        final preimage = _newPreimage();
        logger.i('Generated swap preimage material');

        final creationBlock = await chain.client.getBlockNumber();

        /// Create a reverse submarine swap
        final swap = await _generateSwapRequest(preimage);

        // ── Persist recovery data immediately after swap creation ──
        // Boltz may not echo back `onchainAmount` in the response for EVM
        // reverse swaps — use the requested amount as fallback.
        final onchainSat =
            swap.onchainAmount?.toInt() ?? params.amount.getInSats.toInt();
        final data = SwapInData(
          boltzId: swap.id,
          preimageHex: hex.encode(preimage.preimage),
          preimageHash: preimage.hash,
          onchainAmountSat: onchainSat,
          timeoutBlockHeight: swap.timeoutBlockHeight!.toInt(),
          chainId: chain.config.chainId,
          accountIndex: params.accountIndex,
          creationBlockHeight: creationBlock,
          invoiceString: swap.invoice,
          parentOperationId: params.parentOperationId,
          tokenAddress: _requestedTokenAddress?.eip55With0x,
          postClaimCalls: params.postClaimCalls,
        );
        logger.i('Swap created: ${swap.id}');
        logger.d('Swap ${swap.toString()}');
        return SwapInRequestCreated(data);
      });

  // ── Step 2a: Dispatch payment + wait for lockup (foreground only) ─────

  Future<SwapInState>
  _stepDispatchPayment() => logger.span('stepDispatchPayment', () async {
    final data = state.data!;

    // Skip ahead if on-chain activity already exists.
    final existing = await _checkExistingProgress(data);
    if (existing != null) return existing;

    // ── Validate invoice ──
    final invoice = data.invoiceString;
    if (invoice == null) {
      throw StateError(
        'Swap ${data.boltzId} has no invoice — cannot pay. '
        'This swap may have been created before invoice persistence was added.',
      );
    }

    // Create the payment cubit but DON'T execute yet — we must subscribe
    // to its broadcast stream first to avoid losing fast-emitted states.
    final payment = _createPaymentForSwap(
      invoice: invoice,
      amount: params.amount,
      preimageHash: data.preimageHash,
      onchainAmountSat: data.onchainAmountSat,
    );

    // Start listening for Boltz's on-chain lockup.
    final swapStatusFuture = _waitForSwapOnChain(data.boltzId);
    emit(SwapInAwaitingOnChain(data));
    logger.i('Payment dispatched for swap ${data.boltzId}');

    // Subscribe to payment stream BEFORE executing so we never miss
    // states on the broadcast stream.
    final paymentCompleter = Completer<void>();
    final paySub = payment.stream
        .where((s) => s is PayFailed || s is PayExternalRequired)
        .takeUntil(swapStatusFuture.asStream())
        .listen(
          (paymentState) {
            emit(SwapInPaymentProgress(data, paymentState: paymentState));
          },
          onDone: () {
            if (!paymentCompleter.isCompleted) paymentCompleter.complete();
          },
        );

    // NOW execute the payment — the listener above is already active.
    payment.execute();

    // Wait until the payment stream completes (or Boltz lockup arrives).
    await paymentCompleter.future;
    await paySub.cancel();

    // Wait for Boltz's lockup transaction with a generous timeout.
    final swapStatus = await swapStatusFuture.timeout(
      const Duration(minutes: 30),
      onTimeout: () => throw TimeoutException(
        'Timed out waiting for Boltz to lock funds on-chain for swap ${data.boltzId}. '
        'The Lightning payment may still be pending. '
        'If Boltz never locks, the Lightning HTLC will expire and refund automatically.',
      ),
    );

    final lockupTxId = swapStatus.transaction?.id;
    if (lockupTxId == null) {
      throw StateError(
        'Boltz reported on-chain status but no transaction ID for swap ${data.boltzId}',
      );
    }

    // Wait for the lockup tx to be mined.
    logger.i('Waiting for lockup tx $lockupTxId to be mined…');
    await chain.awaitReceipt(lockupTxId);

    return _verifyLockupOnChain(
      data: data,
      reportedTxId: lockupTxId,
      boltzStatus: swapStatus.status,
    );
  });

  // ── Step 2b: Wait for on-chain lockup (foreground + background) ──────

  Future<SwapInState> _stepEnsureFunded() =>
      logger.span('stepEnsureFunded', () async {
        final data = state.data!;

        // Idempotent checks — may skip ahead.
        final existing = await _checkExistingProgress(data);
        if (existing != null) return existing;

        // No lockup yet — wait for Boltz to lock on-chain.
        return await _waitForLockupOnly(data);
      });

  /// Shared idempotent checks for on-chain progress.
  ///
  /// Returns a skip-ahead state if the swap is already funded / claimed /
  /// expired / terminal on Boltz, or `null` if the caller should proceed
  /// with its normal logic.
  Future<SwapInState?> _checkExistingProgress(
    SwapInData data,
  ) => logger.span('checkExistingProgress', () async {
    final scanner = _scanner;

    // ── Check chain for existing lockup (idempotent recovery) ──
    final lockup = await scanner.findLockup(
      preimageHash: data.preimageHash,
      fromBlock: data.creationBlockHeight,
      tokenAddress: data.tokenAddress,
    );
    if (lockup != null) {
      logger.i(
        'Found lockup on-chain for ${data.boltzId}: '
        'amount=${lockup.amount}, refund=${lockup.refundAddress}',
      );
      return SwapInFunded(
        data.copyWith(
          lockupTxHash: lockup.transactionHash,
          refundAddress: lockup.refundAddress.with0x,
        ),
      );
    }

    // ── Check if already claimed on-chain ──
    final claim = await scanner.findClaim(
      preimageHash: data.preimageHash,
      fromBlock: data.creationBlockHeight,
      tokenAddress: data.tokenAddress,
    );
    if (claim != null) {
      logger.i('Swap ${data.boltzId} already claimed on-chain');
      return SwapInCompleted(data.copyWith(claimTxHash: claim.transactionHash));
    }

    // ── Check if expired ──
    // Use getLocktimeBlockNumber() because on Arbitrum L2, Boltz returns
    // Ethereum L1 block numbers for timeouts while eth_blockNumber returns
    // the much-larger L2 sequencer block — causing false expiry detection.
    final currentBlock = await chain.getLocktimeBlockNumber();
    if (currentBlock >= data.timeoutBlockHeight) {
      logger.w(
        'Swap ${data.boltzId} expired (block $currentBlock >= ${data.timeoutBlockHeight})',
      );
      return SwapInFailed(
        'Swap expired. No on-chain funds at risk — Lightning payment '
        'refunds automatically via HTLC expiry.',
        data: data,
      );
    }

    // ── Check Boltz status for terminal conditions ──
    try {
      final boltzStatus = await chain.swaps!.boltzClient.getSwap(
        id: data.boltzId,
      );
      final status = boltzStatus.status;

      if (status == 'transaction.refunded') {
        return SwapInFailed(
          'Boltz refunded the on-chain lockup. The claim window expired.',
          data: data.copyWith(lastBoltzStatus: status),
        );
      }

      if (status == 'invoice.settled') {
        logger.i('Boltz reports ${data.boltzId} already settled');
        return SwapInCompleted(data.copyWith(lastBoltzStatus: status));
      }

      if (status == 'swap.expired' || status == 'transaction.failed') {
        return SwapInFailed(
          'Swap expired or failed before lockup. No on-chain funds at risk.',
          data: data.copyWith(lastBoltzStatus: status),
        );
      }

      // If Boltz says lockup is already in mempool/confirmed, verify on-chain.
      if (status == 'transaction.mempool' ||
          status == 'transaction.confirmed') {
        final txHash = boltzStatus.transaction?.id;
        if (txHash != null) {
          logger.i(
            'Boltz reports lockup tx $txHash — verifying against preimage hash',
          );
          await chain.awaitReceipt(txHash);

          final lockup = await scanner.findLockup(
            preimageHash: data.preimageHash,
            fromBlock: data.creationBlockHeight,
            tokenAddress: data.tokenAddress,
          );
          if (lockup != null) {
            final verifiedTxHash = lockup.transactionHash;
            if (verifiedTxHash != txHash) {
              logger.w(
                'Boltz reported tx $txHash but on-chain lockup for '
                '${data.preimageHash} is $verifiedTxHash. Using verified hash.',
              );
            }
            return SwapInFunded(
              data.copyWith(
                lockupTxHash: verifiedTxHash,
                refundAddress: lockup.refundAddress.with0x,
                lastBoltzStatus: status,
              ),
            );
          }
          logger.w(
            'Boltz reported lockup tx $txHash but no on-chain Lockup event '
            'matches preimage hash ${data.preimageHash} on '
            'chain ${chain.config.chainId} '
            '(isErc20=${data.tokenAddress != null}, '
            'tokenAddress=${data.tokenAddress}). Falling through.',
          );
        }
      }
    } catch (e) {
      logger.w('Could not check Boltz status for ${data.boltzId}: $e');
    }

    return null; // no existing progress — caller should proceed
  });

  /// Waits for the on-chain lockup via the Boltz WebSocket WITHOUT paying
  /// the Lightning invoice.  Used during recovery when the payment was
  /// already dispatched in a previous session.
  Future<SwapInState> _waitForLockupOnly(
    SwapInData data,
  ) => logger.span('waitForLockupOnly', () async {
    emit(SwapInAwaitingOnChain(data));

    final swapStatus = await _waitForSwapOnChain(data.boltzId).timeout(
      const Duration(minutes: 30),
      onTimeout: () => throw TimeoutException(
        'Timed out waiting for Boltz to lock funds on-chain for swap ${data.boltzId} '
        '(recovery). The Lightning payment may still be pending. '
        'If Boltz never locks, the Lightning HTLC will expire and refund automatically.',
      ),
    );

    final lockupTxId = swapStatus.transaction?.id;
    if (lockupTxId == null) {
      throw StateError(
        'Boltz reported on-chain status but no transaction ID for swap ${data.boltzId}',
      );
    }

    logger.i('Recovery: waiting for lockup tx $lockupTxId to be mined…');
    await chain.awaitReceipt(lockupTxId);

    return _verifyLockupOnChain(
      data: data,
      reportedTxId: lockupTxId,
      boltzStatus: swapStatus.status,
    );
  });

  /// Verifies that a Lockup event matching our preimage hash exists on-chain
  /// and cross-checks it against the [reportedTxId] from Boltz.
  /// Returns [SwapInFunded]. Throws if no matching lockup is found.
  Future<SwapInState> _verifyLockupOnChain({
    required SwapInData data,
    required String reportedTxId,
    required String? boltzStatus,
  }) => logger.span('verifyLockupOnChain', () async {
    final scanner = _scanner;
    var lockupOnChain = await scanner.findLockup(
      preimageHash: data.preimageHash,
      fromBlock: data.creationBlockHeight,
      tokenAddress: data.tokenAddress,
    );

    // Retry once after a short delay — RPC nodes can lag behind receipt
    // confirmation, causing getLogs to return stale results.
    if (lockupOnChain == null) {
      logger.i(
        'No lockup found on first attempt for ${data.boltzId} on '
        'chain ${chain.config.chainId}. Retrying in 3s…',
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      lockupOnChain = await scanner.findLockup(
        preimageHash: data.preimageHash,
        fromBlock: data.creationBlockHeight,
        tokenAddress: data.tokenAddress,
      );
    }

    if (lockupOnChain == null) {
      await scanner.logLockupDiagnostics(
        boltzId: data.boltzId,
        txHash: reportedTxId,
        preimageHash: data.preimageHash,
        creationBlockHeight: data.creationBlockHeight,
        tokenAddress: data.tokenAddress,
      );
      throw StateError(
        'Boltz reported lockup tx $reportedTxId for swap ${data.boltzId} '
        'on chain ${chain.config.chainId} '
        '(isErc20=${data.tokenAddress != null}, '
        'tokenAddress=${data.tokenAddress}), '
        'but no Lockup event matching preimage hash ${data.preimageHash} '
        'was found on-chain. See [lockup-diag] logs above for receipt details.',
      );
    }

    final verifiedTxHash = lockupOnChain.transactionHash;
    if (verifiedTxHash != reportedTxId) {
      logger.w(
        'Boltz reported lockup tx $reportedTxId but on-chain lockup for '
        'preimage hash ${data.preimageHash} is $verifiedTxHash. '
        'Using verified hash.',
      );
    }

    logger.i('Lockup verified on-chain: $verifiedTxHash');

    return SwapInFunded(
      data.copyWith(
        lockupTxHash: verifiedTxHash,
        refundAddress: lockupOnChain.refundAddress.with0x,
        lastBoltzStatus: boltzStatus,
      ),
    );
  });

  // ── Step 3: Claim the locked funds ────────────────────────────────────

  Future<SwapInState> _stepClaim() => logger.span('stepClaim', () async {
    final data = state.data!;

    // ── 3a. Check if already claimed on-chain (idempotent) ──
    final existingClaim = await _scanner.findClaim(
      preimageHash: data.preimageHash,
      fromBlock: data.creationBlockHeight,
      tokenAddress: data.tokenAddress,
    );
    if (existingClaim != null) {
      logger.i('Swap ${data.boltzId} already claimed on-chain');
      return SwapInClaimed(
        data.copyWith(claimTxHash: existingClaim.transactionHash),
      );
    }

    // ── 3b. Resolve refund address if missing ──
    var claimData = data;
    if (claimData.refundAddress == null && claimData.lockupTxHash != null) {
      final lockupTx = await chain.awaitTransaction(claimData.lockupTxHash!);
      claimData = claimData.copyWith(refundAddress: lockupTx.from.with0x);
    }

    if (claimData.refundAddress == null) {
      throw StateError(
        'Cannot claim swap ${claimData.boltzId}: missing refundAddress and lockupTxHash',
      );
    }

    // ── 3c. Build claim args and perform the claim ──
    final signer = BoltzClaimSigner(
      swaps: chain.swaps!,
      chainId: chain.config.chainId,
      logger: logger,
    );
    final claimArgs = await signer.buildClaimArgs(
      preimage: claimData.preimageBytes,
      preimageHash: claimData.preimageHash,
      onchainAmountSat: claimData.onchainAmountSat,
      refundAddress: EthereumAddress.fromHex(claimData.refundAddress!),
      timeoutBlockHeight: claimData.timeoutBlockHeight,
      signer: params.evmKey,
      tokenAddress: claimData.tokenAddress,
      destination: params.claimDestination,
      expectedClaimAddress: params.claimAddress ?? params.evmKey.address,
    );
    logger.i('Claiming swap ${claimData.boltzId} through relay');

    final postCalls = claimData.postClaimCalls;
    final String tx;
    if (postCalls != null && postCalls.isNotEmpty) {
      // Atomic claim + post-claim calls (e.g. escrow fund).
      final builder = BoltzCallBuilder(chain.swaps!);
      final claimCall = builder.claim(
        preimage: claimArgs.preimage,
        amount: claimArgs.amount,
        refundAddress: claimArgs.refundAddress,
        timelock: claimArgs.timelock,
        tokenAddress: claimArgs.tokenAddress,
      );
      final atomicCalls = {'claim': claimCall, ...postCalls};
      logger.i(
        'Atomic claim + ${postCalls.length} post-claim calls: '
        '${atomicCalls.keys.join(', ')}',
      );
      tx = await chain.sendCalls(params.evmKey, atomicCalls);
    } else {
      tx = await _claim(claimArgs: claimArgs);
    }
    logger.i('Claim broadcast for ${claimData.boltzId}: $tx');
    return SwapInClaimed(claimData.copyWith(claimTxHash: tx));
  });

  // ── Step 4: Wait for claim tx to appear in mempool (visual only) ────

  Future<SwapInState> _stepCheckClaimInMempool() =>
      logger.span('stepCheckClaimInMempool', () async {
        final data = state.data!;
        await chain.awaitTransaction(data.claimTxHash!);
        logger.i('Claim tx ${data.claimTxHash} visible in mempool');
        return SwapInClaimTxInMempool(data);
      });

  // ── Step 5: Confirm the claim receipt ─────────────────────────────────

  Future<SwapInState> _stepConfirmClaim() =>
      logger.span('stepConfirmClaim', () async {
        final data = state.data!;
        final receipt = await chain.awaitReceipt(data.claimTxHash!);
        logger.i('Claim receipt for ${data.boltzId}: $receipt');

        if (receipt.status != true) {
          logger.e(
            'Claim tx ${data.claimTxHash} REVERTED (status=${receipt.status}) '
            'for swap ${data.boltzId}. Will clear claimTxHash for retry.',
          );
          return SwapInFailed(
            'Claim transaction reverted on-chain (status=${receipt.status}). '
            'The lockup may be invalid or expired.',
            data: data.copyWith(claimTxHash: null),
          );
        }

        logger.i('Swap-in completed: ${data.claimTxHash}');
        chain.notifyNewBlock();
        return SwapInCompleted(data);
      });

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<ReverseResponse> _generateSwapRequest(
    ({List<int> preimage, String hash}) preimage,
  ) => logger.span('generateSwapRequest', () async {
    final claimAddress =
        (params.claimAddress ?? await chain.getAccountAddress(params.evmKey))
            .eip55With0x;
    final description = params.invoiceDescription ?? 'Hostr Reservation';
    final amountSats = params.amount.getInSats.toDouble();
    logger.i(
      'Using swap claim address: $claimAddress, $amountSats sats '
      '(side: ${params.amountSpec.side})',
    );
    return chain.swaps!.reverseSubmarine(
      // .output → user specified on-chain delivery → Boltz gets onchainAmount
      // .input  → user specified LN invoice amount → Boltz gets invoiceAmount
      onchainAmount: params.amountSpec.side == AmountSide.output
          ? amountSats
          : null,
      invoiceAmount: params.amountSpec.side == AmountSide.input
          ? amountSats
          : null,
      claimAddress: claimAddress,
      preimageHash: preimage.hash,
      description: description,
      tokenAddress: _requestedTokenAddress,
    );
  });

  /// Creates a payment cubit for the swap invoice but does NOT execute it.
  /// The caller MUST subscribe to the returned cubit's stream BEFORE calling
  /// [PayOperation.execute] to avoid losing states on the broadcast stream.
  PayOperation _createPaymentForSwap({
    required String invoice,
    required TokenAmount amount,
    required String preimageHash,
    required int onchainAmountSat,
  }) => logger.spanSync('createPaymentForSwap', () {
    Bolt11PaymentRequest pr = Bolt11PaymentRequest(invoice);
    final invoiceAmount = TokenAmount.fromDecimal(pr.amount.toString(), rbtc);
    final invoicePaymentHash = pr.tags
        .firstWhere((t) => t.type == 'payment_hash')
        .data;

    final invoiceSats = invoiceAmount.getInSats;
    final onchainSats = BigInt.from(onchainAmountSat);
    logger.i(
      'Validating swap invoice before dispatch: '
      'invoiceSats=$invoiceSats, onchainSats=$onchainSats, '
      'requestedOnchain=${amount.getInSats} sats, '
      'invoiceHash=$invoicePaymentHash, preimageHash=$preimageHash',
    );

    // ── Payment hash check (security-critical) ──
    // Ensures the invoice can't be settled until we reveal the preimage in
    // the on-chain claim transaction. Must throw in prod (not just assert).
    if (invoicePaymentHash != preimageHash) {
      throw StateError(
        'Invoice payment hash mismatch: '
        'invoice=$invoicePaymentHash, expected=$preimageHash. '
        'Refusing to pay — this invoice is not bound to our preimage.',
      );
    }

    // ── Invoice amount sanity check ──
    // The invoice was generated by Boltz during swap creation and already
    // includes their fees (percentage + lockup miner fee). We validate
    // against the on-chain amount Boltz committed to in the same response
    // — no extra pair lookup needed.
    if (invoiceSats < onchainSats) {
      throw StateError(
        'Invoice amount $invoiceSats sats is less than on-chain amount '
        '$onchainSats sats — invoice should always include Boltz fees.',
      );
    }
    // Boltz fees are typically <1% + small miner fee. The miner fee is a
    // fixed component that dominates at small swap amounts. Cap at 20%
    // to catch truly broken invoices without being brittle to fee changes
    // or small regtest amounts near the pair minimum.
    final maxFeeFraction = onchainSats * BigInt.from(20) ~/ BigInt.from(100);
    if (invoiceSats - onchainSats > maxFeeFraction) {
      throw StateError(
        'Invoice fees too high: invoice=$invoiceSats sats, '
        'onchain=$onchainSats sats, '
        'overhead=${invoiceSats - onchainSats} sats (>20%). '
        'Refusing to overpay.',
      );
    }

    return chain.payments.pay(Bolt11PayParameters(amount: amount, to: invoice));
  });

  Future<String> _claim({required ClaimArgs claimArgs}) =>
      logger.span('claim', () async {
        final preimageHash = sha256.convert(claimArgs.preimage).toString();
        logger.i(
          'claim: isErc20=${claimArgs.tokenAddress != null}, '
          'preimageHash=0x$preimageHash, '
          'amount=${claimArgs.amount}, '
          'tokenAddress=${claimArgs.tokenAddress?.eip55With0x}, '
          'refundAddress=${claimArgs.refundAddress.eip55With0x}, '
          'timelock=${claimArgs.timelock}',
        );

        final builder = BoltzCallBuilder(chain.swaps!);
        final intent = builder.claim(
          preimage: claimArgs.preimage,
          amount: claimArgs.amount,
          refundAddress: claimArgs.refundAddress,
          timelock: claimArgs.timelock,
          tokenAddress: claimArgs.tokenAddress,
        );
        return chain.sendCalls(params.evmKey, {'claim': intent});
      });

  /// Generate a cryptographically secure 32-byte preimage and its SHA-256 hash.
  ({List<int> preimage, String hash}) _newPreimage() {
    final random = Random.secure();
    final preimage = List<int>.generate(32, (i) => random.nextInt(256));
    final hash = sha256.convert(preimage).toString();
    return (preimage: preimage, hash: hash);
  }

  Future<SwapStatus> _waitForSwapOnChain(
    String id,
  ) => logger.span('waitForSwapOnChain', () {
    return chain.swaps!.boltzClient
        .subscribeToSwap(id: id)
        .doOnData((swapStatus) {
          logger.i('Swap status update: ${swapStatus.status}, $swapStatus');
          final data = state.data;
          if (data == null) return;

          // Boltz's backend has an internal reverse-swap `invoice.paid`
          // event when the hold invoice HTLC is accepted, before the preimage
          // is known. As of the current public API, that event is not emitted
          // on the swap WebSocket for reverse swaps; the first public signal
          // after payment is `transaction.mempool`, when Boltz broadcasts its
          // lockup transaction. Keep the UI state ready in case Boltz exposes
          // this event later.
          // if (swapStatus.status == 'invoice.paid') {
          //   emit(
          //     SwapInInvoicePaid(
          //       data.copyWith(lastBoltzStatus: swapStatus.status),
          //     ),
          //   );
          // }
          if (swapStatus.status == 'transaction.mempool' ||
              swapStatus.status == 'transaction.confirmed') {
            emit(
              SwapInLockupTxInMempool(
                data.copyWith(lastBoltzStatus: swapStatus.status),
              ),
            );
          }
        })
        .where(
          (swapStatus) =>
              swapStatus.status == 'transaction.confirmed' ||
              swapStatus.status == 'transaction.mempool' ||
              swapStatus.status == 'transaction.failed' ||
              swapStatus.status == 'swap.expired',
        )
        .map((swapStatus) {
          if (swapStatus.status == 'transaction.failed') {
            throw StateError(
              'Boltz failed to lock on-chain funds (transaction.failed). '
              'Lightning payment will be refunded automatically via HTLC expiry.',
            );
          }
          if (swapStatus.status == 'swap.expired') {
            throw StateError(
              'Swap expired before Boltz locked on-chain funds. '
              'Lightning payment will be refunded automatically.',
            );
          }
          return swapStatus;
        })
        .first;
  });
}
