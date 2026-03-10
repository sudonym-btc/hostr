import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' hide params;

import '../../../../../../datasources/boltz/boltz.dart';
import '../../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../../datasources/swagger_generated/boltz.swagger.dart';
import '../../../../../../injection.dart';
import '../../../../../../util/main.dart';
import '../../../../../payments/operations/pay_models.dart';
import '../../../../../payments/operations/pay_operation.dart';
import '../../../../../payments/operations/pay_state.dart';
import '../../../../../payments/payments.dart';
import '../../../../operations/swap_in/swap_in_models.dart';
import '../../../../operations/swap_in/swap_in_operation.dart';
import '../../../../operations/swap_in/swap_in_state.dart';
import '../../rif_relay/rif_relay.dart';
import '../../rootstock.dart';

@injectable
class RootstockSwapInOperation extends SwapInOperation {
  final Rootstock rootstock;
  late final RifRelay rifRelay = getIt<RifRelay>(param1: rootstock.client);

  RootstockSwapInOperation({
    required this.rootstock,
    required super.auth,
    required super.logger,
    @factoryParam required super.params,
    @ignoreParam super.initialState,
  });

  @override
  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapLimits() =>
      logger.span('getSwapLimits', () => rootstock.getSwapInLimits());

  @override
  Map<String, Object?> get telemetryAttributes => {
    ...super.telemetryAttributes,
    'hostr.chain.id': rootstock.config.rootstockConfig.chainId,
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

        final creationBlock = await rootstock.client.getBlockNumber();

        /// Create a reverse submarine swap
        final swap = await _generateSwapRequest(preimage);

        // ── Persist recovery data immediately after swap creation ──
        final data = SwapInData(
          boltzId: swap.id,
          preimageHex: hex.encode(preimage.preimage),
          preimageHash: preimage.hash,
          onchainAmountSat: swap.onchainAmount?.toInt() ?? 0,
          timeoutBlockHeight: swap.timeoutBlockHeight.toInt(),
          chainId: rootstock.config.rootstockConfig.chainId,
          accountIndex: params.accountIndex,
          creationBlockHeight: creationBlock,
          invoiceString: swap.invoice,
          parentOperationId: params.parentOperationId,
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
    await rootstock.awaitReceipt(lockupTxId);

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
    // final lockupTx = await rootstock.awaitTransaction(data.lockupTxHash!);

    // ── Check chain for existing lockup (idempotent recovery) ──
    final lockup = await _findLockupOnChain(data);
    if (lockup != null) {
      logger.i(
        'Found lockup on-chain for ${data.boltzId}: '
        'amount=${lockup.amount}, refund=${lockup.refundAddress}',
      );
      return SwapInFunded(
        data.copyWith(
          lockupTxHash: lockup.event.transactionHash,
          refundAddress: lockup.refundAddress.with0x,
        ),
      );
    }

    // ── Check if already claimed on-chain ──
    final claim = await _findClaimOnChain(data);
    if (claim != null) {
      logger.i('Swap ${data.boltzId} already claimed on-chain');
      return SwapInCompleted(
        data.copyWith(claimTxHash: claim.event.transactionHash),
      );
    }

    // ── Check if expired ──
    final currentBlock = await rootstock.client.getBlockNumber();
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
      final boltzStatus = await getIt<BoltzClient>().getSwap(id: data.boltzId);
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
          await rootstock.awaitReceipt(txHash);

          final lockup = await _findLockupOnChain(data);
          if (lockup != null) {
            final verifiedTxHash = lockup.event.transactionHash!;
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
            'matches preimage hash ${data.preimageHash}. Falling through.',
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
    await rootstock.awaitReceipt(lockupTxId);

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
    final lockupOnChain = await _findLockupOnChain(data);
    if (lockupOnChain == null) {
      throw StateError(
        'Boltz reported lockup tx $reportedTxId for swap ${data.boltzId}, '
        'but no Lockup event matching preimage hash ${data.preimageHash} '
        'was found on-chain. The lockup may belong to a different swap.',
      );
    }

    final verifiedTxHash = lockupOnChain.event.transactionHash!;
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
    final existingClaim = await _findClaimOnChain(data);
    if (existingClaim != null) {
      logger.i('Swap ${data.boltzId} already claimed on-chain');
      return SwapInClaimed(
        data.copyWith(claimTxHash: existingClaim.event.transactionHash),
      );
    }

    // ── 3b. Resolve refund address if missing ──
    var claimData = data;
    if (claimData.refundAddress == null && claimData.lockupTxHash != null) {
      final lockupTx = await rootstock.awaitTransaction(
        claimData.lockupTxHash!,
      );
      claimData = claimData.copyWith(refundAddress: lockupTx.from.with0x);
    }

    if (claimData.refundAddress == null) {
      throw StateError(
        'Cannot claim swap ${claimData.boltzId}: missing refundAddress and lockupTxHash',
      );
    }

    // ── 3c. Perform the claim via RIF Relay ──
    final claimArgs = _claimArgsFromData(claimData);
    logger.i('Claiming swap ${claimData.boltzId} through relay');

    final tx = await _claim(claimArgs: claimArgs);
    logger.i('Claim broadcast for ${claimData.boltzId}: $tx');
    return SwapInClaimed(claimData.copyWith(claimTxHash: tx));
  });

  // ── Step 4: Wait for claim tx to appear in mempool (visual only) ────

  Future<SwapInState> _stepCheckClaimInMempool() =>
      logger.span('stepCheckClaimInMempool', () async {
        final data = state.data!;
        await rootstock.awaitTransaction(data.claimTxHash!);
        logger.i('Claim tx ${data.claimTxHash} visible in mempool');
        return SwapInClaimTxInMempool(data);
      });

  // ── Step 5: Confirm the claim receipt ─────────────────────────────────

  Future<SwapInState> _stepConfirmClaim() =>
      logger.span('stepConfirmClaim', () async {
        final data = state.data!;
        final receipt = await rootstock.awaitReceipt(data.claimTxHash!);
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
        return SwapInCompleted(data);
      });

  // ── Fee estimation ────────────────────────────────────────────────────

  @override
  Future<SwapInFees> estimateFees() => logger.span('estimateFees', () async {
    final boltz = getIt<BoltzClient>();
    final (:feeOverhead, invoiceAmount: _) = await boltz
        .computeInvoiceForDesiredOnchain(desiredOnchainAmount: params.amount);

    final relayFees = BitcoinAmount.fromBigInt(
      BitcoinUnit.wei,
      await rifRelay.estimateClaimBeforeLock(params.evmKey),
    );

    return SwapInFees(
      estimatedGasFees: BitcoinAmount.zero(),
      estimatedSwapFees: feeOverhead,
      estimatedRelayFees: relayFees,
    );
  });

  // ── On-chain event queries ────────────────────────────────────────────

  /// Scans the chain for a Lockup event matching [data.preimageHash].
  Future<Lockup?> _findLockupOnChain(SwapInData data) =>
      logger.span('findLockupOnChain', () async {
        try {
          final etherSwap = await rootstock.getEtherSwapContract();
          final fromBlock = data.creationBlockHeight != null
              ? BlockNum.exact(data.creationBlockHeight!)
              : const BlockNum.genesis();
          final preimageHashBytes = Uint8List.fromList(
            hex.decode(data.preimageHash),
          );

          // One-shot getLogs query — the streaming API (client.events) never
          // closes, so .toList() on it would hang forever.
          final event = etherSwap.self.event('Lockup');
          final filter = FilterOptions.events(
            contract: etherSwap.self,
            event: event,
            fromBlock: fromBlock,
            toBlock: const BlockNum.current(),
          );
          final logs = await rootstock.client.getLogs(filter);
          for (final log in logs) {
            // Pre-filter: match preimageHash from the first indexed topic
            // before calling decodeResults. The deployed contract may have
            // fewer indexed params than the generated ABI expects (e.g.
            // contract v3 vs ABI v6), causing a RangeError in decodeResults.
            final topics = log.topics;
            if (topics == null || topics.length < 2) continue;
            final topicHex = topics[1]!.replaceFirst('0x', '').toLowerCase();
            if (topicHex != data.preimageHash.toLowerCase()) continue;

            // Found our lockup — standard decode with manual fallback.
            try {
              final decoded = event.decodeResults(topics, log.data!);
              return Lockup(decoded, log);
            } catch (e) {
              logger.d('Standard Lockup decode failed, manual parse: $e');
              return _decodeLockupManually(log, preimageHashBytes);
            }
          }
          return null;
        } catch (e) {
          logger.w('Failed to query lockup events: $e');
          return null;
        }
      });

  /// Scans the chain for a Claim event matching [data.preimageHash].
  Future<Claim?> _findClaimOnChain(SwapInData data) =>
      logger.span('findClaimOnChain', () async {
        try {
          final etherSwap = await rootstock.getEtherSwapContract();
          final fromBlock = data.creationBlockHeight != null
              ? BlockNum.exact(data.creationBlockHeight!)
              : const BlockNum.genesis();
          final preimageHashBytes = Uint8List.fromList(
            hex.decode(data.preimageHash),
          );

          // One-shot getLogs query — the streaming API (client.events) never
          // closes, so .toList() on it would hang forever.
          final event = etherSwap.self.event('Claim');
          final filter = FilterOptions.events(
            contract: etherSwap.self,
            event: event,
            fromBlock: fromBlock,
            toBlock: const BlockNum.current(),
          );
          final logs = await rootstock.client.getLogs(filter);
          for (final log in logs) {
            // Pre-filter by preimageHash from the first indexed topic.
            final topics = log.topics;
            if (topics == null || topics.length < 2) continue;
            final topicHex = topics[1]!.replaceFirst('0x', '').toLowerCase();
            if (topicHex != data.preimageHash.toLowerCase()) continue;

            try {
              final decoded = event.decodeResults(topics, log.data!);
              return Claim(decoded, log);
            } catch (e) {
              logger.d('Standard Claim decode failed, manual parse: $e');
              return _decodeClaimManually(log, preimageHashBytes);
            }
          }
          return null;
        } catch (e) {
          logger.w('Failed to query claim events: $e');
          return null;
        }
      });

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<ReverseResponse> _generateSwapRequest(
    ({List<int> preimage, String hash}) preimage,
  ) => logger.span('generateSwapRequest', () async {
    final smartWalletInfo = await rifRelay.getSmartWalletAddress(params.evmKey);
    final claimAddress = smartWalletInfo.address.eip55With0x;
    final description = params.invoiceDescription ?? 'Hostr Reservation';
    logger.i(
      'Using RIF smart wallet as claim address: $claimAddress, ${params.amount.getInSats} sats',
    );
    return getIt<BoltzClient>().reverseSubmarine(
      invoiceAmount: params.amount.getInSats.toDouble(),
      claimAddress: claimAddress,
      preimageHash: preimage.hash,
      description: description,
    );
  });

  /// Creates a payment cubit for the swap invoice but does NOT execute it.
  /// The caller MUST subscribe to the returned cubit's stream BEFORE calling
  /// [PayOperation.execute] to avoid losing states on the broadcast stream.
  PayOperation _createPaymentForSwap({
    required String invoice,
    required BitcoinAmount amount,
    required String preimageHash,
  }) => logger.spanSync('createPaymentForSwap', () {
    Bolt11PaymentRequest pr = Bolt11PaymentRequest(invoice);
    final invoiceAmount = BitcoinAmount.fromDecimal(
      BitcoinUnit.bitcoin,
      pr.amount.toString(),
    );
    final invoicePaymentHash = pr.tags
        .firstWhere((t) => t.type == 'payment_hash')
        .data;
    logger.i('Validated swap invoice before dispatch');

    /// Before paying, check that the invoice swapper generated is for the correct amount
    assert(invoiceAmount == amount);

    /// Before paying, check that the invoice hash is equivalent to the preimage hash we generated
    /// Ensures we know the invoice can't be settled until we reveal it in the claim txn
    assert(invoicePaymentHash == preimageHash);

    return getIt<Payments>().pay(
      Bolt11PayParameters(amount: amount, to: invoice),
    );
  });

  /// Builds [ClaimArgs] purely from persisted [SwapInData] — no Boltz
  /// dependency. All parameters needed for the on-chain claim are stored
  /// in the data object.
  ClaimArgs _claimArgsFromData(SwapInData data) {
    return (
      amount: BitcoinAmount.fromBigInt(
        BitcoinUnit.sat,
        BigInt.from(data.onchainAmountSat),
      ).getInWei,
      preimage: data.preimageBytes,
      refundAddress: EthereumAddress.fromHex(data.refundAddress!),
      timelock: BigInt.from(data.timeoutBlockHeight),

      /// EIP-712 signature parts (placeholder zeros — uses 4-param claim overload)
      v: BigInt.zero,
      r: Uint8List(32),
      s: Uint8List(32),
    );
  }

  Future<String> _claim({required ClaimArgs claimArgs}) =>
      logger.span('claim', () async {
        EtherSwap etherSwap = await rootstock.getEtherSwapContract();
        return (await rifRelay.relayClaim(
          etherSwap,
          params.evmKey,
          claimArgs,
        )).txHash.toString();
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
    return getIt<BoltzClient>()
        .subscribeToSwap(id: id)
        .doOnData((swapStatus) {
          logger.i('Swap status update: ${swapStatus.status}, $swapStatus');
          // For reverse submarine swaps, `transaction.mempool` is the
          // signal that Boltz received the Lightning payment and locked
          // on-chain.  (`invoice.settled` is a terminal status that only
          // fires after the claim reveals the preimage.)
          if (swapStatus.status == 'transaction.mempool' ||
              swapStatus.status == 'transaction.confirmed') {
            final data = state.data;
            if (data != null) {
              emit(
                SwapInInvoicePaid(
                  data.copyWith(lastBoltzStatus: swapStatus.status),
                ),
              );
            }
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

  // ── Manual event decoders (ABI-version-agnostic) ──────────────────────

  /// Decodes a Lockup event from raw log data when [decodeResults] fails
  /// (e.g. deployed contract indexes fewer params than the generated ABI).
  Lockup _decodeLockupManually(FilterEvent log, Uint8List preimageHash) =>
      logger.spanSync('decodeLockupManually', () {
        final topics = log.topics!;
        final dataBytes = _hexToBytes(log.data!);
        final wordCount = dataBytes.length ~/ 32;
        final topicCount = topics.length; // includes event-signature topic

        BigInt amount = BigInt.zero;
        EthereumAddress claimAddress = EthereumAddress(Uint8List(20));
        EthereumAddress refundAddress = EthereumAddress(Uint8List(20));
        BigInt timelock = BigInt.zero;

        if (topicCount >= 4 && wordCount >= 2) {
          // 3 indexed (preimageHash, claimAddress, refundAddress)
          // data: [amount, timelock]
          claimAddress = _addressFromTopic(topics[2]!);
          refundAddress = _addressFromTopic(topics[3]!);
          amount = _bigIntFromWord(dataBytes, 0);
          timelock = _bigIntFromWord(dataBytes, 1);
        } else if (topicCount >= 3 && wordCount >= 3) {
          // 2 indexed (preimageHash, claimAddress)
          // data: [amount, refundAddress, timelock]
          claimAddress = _addressFromTopic(topics[2]!);
          amount = _bigIntFromWord(dataBytes, 0);
          refundAddress = _addressFromDataWord(dataBytes, 1);
          timelock = _bigIntFromWord(dataBytes, 2);
        } else if (topicCount >= 3 && wordCount >= 2) {
          // 2 indexed, 2 data words — no refundAddress in event
          claimAddress = _addressFromTopic(topics[2]!);
          amount = _bigIntFromWord(dataBytes, 0);
          timelock = _bigIntFromWord(dataBytes, 1);
          // refundAddress stays zero — caller resolves from tx sender
        } else if (topicCount >= 2 && wordCount >= 4) {
          // 1 indexed (preimageHash only)
          // data: [amount, claimAddress, refundAddress, timelock]
          amount = _bigIntFromWord(dataBytes, 0);
          claimAddress = _addressFromDataWord(dataBytes, 1);
          refundAddress = _addressFromDataWord(dataBytes, 2);
          timelock = _bigIntFromWord(dataBytes, 3);
        }

        return Lockup([
          preimageHash,
          amount,
          claimAddress,
          refundAddress,
          timelock,
        ], log);
      });

  /// Decodes a Claim event from raw log data.
  Claim _decodeClaimManually(FilterEvent log, Uint8List preimageHash) {
    final dataBytes = _hexToBytes(log.data!);
    // preimage is always the first (and only) non-indexed param
    final preimage = Uint8List.fromList(dataBytes.sublist(0, 32));
    return Claim([preimageHash, preimage], log);
  }

  // ── Low-level ABI helpers ─────────────────────────────────────────────

  static Uint8List _hexToBytes(String hexStr) {
    return Uint8List.fromList(hex.decode(hexStr.replaceFirst('0x', '')));
  }

  static BigInt _bigIntFromWord(Uint8List data, int wordIndex) {
    final start = wordIndex * 32;
    return BigInt.parse(hex.encode(data.sublist(start, start + 32)), radix: 16);
  }

  static EthereumAddress _addressFromTopic(String topicHex) {
    final bytes = hex.decode(topicHex.replaceFirst('0x', ''));
    // Address occupies the last 20 bytes of the 32-byte topic
    return EthereumAddress(Uint8List.fromList(bytes.sublist(12, 32)));
  }

  static EthereumAddress _addressFromDataWord(Uint8List data, int wordIndex) {
    final start = wordIndex * 32;
    return EthereumAddress(
      Uint8List.fromList(data.sublist(start + 12, start + 32)),
    );
  }
}
