import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:hostr_sdk/datasources/swagger_generated/boltz.swagger.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/payments.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' hide params;

import '../../../../../../datasources/boltz/boltz.dart';
import '../../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../../util/main.dart';
import '../../../../../payments/operations/pay_operation.dart';
import '../../../../../payments/operations/pay_state.dart';
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
      rootstock.getSwapInLimits();

  // ── State machine ─────────────────────────────────────────────────────

  @override
  Future<void> handle() async {
    try {
      switch (state) {
        case SwapInInitialised():
          await _stepCreateSwap();
        case SwapInRequestCreated() ||
            SwapInAwaitingOnChain() ||
            SwapInPaymentProgress():
          await _stepEnsureFunded();
        case SwapInFunded():
          await _stepClaim();
        case SwapInClaimed():
          await _stepCheckClaimInMempool();
        case SwapInClaimTxInMempool():
          await _stepConfirmClaim();
        case SwapInCompleted() || SwapInFailed():
          return; // terminal — nothing to do
      }
    } on TimeoutException catch (e, st) {
      logger.e('Timeout during swap-in: $e');
      emit(SwapInFailed(e, data: state.data, stackTrace: st));
    } catch (e, st) {
      logger.e('Error during swap-in handle (${state.runtimeType}): $e');
      emit(SwapInFailed(e, data: state.data, stackTrace: st));
    }
  }

  // ── Step 1: Create the Boltz reverse-submarine swap ───────────────────

  Future<void> _stepCreateSwap() async {
    final preimage = _newPreimage();
    logger.i('Preimage: ${preimage.hash}, ${preimage.preimage.length}');

    final creationBlock = await rootstock.client.getBlockNumber();

    /// Create a reverse submarine swap
    final swap = await _generateSwapRequest(preimage);

    // ── Persist recovery data immediately after swap creation ──
    // The preimage is the single most critical piece of data.
    // Without it, any on-chain funds locked by Boltz are UNRECOVERABLE.
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
    );
    emit(SwapInRequestCreated(data));
    logger.i('Swap data persisted for ${swap.id} with preimage');
    logger.d('Swap ${swap.toString()}');
  }

  // ── Step 2: Ensure Boltz locked on-chain (chain-first) ───────────────

  Future<void> _stepEnsureFunded() async {
    final data = state.data!;

    // ── 2a. Check chain for existing lockup (idempotent recovery) ──
    final lockup = await _findLockupOnChain(data);
    if (lockup != null) {
      logger.i(
        'Found lockup on-chain for ${data.boltzId}: '
        'amount=${lockup.amount}, refund=${lockup.refundAddress}',
      );
      emit(
        SwapInFunded(
          data.copyWith(
            lockupTxHash: lockup.event.transactionHash,
            refundAddress: lockup.refundAddress.with0x,
          ),
        ),
      );
      return;
    }

    // ── 2b. Check if already claimed on-chain ──
    final claim = await _findClaimOnChain(data);
    if (claim != null) {
      logger.i('Swap ${data.boltzId} already claimed on-chain');
      emit(
        SwapInCompleted(
          data.copyWith(claimTxHash: claim.event.transactionHash),
        ),
      );
      return;
    }

    // ── 2c. Check if expired ──
    final currentBlock = await rootstock.client.getBlockNumber();
    if (currentBlock >= data.timeoutBlockHeight) {
      logger.w(
        'Swap ${data.boltzId} expired (block $currentBlock >= ${data.timeoutBlockHeight})',
      );
      emit(
        SwapInFailed(
          'Swap expired. No on-chain funds at risk — Lightning payment '
          'refunds automatically via HTLC expiry.',
          data: data,
        ),
      );
      return;
    }

    // ── 2d. Check Boltz status for terminal conditions ──
    try {
      final boltzStatus = await getIt<BoltzClient>().getSwap(id: data.boltzId);
      final status = boltzStatus.status;

      if (status == 'transaction.refunded') {
        emit(
          SwapInFailed(
            'Boltz refunded the on-chain lockup. The claim window expired.',
            data: data.copyWith(lastBoltzStatus: status),
          ),
        );
        return;
      }

      if (status == 'invoice.settled') {
        logger.i('Boltz reports ${data.boltzId} already settled');
        emit(SwapInCompleted(data.copyWith(lastBoltzStatus: status)));
        return;
      }

      if (status == 'swap.expired' || status == 'transaction.failed') {
        emit(
          SwapInFailed(
            'Swap expired or failed before lockup. No on-chain funds at risk.',
            data: data.copyWith(lastBoltzStatus: status),
          ),
        );
        return;
      }

      // If Boltz says lockup is already in mempool/confirmed, wait for chain.
      if (status == 'transaction.mempool' ||
          status == 'transaction.confirmed') {
        final txHash = boltzStatus.transaction?.id;
        if (txHash != null) {
          logger.i(
            'Boltz reports lockup tx $txHash — awaiting chain confirmation',
          );
          final lockupTx = await rootstock.awaitTransaction(txHash);
          emit(
            SwapInFunded(
              data.copyWith(
                lockupTxHash: txHash,
                refundAddress: lockupTx.from.with0x,
                lastBoltzStatus: status,
              ),
            ),
          );
          return;
        }
      }
    } catch (e) {
      logger.w('Could not check Boltz status for ${data.boltzId}: $e');
      // Non-fatal — fall through to the payment + WebSocket flow.
    }

    // ── 2e. No lockup yet — attempt the payment flow (execute path) ──
    await _payAndWaitForLockup(data);
  }

  /// Pays the Lightning invoice and waits for the on-chain lockup via the
  /// Boltz WebSocket. Only reached during the initial execute flow (not
  /// recovery — recovery finds the lockup via chain or Boltz HTTP above).
  Future<void> _payAndWaitForLockup(SwapInData data) async {
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

    // Subscribe to Boltz status updates with timeout
    final swapStatusFuture = _waitForSwapOnChain(data.boltzId);
    emit(SwapInAwaitingOnChain(data));

    // Subscribe to payment stream BEFORE executing so we never miss
    // states on the broadcast stream.
    final paymentCompleter = Completer<void>();
    final paySub = payment.stream
        .where((s) => s is PayFailed || s is PayExternalRequired)
        .takeUntil(swapStatusFuture.asStream())
        .listen(
          (paymentState) {
            logger.e('Payment emitted with state: $paymentState');
            emit(SwapInPaymentProgress(data, paymentState: paymentState));
          },
          onDone: () {
            if (!paymentCompleter.isCompleted) paymentCompleter.complete();
          },
        );

    // NOW execute the payment — the listener above is already active
    payment.execute();

    // Wait until the payment stream completes
    await paymentCompleter.future;
    await paySub.cancel();

    // Wait for Boltz's lockup transaction with a generous timeout
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

    // ── Persist lockup tx hash immediately ──
    final lockupTx = await rootstock.awaitTransaction(lockupTxId);
    emit(
      SwapInFunded(
        data.copyWith(
          lockupTxHash: lockupTxId,
          refundAddress: lockupTx.from.with0x,
          lastBoltzStatus: swapStatus.status,
        ),
      ),
    );
  }

  // ── Step 3: Claim the locked funds ────────────────────────────────────

  Future<void> _stepClaim() async {
    final data = state.data!;

    // ── 3a. Check if already claimed on-chain (idempotent) ──
    final existingClaim = await _findClaimOnChain(data);
    if (existingClaim != null) {
      logger.i('Swap ${data.boltzId} already claimed on-chain');
      emit(
        SwapInClaimed(
          data.copyWith(claimTxHash: existingClaim.event.transactionHash),
        ),
      );
      return;
    }

    // ── 3b. Resolve refund address if missing ──
    var claimData = data;
    if (claimData.refundAddress == null && claimData.lockupTxHash != null) {
      final lockupTx = await rootstock.awaitTransaction(
        claimData.lockupTxHash!,
      );
      claimData = claimData.copyWith(refundAddress: lockupTx.from.with0x);
      emit(SwapInFunded(claimData)); // persist before claim attempt
    }

    if (claimData.refundAddress == null) {
      throw StateError(
        'Cannot claim swap ${claimData.boltzId}: missing refundAddress and lockupTxHash',
      );
    }

    // ── 3c. Perform the claim via RIF Relay ──
    final claimArgs = _claimArgsFromData(claimData);
    logger.i('Claiming swap ${claimData.boltzId} with args: $claimArgs');

    final tx = await _claim(claimArgs: claimArgs);
    emit(SwapInClaimed(claimData.copyWith(claimTxHash: tx)));
    logger.i('Claim broadcast for ${claimData.boltzId}: $tx');
  }

  // ── Step 4: Wait for claim tx to appear in mempool (visual only) ────

  Future<void> _stepCheckClaimInMempool() async {
    final data = state.data!;
    await rootstock.awaitTransaction(data.claimTxHash!);
    logger.i('Claim tx ${data.claimTxHash} visible in mempool');
    emit(SwapInClaimTxInMempool(data));
  }

  // ── Step 5: Confirm the claim receipt ─────────────────────────────────

  Future<void> _stepConfirmClaim() async {
    final data = state.data!;
    final receipt = await rootstock.awaitReceipt(data.claimTxHash!);
    logger.i('Claim receipt for ${data.boltzId}: $receipt');
    emit(SwapInCompleted(data));
    logger.i('Swap-in completed: ${data.claimTxHash}');
  }

  // ── Fee estimation ────────────────────────────────────────────────────

  @override
  Future<SwapInFees> estimateFees() async {
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
  }

  // ── On-chain event queries ────────────────────────────────────────────

  /// Scans the chain for a Lockup event matching [data.preimageHash].
  Future<Lockup?> _findLockupOnChain(SwapInData data) async {
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
  }

  /// Scans the chain for a Claim event matching [data.preimageHash].
  Future<Claim?> _findClaimOnChain(SwapInData data) async {
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
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<ReverseResponse> _generateSwapRequest(
    ({List<int> preimage, String hash}) preimage,
  ) async {
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
  }

  /// Creates a payment cubit for the swap invoice but does NOT execute it.
  /// The caller MUST subscribe to the returned cubit's stream BEFORE calling
  /// [PayOperation.execute] to avoid losing states on the broadcast stream.
  PayOperation _createPaymentForSwap({
    required String invoice,
    required BitcoinAmount amount,
    required String preimageHash,
  }) {
    Bolt11PaymentRequest pr = Bolt11PaymentRequest(invoice);
    final invoiceAmount = BitcoinAmount.fromDecimal(
      BitcoinUnit.bitcoin,
      pr.amount.toString(),
    );
    logger.i(
      'Invoice to pay: ${invoiceAmount.getInSats} against ${amount.getInSats} planned, hash: ${pr.tags.firstWhere((t) => t.type == 'payment_hash').data} against planned $preimageHash',
    );

    /// Before paying, check that the invoice swapper generated is for the correct amount
    assert(invoiceAmount == amount);

    /// Before paying, check that the invoice hash is equivalent to the preimage hash we generated
    /// Ensures we know the invoice can't be settled until we reveal it in the claim txn
    assert(
      pr.tags.firstWhere((t) => t.type == 'payment_hash').data == preimageHash,
    );

    return getIt<Payments>().pay(
      Bolt11PayParameters(amount: amount, to: invoice),
    );
  }

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

  Future<String> _claim({required ClaimArgs claimArgs}) async {
    EtherSwap etherSwap = await rootstock.getEtherSwapContract();
    return (await rifRelay.relayClaim(
      etherSwap,
      params.evmKey,
      claimArgs,
    )).txHash.toString();
  }

  /// Generate a cryptographically secure 32-byte preimage and its SHA-256 hash.
  ({List<int> preimage, String hash}) _newPreimage() {
    final random = Random.secure();
    final preimage = List<int>.generate(32, (i) => random.nextInt(256));
    final hash = sha256.convert(preimage).toString();
    return (preimage: preimage, hash: hash);
  }

  Future<SwapStatus> _waitForSwapOnChain(String id) {
    return getIt<BoltzClient>()
        .subscribeToSwap(id: id)
        .doOnData((swapStatus) {
          logger.i('Swap status update: ${swapStatus.status}, $swapStatus');
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
  }

  // ── Manual event decoders (ABI-version-agnostic) ──────────────────────

  /// Decodes a Lockup event from raw log data when [decodeResults] fails
  /// (e.g. deployed contract indexes fewer params than the generated ABI).
  Lockup _decodeLockupManually(FilterEvent log, Uint8List preimageHash) {
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
  }

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
