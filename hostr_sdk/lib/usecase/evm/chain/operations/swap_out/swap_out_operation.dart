import 'dart:async';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';

import '../../../../../datasources/swagger_generated/boltz.swagger.dart'
    hide Call;
import '../../../../../util/main.dart';
import '../../../../nwc/nwc.dart';
import '../../../../payments/payments.dart';
import '../../../main.dart';

class EvmSwapOutOperation extends SwapOutOperation {
  @override
  final EvmChain chain;
  final Nwc nwc;
  final SwapOutQuoteService quoteService;
  final Payments payments;

  EthereumAddress? get _requestedTokenAddress {
    final amount = params.amount;
    if (amount == null || !amount.token.isERC20) return null;
    return EthereumAddress.fromHex(amount.token.address);
  }

  EvmSwapOutOperation({
    required this.chain,
    required super.auth,
    required super.logger,
    required this.nwc,
    required this.quoteService,
    required this.payments,
    required super.params,
    super.initialState,
  });

  // ── State machine ─────────────────────────────────────────────────────

  @override
  Future<SwapOutState> executeStep(SwapOutStep step) =>
      logger.span('executeStep', () async {
        return switch (step) {
          SwapOutStep.createSwap => await _stepCreateSwap(),
          SwapOutStep.lockFunds => await _stepLockFunds(),
          SwapOutStep.awaitResolution => await _stepAwaitResolution(),
          SwapOutStep.confirmRefund => await _stepConfirmRefund(),
        };
      });

  // ── Step 1: Acquire invoice + create Boltz submarine swap ─────────────

  Future<SwapOutState> _stepCreateSwap() =>
      logger.span('_stepCreateSwap', () async {
        emit(SwapOutRequestCreated());

        final quote = await _buildQuote();
        final invoice = await _acquireInvoice(quote);
        emit(SwapOutInvoiceCreated(invoice));
        logger.i('Invoice created: $invoice');

        final creationBlock = await chain.client.getBlockNumber();
        return await _prepareSwap(invoice, quote, creationBlock);
      });

  // ── Step 2: Lock funds in swap contract ───────────────────────────────

  Future<SwapOutState> _stepLockFunds() =>
      logger.span('_stepLockFunds', () async {
        final data = state.data!;

        // ── 2a. Check if already locked on-chain (idempotent recovery) ──
        if (data.lockTxHash != null) {
          return SwapOutFunded(data);
        }

        // ── 2b. Build lock calls ──
        final builder = BoltzCallBuilder(chain.swaps!);
        final isErc20 = data.tokenAddress != null;
        final Map<String, Call> lockCalls;

        if (isErc20) {
          final tokenAddr = EthereumAddress.fromHex(data.tokenAddress!);
          lockCalls = builder.erc20Lock(
            preimageHash: data.invoicePreimageHashBytes,
            amountWei: data.lockedAmountWei,
            tokenAddress: tokenAddr,
            claimAddress: EthereumAddress.fromHex(data.claimAddress),
            timeoutBlockHeight: data.timeoutBlockHeight,
          );
        } else {
          lockCalls = {
            'EtherSwap.lock': builder.nativeLock(
              preimageHash: data.invoicePreimageHashBytes,
              amountWei: data.lockedAmountWei,
              claimAddress: EthereumAddress.fromHex(data.claimAddress),
              timeoutBlockHeight: data.timeoutBlockHeight,
            ),
          };
        }

        // ── 2c. Broadcast (merge preLockCalls if set) ──
        final preCalls = data.preLockCalls;
        final Map<String, Call> allCalls;
        if (preCalls != null && preCalls.isNotEmpty) {
          allCalls = {...preCalls, ...lockCalls};
          logger.i(
            'Atomic pre-lock + lock (${allCalls.length} calls): '
            '${allCalls.keys.join(', ')}',
          );
        } else {
          allCalls = lockCalls;
        }
        final tx = await chain.sendCalls(params.evmKey, allCalls);
        logger.i('Locked funds in ${isErc20 ? 'ERC20Swap' : 'EtherSwap'}: $tx');

        return SwapOutFunded(
          data.copyWith(lockTxHash: tx, lastBoltzStatus: 'lock.broadcast'),
        );
      });

  // ── Step 3: Await Boltz invoice payment or trigger refund ─────────────
  //
  // NOTE: Boltz batches on-chain claim transactions (especially for ERC-20
  // swaps), so waiting for an on-chain claim event can block indefinitely.
  // Instead we treat Boltz reporting `invoice.paid` as the completion
  // signal — the user has received their Lightning sats at that point.
  //
  // To prevent a spoofed WebSocket event from tricking us into marking a
  // swap as complete, we cross-verify any WS `invoice.paid` against the
  // Boltz HTTP API (canonical server state) before accepting it.

  Future<SwapOutState> _stepAwaitResolution() =>
      logger.span('_stepAwaitResolution', () async {
        final data = state.data!;
        final boltz = chain.swaps!.boltzClient;

        // ── 3a. Quick on-chain check for already-resolved swaps ──
        // If Boltz has already claimed (or we already refunded), we can
        // short-circuit without any network round-trips to Boltz.
        final scanner = BoltzEventScanner(
          swaps: chain.swaps!,
          chain: chain,
          logger: logger,
        );

        final claimEvent = await scanner.findClaim(
          preimageHash: data.invoicePreimageHashHex,
          fromBlock: data.creationBlockHeight,
          tokenAddress: data.tokenAddress,
        );
        if (claimEvent != null) {
          logger.i('Found claim on-chain for ${data.boltzId} — swap succeeded');
          return SwapOutCompleted(
            data.copyWith(lastBoltzStatus: 'transaction.claimed'),
          );
        }

        final refundEvent = await scanner.findRefund(
          preimageHash: data.invoicePreimageHashHex,
          fromBlock: data.creationBlockHeight,
          tokenAddress: data.tokenAddress,
        );
        if (refundEvent != null) {
          logger.i('Found refund on-chain for ${data.boltzId}');
          return SwapOutRefunded(
            data.copyWith(resolutionTxHash: refundEvent.transactionHash),
          );
        }

        // ── 3b. Check Boltz HTTP status for terminal conditions ──
        try {
          final boltzResponse = await boltz.getSwap(id: data.boltzId);
          final status = boltzResponse.status;

          // Boltz reports the invoice was paid — verify with preimage
          // proof before trusting it. The on-chain claim tx may arrive
          // later (batched), but the preimage proves the LN payment settled.
          // `transaction.claim.pending` means Boltz paid the invoice and
          // is queuing the batched on-chain claim — also needs verification.
          if (status == 'invoice.paid' ||
              status == 'transaction.claimed' ||
              status == 'transaction.claim.pending') {
            logger.i('Boltz reports ${data.boltzId} completed ($status)');
            return await _verifyAndComplete(data, status);
          }

          // Swap was created but we never locked funds — safe to abandon
          if (data.lockTxHash == null &&
              (status == 'swap.expired' || status == 'swap.created')) {
            logger.i('Swap ${data.boltzId} never funded, safe to abandon');
            return SwapOutFailed(
              'Swap abandoned — funds were never locked.',
              data: data.copyWith(lastBoltzStatus: status),
            );
          }

          // Boltz failed to pay — need to refund
          if (status == 'invoice.failedToPay' ||
              status == 'transaction.lockupFailed' ||
              status == 'swap.expired') {
            logger.w('Boltz reported $status for ${data.boltzId} — refunding');
            return await _attemptRefund(data.copyWith(lastBoltzStatus: status));
          }

          // Swap still in progress — subscribe to WebSocket for live updates
          if (status == 'invoice.pending' ||
              status == 'transaction.mempool' ||
              status == 'transaction.confirmed') {
            logger.d('Swap ${data.boltzId} in progress ($status) — waiting');
            return await _waitForTerminalStatus(data);
          }

          logger.d('Swap ${data.boltzId} in status $status — no action taken');
        } catch (e) {
          logger.w('Could not check Boltz status for ${data.boltzId}: $e');
        }

        // ── 3c. Fall back to WebSocket wait (fresh execute path) ──
        return await _waitForTerminalStatus(data);
      });

  /// Subscribes to the Boltz WebSocket and waits for a terminal status,
  /// then either completes the swap or triggers a refund.
  ///
  /// When the WS reports `invoice.paid` or `transaction.claimed`, we
  /// cross-verify against the Boltz HTTP API before accepting it. This
  /// prevents a spoofed or replayed WS event from tricking us into
  /// marking the swap as complete when Boltz hasn't actually paid.
  Future<SwapOutState> _waitForTerminalStatus(SwapOutData data) =>
      logger.span('_waitForTerminalStatus', () async {
        final statusStream = _waitForSwapOnChain(data.boltzId);

        final terminalStatus = await statusStream
            .where(
              (s) =>
                  s.status == 'invoice.paid' ||
                  s.status == 'transaction.claimed' ||
                  s.status == 'transaction.claim.pending' ||
                  s.status == 'invoice.failedToPay' ||
                  s.status == 'transaction.lockupFailed' ||
                  s.status == 'swap.expired',
            )
            .timeout(
              const Duration(minutes: 60),
              onTimeout: (sink) {
                sink.addError(
                  TimeoutException(
                    'Timed out waiting for Boltz to pay invoice for swap '
                    '${data.boltzId}. Funds are locked in swap contract. '
                    'A refund can be attempted after block '
                    '${data.timeoutBlockHeight}.',
                  ),
                );
              },
            )
            .first;

        if (terminalStatus.status == 'invoice.paid' ||
            terminalStatus.status == 'transaction.claimed' ||
            terminalStatus.status == 'transaction.claim.pending') {
          // ── Cross-verify against HTTP API ──
          // The WS event could be spoofed or replayed. Confirm via the
          // canonical Boltz HTTP endpoint before trusting it.
          return await _verifyAndComplete(data, terminalStatus.status);
        }

        // ── FAILURE: attempt refund ──
        logger.w(
          'Swap-out failed with status: ${terminalStatus.status}. '
          'Will attempt refund.',
        );
        return await _attemptRefund(
          data.copyWith(
            lastBoltzStatus: terminalStatus.status,
            errorMessage:
                'Boltz reported ${terminalStatus.status}. Refund required.',
          ),
        );
      });

  /// Fetches the preimage from Boltz and verifies that
  /// `SHA-256(preimage) == data.invoicePreimageHashHex`.
  ///
  /// This is cryptographic proof that the Lightning invoice was actually
  /// settled — only the payer (or a node along the payment route) can
  /// reveal a preimage whose hash matches the invoice's payment_hash.
  ///
  /// If Boltz cannot provide a valid preimage, we refuse to mark the
  /// swap as complete and fall back to waiting.
  Future<SwapOutState> _verifyAndComplete(
    SwapOutData data,
    String reportedStatus,
  ) => logger.span('_verifyAndComplete', () async {
    logger.i(
      'Status "$reportedStatus" for ${data.boltzId} — '
      'fetching preimage for verification',
    );

    try {
      final preimageHex = await chain.swaps!.boltzClient.getSubmarinePreimage(
        id: data.boltzId,
      );

      // Strip optional 0x prefix and decode.
      final normalized = preimageHex.startsWith('0x')
          ? preimageHex.substring(2)
          : preimageHex;
      final preimageBytes = hex.decode(normalized);

      // SHA-256(preimage) must equal the payment_hash from the invoice.
      final computedHash = sha256.convert(preimageBytes).toString();
      final expectedHash = data.invoicePreimageHashHex.toLowerCase();

      if (computedHash == expectedHash) {
        logger.i(
          'Preimage verified for ${data.boltzId}: '
          'SHA-256($normalized) == $expectedHash ✓',
        );
        return SwapOutCompleted(data.copyWith(lastBoltzStatus: reportedStatus));
      }

      // Hash mismatch — Boltz provided an invalid preimage.
      logger.e(
        'Preimage verification FAILED for ${data.boltzId}: '
        'SHA-256($normalized) = $computedHash, '
        'expected $expectedHash. Refusing to mark as complete.',
      );
      return await _waitForTerminalStatus(data);
    } catch (e) {
      // Preimage not yet available (Boltz may not have revealed it yet)
      // or network error. Fall back to waiting for the next status update.
      logger.w(
        'Could not fetch/verify preimage for ${data.boltzId}: $e — '
        'continuing to wait',
      );
      return await _waitForTerminalStatus(data);
    }
  });

  // ── Step 4: Confirm refund receipt ────────────────────────────────────

  Future<SwapOutState> _stepConfirmRefund() =>
      logger.span('_stepConfirmRefund', () async {
        final data = state.data!;
        if (data.resolutionTxHash == null) {
          // Shouldn't happen, but re-attempt refund
          return await _attemptRefund(data);
        }
        final receipt = await chain.awaitReceipt(data.resolutionTxHash!);
        logger.i('Refund receipt for ${data.boltzId}: $receipt');
        logger.i('Swap-out refunded: ${data.resolutionTxHash}');
        return SwapOutRefunded(data);
      });

  // ── Refund logic ──────────────────────────────────────────────────────

  /// Attempt to refund locked funds from the swap contract.
  ///
  /// Tries cooperative refund first (via EIP-712 signature from Boltz, available
  /// immediately when swap is in a failed state). Falls back to timelock refund
  /// if cooperative refund isn't available.
  Future<SwapOutState> _attemptRefund(
    SwapOutData data,
  ) => logger.span('_attemptRefund', () async {
    final claimAddress = EthereumAddress.fromHex(data.claimAddress);
    final isErc20 = data.tokenAddress != null;
    final tokenAddr = isErc20
        ? EthereumAddress.fromHex(data.tokenAddress!)
        : null;
    final intents = BoltzCallBuilder(chain.swaps!);

    // 1. Try cooperative refund (immediate, doesn't need timelock expiry)
    try {
      final boltz = chain.swaps!.boltzClient;
      final sigResponse = await boltz.getCooperativeRefundSignature(
        id: data.boltzId,
      );

      if (sigResponse != null) {
        logger.i('Got cooperative refund signature from Boltz');
        final sig = parseEvmSignature(sigResponse.signature);

        final intent = intents.cooperativeRefund(
          preimageHash: data.invoicePreimageHashBytes,
          amountWei: data.lockedAmountWei,
          claimAddress: claimAddress,
          timeoutBlockHeight: data.timeoutBlockHeight,
          sig: sig,
          tokenAddress: tokenAddr,
        );

        final refundTx = await chain.sendCalls(params.evmKey, {
          'cooperativeRefund': intent,
        });

        logger.i('Cooperative refund broadcast: $refundTx');
        return SwapOutRefunding(data.copyWith(resolutionTxHash: refundTx));
      }
    } catch (e) {
      logger.w('Cooperative refund failed: $e — will fall back to timelock');
    }

    // 2. Fall back to timelock refund (must wait for block height)
    try {
      final currentBlock = await chain.getLocktimeBlockNumber();
      if (currentBlock < data.timeoutBlockHeight) {
        logger.w(
          'Timelock not expired yet (current: $currentBlock, '
          'timelock: ${data.timeoutBlockHeight}). '
          'Refund will be retried by SwapRecoverer.',
        );
        return SwapOutFunded(
          data.copyWith(
            errorMessage:
                'Waiting for timelock expiry at block '
                '${data.timeoutBlockHeight} (current: $currentBlock)',
          ),
        );
      }

      final intent = intents.refund(
        preimageHash: data.invoicePreimageHashBytes,
        amountWei: data.lockedAmountWei,
        claimAddress: claimAddress,
        timeoutBlockHeight: data.timeoutBlockHeight,
        tokenAddress: tokenAddr,
      );

      final refundTx = await chain.sendCalls(params.evmKey, {'refund': intent});

      logger.i('Timelock refund broadcast: $refundTx');
      return SwapOutRefunding(data.copyWith(resolutionTxHash: refundTx));
    } catch (e) {
      logger.e('Timelock refund failed: $e');
      return SwapOutFunded(data.copyWith(errorMessage: 'Refund failed: $e'));
    }
  });

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Obtains a Lightning invoice for the swap-out.
  ///
  /// Tries NWC / LUD-16 first; if unavailable, asks the user to provide
  /// one manually via [SwapOutExternalInvoiceRequired].
  Future<String> _acquireInvoice(SwapOutQuote quote) =>
      logger.span('_acquireInvoice', () async {
        final invoice = await payments.getMyInvoice(
          quote.invoiceAmount.getInSats.toInt(),
          description: 'Hostr payout',
        );
        if (invoice != null) return invoice;

        emit(SwapOutExternalInvoiceRequired(quote.invoiceAmount));
        logger.i(
          'No NWC or LUD16 available, emitted SwapOutExternalInvoiceRequired '
          'with amount ${quote.invoiceAmount.getInSats} sats',
        );
        externalInvoiceCompleter = Completer<String>();
        return externalInvoiceCompleter!.future;
      });

  /// Decodes a BOLT-11 invoice and returns the 32-byte preimage hash.
  Uint8List _extractPreimageHash(String invoice) {
    final tag = Bolt11PaymentRequest(
      invoice,
    ).tags.where((t) => t.type == 'payment_hash').first.data;
    return _decodePaymentHash(tag);
  }

  /// Creates the Boltz submarine swap, validates that the on-chain balance
  /// covers the lock amount plus gas, and builds the [SwapOutData] recovery
  /// record.
  Future<SwapOutState> _prepareSwap(
    String invoice,
    SwapOutQuote quote,
    int creationBlock,
  ) => logger.span('_prepareSwap', () async {
    final preimageHash = _extractPreimageHash(invoice);
    final swap = await chain.swaps!.submarine(
      invoice: invoice,
      tokenAddress: _requestedTokenAddress,
    );
    logger.i('Submarine swap created: ${swap.toString()}');

    final gasFee = TokenAmount.fromDenominated(
      quote.estimatedGasFee,
      Token.native(chain.config.chainId),
    );
    final funding = SwapFundingRequirement.fromBoltzExpectedAmount(
      expectedAmountSat: swap.expectedAmount.ceil(),
      fundingToken: quote.balance.token,
      balance: quote.balance,
      gasFee: gasFee,
    );
    funding.validate();

    final lockClaimAddress = _resolveSubmarineClaimAddress(swap);

    final data = SwapOutData(
      boltzId: swap.id,
      invoice: invoice,
      invoicePreimageHashHex: hex.encode(preimageHash),
      claimAddress: lockClaimAddress.with0x,
      lockedAmountWeiHex: funding.lockAmountWei.toRadixString(16),
      lockerAddress: params.evmKey.address.with0x,
      timeoutBlockHeight: swap.timeoutBlockHeight!.toInt(),
      chainId: chain.config.chainId,
      accountIndex: params.accountIndex,
      creationBlockHeight: creationBlock,
      tokenAddress: _requestedTokenAddress?.eip55With0x,
      preLockCalls: params.preLockCalls,
    );
    logger.i('Swap-out data persisted for ${swap.id} before lock');
    return SwapOutAwaitingOnChain(data);
  });

  Future<SwapOutQuote> _buildQuote() =>
      quoteService.buildQuote(chain: chain, params: params);

  Uint8List _decodePaymentHash(String paymentHash) {
    final normalized = paymentHash.startsWith('0x')
        ? paymentHash.substring(2)
        : paymentHash;

    if (normalized.length != 64) {
      throw StateError(
        'Expected payment_hash to be 32 bytes (64 hex chars), got ${normalized.length} chars: $paymentHash',
      );
    }

    return Uint8List.fromList(hex.decode(normalized));
  }

  EthereumAddress _resolveSubmarineClaimAddress(SubmarineResponse swap) {
    final raw = swap.claimPublicKey;
    if (raw == null || raw.isEmpty) {
      throw StateError(
        'Boltz submarine response did not include a claim address. '
        'Received: ${swap.toString()}',
      );
    }

    try {
      return EthereumAddress.fromHex(raw);
    } catch (_) {
      throw StateError(
        'Invalid submarine claim address format: $raw. Response: ${swap.toString()}',
      );
    }
  }

  Stream<SwapStatus> _waitForSwapOnChain(String id) {
    return chain.swaps!.boltzClient.subscribeToSwap(id: id).doOnData((
      swapStatus,
    ) {
      logger.i('Swap status update: ${swapStatus.status}, $swapStatus');
    });
  }
}
