import 'dart:async';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' hide params;

import '../../../../../../datasources/boltz/boltz.dart';
import '../../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../../datasources/swagger_generated/boltz.swagger.dart';
import '../../../../../../injection.dart';
import '../../../../../../util/main.dart';
import '../../../../../nwc/nwc.dart';
import '../../../../../payments/payments.dart';
import '../../../../main.dart';
import '../../rif_relay/rif_relay.dart';

@injectable
class RootstockSwapOutOperation extends SwapOutOperation {
  static const int _estimatedLockGasLimit = 200000;

  final Rootstock rootstock;
  final Nwc nwc;
  final SwapOutQuoteService quoteService;
  final Payments payments;
  late final RifRelay rifRelay = getIt<RifRelay>(
    param1: rootstock.client,
    param2: rootstock.config.rootstockConfig.rifRelay,
  );

  RootstockSwapOutOperation({
    required this.rootstock,
    required super.auth,
    required super.logger,
    required this.nwc,
    required this.quoteService,
    required this.payments,
    @factoryParam required super.params,
    @ignoreParam super.initialState,
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

        final creationBlock = await rootstock.client.getBlockNumber();
        return await _prepareSwap(invoice, quote, creationBlock);
      });

  // ── Step 2: Lock funds in EtherSwap ───────────────────────────────────

  Future<SwapOutState> _stepLockFunds() =>
      logger.span('_stepLockFunds', () async {
        final data = state.data!;

        // ── 2a. Check if already locked on-chain (idempotent recovery) ──
        if (data.lockTxHash != null) {
          // Already locked — fast-forward to Funded
          return SwapOutFunded(data);
        }

        final swapContract = await rootstock.getEtherSwapContract();
        final tx = await swapContract.lock(
          (
            claimAddress: EthereumAddress.fromHex(data.claimAddress),
            preimageHash: data.invoicePreimageHashBytes,
            timelock: BigInt.from(data.timeoutBlockHeight),
          ),
          credentials: params.evmKey,
          transaction: Transaction(
            value: EtherAmount.inWei(data.lockedAmountWei),
          ),
        );

        logger.i('Locked funds in EtherSwap: $tx');
        return SwapOutFunded(
          data.copyWith(lockTxHash: tx, lastBoltzStatus: 'lock.broadcast'),
        );
      });

  // ── Step 3: Await Boltz payment or trigger refund ─────────────────────

  Future<SwapOutState> _stepAwaitResolution() => logger.span(
    '_stepAwaitResolution',
    () async {
      final data = state.data!;

      // ── 3a. Check chain for claim event (Boltz claimed = success) ──
      final claimEvent = await _findClaimOnChain(data);
      if (claimEvent != null) {
        logger.i('Found claim on-chain for ${data.boltzId} — swap succeeded');
        return SwapOutCompleted(data.copyWith(lastBoltzStatus: 'invoice.paid'));
      }

      // ── 3b. Check chain for existing refund event ──
      final refundEvent = await _findRefundOnChain(data);
      if (refundEvent != null) {
        logger.i('Found refund on-chain for ${data.boltzId}');
        return SwapOutRefunded(
          data.copyWith(resolutionTxHash: refundEvent.event.transactionHash),
        );
      }

      // ── 3c. Check Boltz HTTP status for terminal conditions ──
      try {
        final boltzResponse = await getIt<BoltzClient>().getSwap(
          id: data.boltzId,
        );
        final status = boltzResponse.status;

        // Boltz already paid the invoice — swap succeeded
        if (status == 'invoice.paid' || status == 'transaction.claimed') {
          logger.i('Boltz reports ${data.boltzId} completed ($status)');
          return SwapOutCompleted(data.copyWith(lastBoltzStatus: status));
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

      // ── 3d. Fall back to WebSocket wait (fresh execute path) ──
      return await _waitForTerminalStatus(data);
    },
  );

  /// Subscribes to the Boltz WebSocket and waits for a terminal status,
  /// then either completes the swap or triggers a refund.
  Future<SwapOutState> _waitForTerminalStatus(SwapOutData data) => logger.span(
    '_waitForTerminalStatus',
    () async {
      final statusStream = _waitForSwapOnChain(data.boltzId);

      final terminalStatus = await statusStream
          .where(
            (s) =>
                s.status == 'invoice.paid' ||
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
                  '${data.boltzId}. Funds are locked in EtherSwap contract. '
                  'A refund can be attempted after block '
                  '${data.timeoutBlockHeight}.',
                ),
              );
            },
          )
          .first;

      if (terminalStatus.status == 'invoice.paid') {
        logger.i('Swap-out completed: invoice paid by Boltz');
        return SwapOutCompleted(data.copyWith(lastBoltzStatus: 'invoice.paid'));
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
    },
  );

  // ── Step 4: Confirm refund receipt ────────────────────────────────────

  Future<SwapOutState> _stepConfirmRefund() =>
      logger.span('_stepConfirmRefund', () async {
        final data = state.data!;
        if (data.resolutionTxHash == null) {
          // Shouldn't happen, but re-attempt refund
          return await _attemptRefund(data);
        }
        final receipt = await rootstock.awaitReceipt(data.resolutionTxHash!);
        logger.i('Refund receipt for ${data.boltzId}: $receipt');
        logger.i('Swap-out refunded: ${data.resolutionTxHash}');
        return SwapOutRefunded(data);
      });

  // ── Refund logic ──────────────────────────────────────────────────────

  /// Attempt to refund locked funds from the EtherSwap contract.
  ///
  /// Tries cooperative refund first (via EIP-712 signature from Boltz, available
  /// immediately when swap is in a failed state). Falls back to timelock refund
  /// if cooperative refund isn't available.
  Future<SwapOutState> _attemptRefund(SwapOutData data) => logger.span(
    '_attemptRefund',
    () async {
      final claimAddress = EthereumAddress.fromHex(data.claimAddress);
      final swapContract = await rootstock.getEtherSwapContract();

      // 1. Try cooperative refund (immediate, doesn't need timelock expiry)
      try {
        final boltz = getIt<BoltzClient>();
        final sigResponse = await boltz.getCooperativeRefundSignature(
          id: data.boltzId,
        );

        if (sigResponse != null) {
          logger.i('Got cooperative refund signature from Boltz');
          final sig = parseEvmSignature(sigResponse.signature);

          final refundTx = await swapContract.refundCooperative$2((
            preimageHash: data.invoicePreimageHashBytes,
            amount: data.lockedAmountWei,
            claimAddress: claimAddress,
            timelock: BigInt.from(data.timeoutBlockHeight),
            v: sig.v,
            r: sig.r,
            s: sig.s,
          ), credentials: params.evmKey);

          logger.i('Cooperative refund broadcast: $refundTx');
          return SwapOutRefunding(data.copyWith(resolutionTxHash: refundTx));
        }
      } catch (e) {
        logger.w('Cooperative refund failed: $e — will fall back to timelock');
      }

      // 2. Fall back to timelock refund (must wait for block height)
      try {
        final currentBlock = await rootstock.client.getBlockNumber();
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

        final refundTx = await swapContract.refund((
          preimageHash: data.invoicePreimageHashBytes,
          amount: data.lockedAmountWei,
          claimAddress: claimAddress,
          timelock: BigInt.from(data.timeoutBlockHeight),
        ), credentials: params.evmKey);

        logger.i('Timelock refund broadcast: $refundTx');
        return SwapOutRefunding(data.copyWith(resolutionTxHash: refundTx));
      } catch (e) {
        logger.e('Timelock refund failed: $e');
        return SwapOutFunded(data.copyWith(errorMessage: 'Refund failed: $e'));
      }
    },
  );

  // ── Fee estimation ────────────────────────────────────────────────────

  @override
  Future<SwapOutFees> estimateFees() => logger.span('estimateFees', () async {
    final quote = await _buildQuote();
    return SwapOutFees(
      estimatedGasFees: quote.estimatedGasFee,
      estimatedSwapFees: quote.estimatedSwapFee,
      balance: quote.balance,
      invoiceAmount: quote.invoiceAmount,
    );
  });

  // ── On-chain event queries ────────────────────────────────────────────

  /// Scans the chain for a Claim event matching [data.invoicePreimageHashHex].
  Future<Claim?> _findClaimOnChain(SwapOutData data) => logger.span(
    '_findClaimOnChain',
    () async {
      try {
        final etherSwap = await rootstock.getEtherSwapContract();
        final fromBlock = data.creationBlockHeight != null
            ? BlockNum.exact(data.creationBlockHeight!)
            : const BlockNum.genesis();

        final event = etherSwap.self.event('Claim');
        final filter = FilterOptions.events(
          contract: etherSwap.self,
          event: event,
          fromBlock: fromBlock,
          toBlock: const BlockNum.current(),
        );
        final logs = await rootstock.client.getLogs(filter);
        for (final log in logs) {
          final decoded = event.decodeResults(log.topics!, log.data!);
          final claim = Claim(decoded, log);
          if (_bytesEqual(claim.preimageHash, data.invoicePreimageHashBytes)) {
            return claim;
          }
        }
        return null;
      } catch (e) {
        logger.w('Failed to query claim events: $e');
        return null;
      }
    },
  );

  /// Scans the chain for a Refund event matching [data.invoicePreimageHashHex].
  Future<Refund?> _findRefundOnChain(SwapOutData data) => logger.span(
    '_findRefundOnChain',
    () async {
      try {
        final etherSwap = await rootstock.getEtherSwapContract();
        final fromBlock = data.creationBlockHeight != null
            ? BlockNum.exact(data.creationBlockHeight!)
            : const BlockNum.genesis();

        final event = etherSwap.self.event('Refund');
        final filter = FilterOptions.events(
          contract: etherSwap.self,
          event: event,
          fromBlock: fromBlock,
          toBlock: const BlockNum.current(),
        );
        final logs = await rootstock.client.getLogs(filter);
        for (final log in logs) {
          final decoded = event.decodeResults(log.topics!, log.data!);
          final refund = Refund(decoded, log);
          if (_bytesEqual(refund.preimageHash, data.invoicePreimageHashBytes)) {
            return refund;
          }
        }
        return null;
      } catch (e) {
        logger.w('Failed to query refund events: $e');
        return null;
      }
    },
  );

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
    final swap = await getIt<BoltzClient>().submarine(invoice: invoice);
    logger.i('Submarine swap created: ${swap.toString()}');

    final expectedLockAmount = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      swap.expectedAmount.ceil(),
    );
    final expectedLockAmountRounded = expectedLockAmount.roundUp(
      BitcoinUnit.sat,
    );
    final gasFeeRounded = quote.estimatedGasFee.roundUp(BitcoinUnit.sat);
    final balanceRounded = quote.balance.roundDown(BitcoinUnit.sat);

    if (expectedLockAmountRounded + gasFeeRounded > balanceRounded) {
      final requiredTotal = expectedLockAmountRounded + gasFeeRounded;
      throw StateError(
        'Insufficient balance to lock swap. '
        'Need ${expectedLockAmountRounded.getInSats} sats + '
        '${gasFeeRounded.getInSats} sats gas, '
        'total of ${requiredTotal.getInSats} sats, '
        'have ${balanceRounded.getInSats} sats.',
      );
    }

    final lockClaimAddress = _resolveSubmarineClaimAddress(swap);

    final data = SwapOutData(
      boltzId: swap.id,
      invoice: invoice,
      invoicePreimageHashHex: hex.encode(preimageHash),
      claimAddress: lockClaimAddress.with0x,
      lockedAmountWeiHex: expectedLockAmountRounded.getInWei.toRadixString(16),
      lockerAddress: params.evmKey.address.with0x,
      timeoutBlockHeight: swap.timeoutBlockHeight.toInt(),
      chainId: rootstock.config.rootstockConfig.chainId,
      accountIndex: params.accountIndex,
      creationBlockHeight: creationBlock,
    );
    logger.i('Swap-out data persisted for ${swap.id} before lock');
    return SwapOutAwaitingOnChain(data);
  });

  Future<SwapOutQuote> _buildQuote() => logger.span('_buildQuote', () async {
    return quoteService.buildQuote(
      balance: await rootstock.getBalance(params.evmKey.address),
      estimatedGasFee: await _estimateLockGasFee(),
      requestedAmount: params.amount,
    );
  });

  Future<BitcoinAmount> _estimateLockGasFee() =>
      logger.span('_estimateLockGasFee', () async {
        final gasPrice = await rootstock.client.getGasPrice();
        final feeWei = gasPrice.getInWei * BigInt.from(_estimatedLockGasLimit);
        return BitcoinAmount.inWei(feeWei);
      });

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
    return getIt<BoltzClient>().subscribeToSwap(id: id).doOnData((swapStatus) {
      logger.i('Swap status update: ${swapStatus.status}, $swapStatus');
    });
  }

  /// Constant-time-safe byte array comparison.
  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
