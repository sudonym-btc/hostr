import 'dart:async';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' hide params;

import '../../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../../../../datasources/swagger_generated/boltz.swagger.dart';
import '../../../../../../util/main.dart';
import '../../../../../nwc/nwc.dart';
import '../../../../../payments/payments.dart';
import '../../../../main.dart';

class EvmSwapOutOperation extends SwapOutOperation {
  final ConfiguredEvmChain configuredChain;
  final Nwc nwc;
  final SwapOutQuoteService quoteService;
  final Payments payments;

  EthereumAddress? get _requestedTokenAddress {
    final amount = params.amount;
    if (amount == null || !amount.token.isERC20) return null;
    return EthereumAddress.fromHex(amount.token.address);
  }

  EvmSwapOutOperation({
    required this.configuredChain,
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

  Future<SwapOutState> _stepCreateSwap() => logger.span(
    '_stepCreateSwap',
    () async {
      emit(SwapOutRequestCreated());

      final quote = await _buildQuote();
      final invoice = await _acquireInvoice(quote);
      emit(SwapOutInvoiceCreated(invoice));
      logger.i('Invoice created: $invoice');

      final creationBlock = await configuredChain.chain.client.getBlockNumber();
      return await _prepareSwap(invoice, quote, creationBlock);
    },
  );

  // ── Step 2: Lock funds in swap contract ───────────────────────────────

  Future<SwapOutState> _stepLockFunds() =>
      logger.span('_stepLockFunds', () async {
        final data = state.data!;

        // ── 2a. Check if already locked on-chain (idempotent recovery) ──
        if (data.lockTxHash != null) {
          // Already locked — fast-forward to Funded
          return SwapOutFunded(data);
        }

        final isErc20 = data.tokenAddress != null;
        final String tx;

        if (isErc20) {
          final erc20Swap = configuredChain.swaps!.getERC20SwapContract();
          final tokenAddr = EthereumAddress.fromHex(data.tokenAddress!);

          // Build ERC-20 approve intent
          final token = IERC20(
            address: tokenAddr,
            client: configuredChain.chain.client,
          );
          final approveFn = token.self.abi.functions.firstWhere(
            (f) => f.name == 'approve',
          );
          final approveIntent = CallIntent(
            to: tokenAddr,
            data: approveFn.encodeCall([
              erc20Swap.self.address,
              data.lockedAmountWei,
            ]),
            value: EtherAmount.zero(),
            methodName: 'ERC20.approve',
          );

          // Build ERC20Swap.lock intent (5 params, zero native value)
          final lockFn = erc20Swap.self.abi.functions.firstWhere(
            (f) => f.name == 'lock' && f.parameters.length == 5,
          );
          final lockIntent = CallIntent(
            to: erc20Swap.self.address,
            data: lockFn.encodeCall([
              data.invoicePreimageHashBytes,
              data.lockedAmountWei,
              tokenAddr,
              EthereumAddress.fromHex(data.claimAddress),
              BigInt.from(data.timeoutBlockHeight),
            ]),
            value: EtherAmount.zero(),
            methodName: 'ERC20Swap.lock',
          );

          // Send both as a single batched UserOperation
          tx = await configuredChain.aa!.sendUserOp(params.evmKey, [
            approveIntent,
            lockIntent,
          ]);
          logger.i('Locked funds in ERC20Swap (approve + lock): $tx');
        } else {
          final swapContract = configuredChain.swaps!.getEtherSwapContract();
          final lockFn = swapContract.self.abi.functions.firstWhere(
            (f) => f.name == 'lock' && f.parameters.length == 3,
          );
          final intent = CallIntent(
            to: swapContract.self.address,
            data: lockFn.encodeCall([
              data.invoicePreimageHashBytes,
              EthereumAddress.fromHex(data.claimAddress),
              BigInt.from(data.timeoutBlockHeight),
            ]),
            value: EtherAmount.inWei(data.lockedAmountWei),
            methodName: 'EtherSwap.lock',
          );
          tx = await configuredChain.aa!.sendUserOp(params.evmKey, [intent]);
          logger.i('Locked funds in EtherSwap: $tx');
        }

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
        final boltzResponse = await configuredChain.swaps!.boltzClient.getSwap(
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
        final receipt = await configuredChain.chain.awaitReceipt(
          data.resolutionTxHash!,
        );
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

    // Select the correct swap contract
    final swapContractSelf = isErc20
        ? configuredChain.swaps!.getERC20SwapContract().self
        : configuredChain.swaps!.getEtherSwapContract().self;

    // 1. Try cooperative refund (immediate, doesn't need timelock expiry)
    try {
      final boltz = configuredChain.swaps!.boltzClient;
      final sigResponse = await boltz.getCooperativeRefundSignature(
        id: data.boltzId,
      );

      if (sigResponse != null) {
        logger.i('Got cooperative refund signature from Boltz');
        final sig = parseEvmSignature(sigResponse.signature);

        final CallIntent intent;
        if (isErc20) {
          final coopRefundFn = swapContractSelf.abi.functions.firstWhere(
            (f) => f.name == 'refundCooperative' && f.parameters.length == 8,
          );
          intent = CallIntent(
            to: swapContractSelf.address,
            data: coopRefundFn.encodeCall([
              data.invoicePreimageHashBytes,
              data.lockedAmountWei,
              tokenAddr!,
              claimAddress,
              BigInt.from(data.timeoutBlockHeight),
              sig.v,
              sig.r,
              sig.s,
            ]),
            value: EtherAmount.zero(),
            methodName: 'ERC20Swap.refundCooperative',
          );
        } else {
          final coopRefundFn = swapContractSelf.abi.functions.firstWhere(
            (f) => f.name == 'refundCooperative' && f.parameters.length == 7,
          );
          intent = CallIntent(
            to: swapContractSelf.address,
            data: coopRefundFn.encodeCall([
              data.invoicePreimageHashBytes,
              data.lockedAmountWei,
              claimAddress,
              BigInt.from(data.timeoutBlockHeight),
              sig.v,
              sig.r,
              sig.s,
            ]),
            value: EtherAmount.zero(),
            methodName: 'EtherSwap.refundCooperative',
          );
        }

        final refundTx = await configuredChain.aa!.sendUserOp(params.evmKey, [
          intent,
        ]);

        logger.i('Cooperative refund broadcast: $refundTx');
        return SwapOutRefunding(data.copyWith(resolutionTxHash: refundTx));
      }
    } catch (e) {
      logger.w('Cooperative refund failed: $e — will fall back to timelock');
    }

    // 2. Fall back to timelock refund (must wait for block height)
    try {
      // Use getLocktimeBlockNumber() because on Arbitrum L2, Boltz returns
      // Ethereum L1 block numbers for timeouts while eth_blockNumber returns
      // the much-larger L2 sequencer block.
      final currentBlock = await configuredChain.chain.getLocktimeBlockNumber();
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

      final CallIntent intent;
      if (isErc20) {
        final refundFn = swapContractSelf.abi.functions.firstWhere(
          (f) => f.name == 'refund' && f.parameters.length == 5,
        );
        intent = CallIntent(
          to: swapContractSelf.address,
          data: refundFn.encodeCall([
            data.invoicePreimageHashBytes,
            data.lockedAmountWei,
            tokenAddr!,
            claimAddress,
            BigInt.from(data.timeoutBlockHeight),
          ]),
          value: EtherAmount.zero(),
          methodName: 'ERC20Swap.refund',
        );
      } else {
        final refundFn = swapContractSelf.abi.functions.firstWhere(
          (f) => f.name == 'refund' && f.parameters.length == 4,
        );
        intent = CallIntent(
          to: swapContractSelf.address,
          data: refundFn.encodeCall([
            data.invoicePreimageHashBytes,
            data.lockedAmountWei,
            claimAddress,
            BigInt.from(data.timeoutBlockHeight),
          ]),
          value: EtherAmount.zero(),
          methodName: 'EtherSwap.refund',
        );
      }

      final refundTx = await configuredChain.aa!.sendUserOp(params.evmKey, [
        intent,
      ]);

      logger.i('Timelock refund broadcast: $refundTx');
      return SwapOutRefunding(data.copyWith(resolutionTxHash: refundTx));
    } catch (e) {
      logger.e('Timelock refund failed: $e');
      return SwapOutFunded(data.copyWith(errorMessage: 'Refund failed: $e'));
    }
  });

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
        final isErc20 = data.tokenAddress != null;
        final contract = isErc20
            ? configuredChain.swaps!.getERC20SwapContract().self
            : configuredChain.swaps!.getEtherSwapContract().self;
        final fromBlock = data.creationBlockHeight != null
            ? BlockNum.exact(data.creationBlockHeight!)
            : const BlockNum.exact(0);

        final event = contract.event('Claim');
        final filter = FilterOptions.events(
          contract: contract,
          event: event,
          fromBlock: fromBlock,
          toBlock: const BlockNum.current(),
        );
        final logs = await configuredChain.chain.client.getLogs(filter);
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
        final isErc20 = data.tokenAddress != null;
        final contract = isErc20
            ? configuredChain.swaps!.getERC20SwapContract().self
            : configuredChain.swaps!.getEtherSwapContract().self;
        final fromBlock = data.creationBlockHeight != null
            ? BlockNum.exact(data.creationBlockHeight!)
            : const BlockNum.exact(0);

        final event = contract.event('Refund');
        final filter = FilterOptions.events(
          contract: contract,
          event: event,
          fromBlock: fromBlock,
          toBlock: const BlockNum.current(),
        );
        final logs = await configuredChain.chain.client.getLogs(filter);
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
    final swap = await configuredChain.swaps!.submarine(
      invoice: invoice,
      tokenAddress: _requestedTokenAddress,
    );
    logger.i('Submarine swap created: ${swap.toString()}');

    final expectedLockAmount = rbtcFromSatsInt(swap.expectedAmount.ceil());
    final expectedLockAmountRounded = expectedLockAmount.roundUpToSats();
    final gasFeeRounded = TokenAmount.fromDenominated(
      quote.estimatedGasFee,
      quote.balance.token,
    ).roundUpToSats();
    final balanceRounded = quote.balance.roundDownToSats();

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
      timeoutBlockHeight: swap.timeoutBlockHeight!.toInt(),
      chainId: configuredChain.config.chainId,
      accountIndex: params.accountIndex,
      creationBlockHeight: creationBlock,
      tokenAddress: _requestedTokenAddress?.eip55With0x,
    );
    logger.i('Swap-out data persisted for ${swap.id} before lock');
    return SwapOutAwaitingOnChain(data);
  });

  Future<SwapOutQuote> _buildQuote() => logger.span('_buildQuote', () async {
    final balance = await _getSwapBalance();
    return quoteService.buildQuote(
      balance: balance,
      estimatedGasFee: await _estimateLockGasFee(),
      requestedAmount: params.amount,
      boltzCurrency: configuredChain.swaps!.currencyForTokenAddress(
        _requestedTokenAddress,
      ),
    );
  });

  Future<TokenAmount> _getSwapBalance() =>
      logger.span('_getSwapBalance', () async {
        final tokenAddress = _requestedTokenAddress;
        if (tokenAddress == null) {
          return configuredChain.chain.getBalance(params.evmKey.address);
        }

        final token = IERC20(
          address: tokenAddress,
          client: configuredChain.chain.client,
        );
        final raw = await token.balanceOf((account: params.evmKey.address));
        return tokenAmountFromEvm(
          tokenAddress.eip55With0x,
          raw,
          chainId: configuredChain.config.chainId,
          knownTokens: configuredChain.config.tokens,
        );
      });

  Future<TokenAmount> _estimateLockGasFee() =>
      logger.span('_estimateLockGasFee', () async {
        final feeWei = await configuredChain.aa!.estimateGasFee(params.evmKey);
        return rbtcFromWei(feeWei);
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
    return configuredChain.swaps!.boltzClient.subscribeToSwap(id: id).doOnData((
      swapStatus,
    ) {
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
