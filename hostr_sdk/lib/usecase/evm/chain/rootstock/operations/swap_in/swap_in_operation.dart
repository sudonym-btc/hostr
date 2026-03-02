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
  late final ({List<int> preimage, String hash}) preimage;

  RootstockSwapInOperation({
    required this.rootstock,
    required super.auth,
    required super.logger,
    @factoryParam required super.params,
    super.initialState,
  }) {
    final recoveryData = state.data;
    if (recoveryData != null) {
      preimage = (
        preimage: recoveryData.preimageBytes.toList(),
        hash: recoveryData.preimageHash,
      );
    } else {
      preimage = _newPreimage();
    }
  }

  @override
  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapLimits() async {
    final results = await Future.wait([
      rootstock.getMinimumSwapIn(),
      rootstock.getMaximumSwapIn(),
    ]);
    return (min: results[0], max: results[1]);
  }

  @override
  Future<void> execute() async {
    SwapInData? data;
    try {
      logger.i("Preimage: ${preimage.hash}, ${preimage.preimage.length}");

      /// Create a reverse submarine swap
      final swap = await _generateSwapRequest();

      // ── Create recovery data immediately after swap creation ──
      // The preimage is the single most critical piece of data.
      // Without it, any on-chain funds locked by Boltz are UNRECOVERABLE.
      data = SwapInData(
        boltzId: swap.id,
        preimageHex: hex.encode(preimage.preimage),
        preimageHash: preimage.hash,
        onchainAmountSat: swap.onchainAmount?.toInt() ?? 0,
        timeoutBlockHeight: swap.timeoutBlockHeight.toInt(),
        chainId: rootstock.config.rootstockConfig.chainId,
        accountIndex: params.accountIndex,
      );
      emit(SwapInRequestCreated(data));
      logger.i('Swap data persisted for ${swap.id} with preimage');
      logger.d('Swap ${swap.toString()}');

      // Create the payment cubit but DON'T execute yet — we must subscribe
      // to its broadcast stream first to avoid losing fast-emitted states
      // (e.g. PayExternalRequired when no NWC wallet is connected).
      final payment = _createPaymentForSwap(
        invoice: swap.invoice,
        amount: params.amount,
      );

      // Subscribe to Boltz status updates with timeout
      final swapStatusFuture = _waitForSwapOnChain(swap.id);
      emit(SwapInAwaitingOnChain(data));

      // Subscribe to payment stream BEFORE executing so we never miss
      // states on the broadcast stream (Bolt11 resolve/finalize are near-
      // synchronous and can complete before an await-for would subscribe).
      final paymentCompleter = Completer<void>();
      final paySub = payment.stream
          .where((state) => state is PayFailed || state is PayExternalRequired)
          .takeUntil(swapStatusFuture.asStream())
          .listen(
            (paymentState) {
              logger.e('Payment emitted with state: $paymentState');
              emit(SwapInPaymentProgress(data!, paymentState: paymentState));
            },
            onDone: () {
              if (!paymentCompleter.isCompleted) paymentCompleter.complete();
            },
          );

      // NOW execute the payment — the listener above is already active
      payment.execute();

      // Wait until the payment stream completes (either all states processed,
      // or takeUntil fires because Boltz locked on-chain)
      await paymentCompleter.future;
      await paySub.cancel();

      // Wait for Boltz's lockup transaction with a generous timeout
      final swapStatus = await swapStatusFuture.timeout(
        const Duration(minutes: 30),
        onTimeout: () => throw TimeoutException(
          'Timed out waiting for Boltz to lock funds on-chain for swap ${swap.id}. '
          'The Lightning payment may still be pending. '
          'If Boltz never locks, the Lightning HTLC will expire and refund automatically.',
        ),
      );

      final lockupTxId = swapStatus.transaction?.id;
      if (lockupTxId == null) {
        throw StateError(
          'Boltz reported on-chain status but no transaction ID for swap ${swap.id}',
        );
      }

      // ── Persist lockup tx hash immediately ──
      data = data.copyWith(
        lockupTxHash: lockupTxId,
        lastBoltzStatus: swapStatus.status,
      );
      emit(SwapInFunded(data));

      TransactionInformation lockupTx = await rootstock.awaitTransaction(
        lockupTxId,
      );

      // ── Persist refund address from the lockup tx ──
      data = data.copyWith(refundAddress: lockupTx.from.with0x);
      emit(SwapInFunded(data));

      /// Create the args record for the claim function
      final claimArgs = _generateClaimArgs(lockupTx: lockupTx, swap: swap);
      logger.i('Claim can be unlocked with arguments: $claimArgs');

      /// Withdraw the funds to our own address, providing swapper with preimage to settle lightning
      /// Must send via RIF if no previous balance exists
      String tx = await _claim(claimArgs: claimArgs);

      data = data.copyWith(claimTxHash: tx);
      emit(SwapInClaimed(data));

      final receipt = await rootstock.awaitReceipt(tx);
      logger.i('Claim receipt: $receipt');

      emit(SwapInCompleted(data));
      logger.i('Swap-in completed: $tx');
      await close();
    } on TimeoutException catch (e, st) {
      logger.e('Timeout during swap-in: $e');
      emit(SwapInFailed(e, data: data, stackTrace: st));
    } catch (e, st) {
      logger.e('Error during swap in operation: $e');
      emit(SwapInFailed(e, data: data, stackTrace: st));
    }
  }

  @override
  Future<SwapInFees> estimateFees() async {
    // params.amount is the desired *on-chain* amount. Use the inverse Boltz
    // formula so the fee overhead accounts for the percentage being applied
    // to the (larger) invoice, not to the desired on-chain amount.
    // ignore: unused_local_variable
    final (:invoiceAmount, :feeOverhead) = await getIt<BoltzClient>()
        .computeInvoiceForDesiredOnchain(
          desiredOnchainAmount: params.amount,
          from: 'BTC',
          to: 'RBTC',
        );

    final relayFees = BitcoinAmount.fromBigInt(
      BitcoinUnit.wei,
      await rifRelay.estimateClaimBeforeLock(params.evmKey),
    );
    logger.d('Estimated relay fees ${relayFees.getInSats} sats');

    return SwapInFees(
      estimatedGasFees: BitcoinAmount.zero(),
      estimatedSwapFees: feeOverhead,
      estimatedRelayFees: relayFees,
    );
  }

  Future<ReverseResponse> _generateSwapRequest() async {
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
  }) {
    Bolt11PaymentRequest pr = Bolt11PaymentRequest(invoice);
    final invoiceAmount = BitcoinAmount.fromDecimal(
      BitcoinUnit.bitcoin,
      pr.amount.toString(),
    );
    logger.i(
      'Invoice to pay: ${invoiceAmount.getInSats} against ${amount.getInSats} planned, hash: ${pr.tags.firstWhere((t) => t.type == 'payment_hash').data} against planned ${preimage.hash}',
    );

    /// Before paying, check that the invoice swapper generated is for the correct amount
    assert(invoiceAmount == amount);

    /// Before paying, check that the invoice hash is equivalent to the preimage hash we generated
    /// Ensures we know the invoice can't be settled until we reveal it in the claim txn
    assert(
      pr.tags.firstWhere((t) => t.type == 'payment_hash').data == preimage.hash,
    );

    return getIt<Payments>().pay(
      Bolt11PayParameters(amount: amount, to: invoice),
    );
  }

  ClaimArgs _generateClaimArgs({
    required TransactionInformation lockupTx,
    required ReverseResponse swap,
  }) {
    return (
      amount: BitcoinAmount.fromBigInt(
        BitcoinUnit.sat,
        BigInt.from(swap.onchainAmount!),
      ).getInWei,
      preimage: Uint8List.fromList(preimage.preimage),

      /// Why is swap.refundPublicKey null in the response
      refundAddress:
          lockupTx.from, //EthereumAddress.fromHex(swap.refundPublicKey!),

      timelock: BigInt.from(swap.timeoutBlockHeight),

      /// EIP-712 signature parts from the claim address (placeholder zeros until wired up)
      v: BigInt.zero,
      r: Uint8List(32),
      s: Uint8List(32),
    );
  }

  Future<String> _claim({required claimArgs}) async {
    EtherSwap etherSwap = await rootstock.getEtherSwapContract();
    return (await rifRelay.relayClaim(
      etherSwap,
      params.evmKey,
      claimArgs,
    )).transactionHash.toString();
  }

  /// We generate the preimage for the invoice we will pay
  /// This prevents swapper from being able to claim the HTLC
  /// until we reveal the preimage to make the claim transaction
  /// Has to be 32 bytes for the claim txn to pass
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
          // If Boltz reports failure, throw so we don't hang waiting forever.
          // For reverse swaps, transaction.failed means Boltz couldn't lock
          // on-chain — the Lightning HTLC will expire and refund automatically.
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

  @override
  Future<bool> recover() async {
    final currentState = state;
    final data = currentState.data;
    if (data == null) return false; // Never started
    if (currentState.isTerminal) return true; // Already resolved

    try {
      // Fetch current Boltz status
      final boltzResponse = await getIt<BoltzClient>().getSwap(
        id: data.boltzId,
      );
      final boltzStatus = boltzResponse.status;

      // If Boltz already refunded itself, the swap is lost.
      if (boltzStatus == 'transaction.refunded') {
        logger.w(
          'SwapRecovery: swap-in ${data.boltzId} — Boltz refunded. '
          'Funds lost (preimage was not revealed in time).',
        );
        emit(
          SwapInFailed(
            'Boltz refunded the on-chain lockup. The claim window expired.',
            data: data.copyWith(lastBoltzStatus: boltzStatus),
          ),
        );
        return false;
      }

      // If swap expired without Boltz ever locking, Lightning refunds automatically.
      if (boltzStatus == 'swap.expired' ||
          boltzStatus == 'transaction.failed') {
        logger.i(
          'SwapRecovery: swap-in ${data.boltzId} expired/failed before lockup. '
          'Lightning payment refunded automatically.',
        );
        emit(
          SwapInFailed(
            'Swap expired. No on-chain funds at risk.',
            data: data.copyWith(lastBoltzStatus: boltzStatus),
          ),
        );
        return true;
      }

      // If Boltz reports invoice.settled, the claim was already processed.
      if (boltzStatus == 'invoice.settled') {
        logger.i('SwapRecovery: swap-in ${data.boltzId} already settled.');
        emit(SwapInCompleted(data.copyWith(lastBoltzStatus: boltzStatus)));
        return true;
      }

      // Boltz has locked on-chain, we need to claim.
      if (boltzStatus == 'transaction.mempool' ||
          boltzStatus == 'transaction.confirmed' ||
          currentState is SwapInFunded ||
          currentState is SwapInClaimed) {
        return await _attemptRecoveryClaim(
          data.copyWith(lastBoltzStatus: boltzStatus),
        );
      }

      logger.d(
        'SwapRecovery: swap-in ${data.boltzId} in status $boltzStatus — '
        'no action needed yet.',
      );
      return false;
    } catch (e) {
      logger.e('SwapRecovery: error recovering ${data.boltzId}: $e');
      return false;
    }
  }

  Future<bool> _attemptRecoveryClaim(SwapInData data) async {
    // If we don't have the refund address yet, try to resolve it from the
    // lockup tx hash (persisted or re-fetched from the Boltz HTTP API).
    if (data.refundAddress == null) {
      String? txHash = data.lockupTxHash;

      // If we never persisted the lockup tx hash either, try fetching the
      // current swap status from Boltz.
      if (txHash == null) {
        try {
          final status = await getIt<BoltzClient>().getSwap(id: data.boltzId);
          txHash = status.transaction?.id;
        } catch (e) {
          logger.w(
            'SwapRecovery: ${data.boltzId} — could not fetch Boltz status: $e',
          );
        }
      }

      if (txHash == null) {
        logger.e(
          'SwapRecovery: swap-in ${data.boltzId} missing lockup tx hash. '
          'Cannot derive refund address.',
        );
        emit(
          SwapInFailed(
            'Claim parameters incomplete (missing: lockupTxHash). '
            'Contact support with swap ID.',
            data: data,
          ),
        );
        return false;
      }

      // We have the tx hash — fetch the full transaction from the chain.
      logger.i(
        'SwapRecovery: ${data.boltzId} — resolving refund address from '
        'lockup tx $txHash',
      );
      final lockupTx = await rootstock.awaitTransaction(txHash);
      data = data.copyWith(
        lockupTxHash: txHash,
        refundAddress: lockupTx.from.with0x,
      );
      emit(SwapInFunded(data)); // persist updated data
    }

    // We have all claim params — attempt claim via RIF Relay.
    return false;
    // try {
    //   final amountWei = BitcoinAmount.fromBigInt(
    //     BitcoinUnit.sat,
    //     BigInt.from(claimP.onchainAmountSat),
    //   ).getInWei;

    //   final swapContract = await rootstock.getEtherSwapContract();
    //   final relay = getIt<RifRelay>(param1: rootstock.client);

    //   final tx = await relay.relayClaim(
    //     swapContract,
    //     params.evmKey,
    //     _generateClaimArgs(...)
    //   );

    //   logger.i('SwapRecovery: claim broadcast for ${claimP.boltzId}: $tx');
    //   data = data.copyWith(claimTxHash: tx);
    //   emit(SwapInClaimed(data));

    //   await rootstock.awaitReceipt(tx);
    //   logger.i('SwapRecovery: claim confirmed for ${claimP.boltzId}');
    //   emit(SwapInCompleted(data));
    //   return true;
    // } catch (e) {
    //   logger.e('SwapRecovery: claim failed for ${claimP.boltzId}: $e');
    //   return false;
    // }
  }
}
