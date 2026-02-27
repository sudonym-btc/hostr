import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:crypto/crypto.dart';
import 'package:hostr_sdk/datasources/swagger_generated/boltz.swagger.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/payments.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' hide params;

import '../../../../../../datasources/boltz/boltz.dart';
import '../../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../../util/main.dart';
import '../../../../../payments/operations/pay_operation.dart';
import '../../../../../payments/operations/pay_state.dart';
import '../../../../chain/evm_chain.dart';
import '../../../../operations/swap_in/swap_in_operation.dart';
import '../../../../operations/swap_in/swap_in_state.dart';
import '../../../../operations/swap_record.dart';
import '../../../../operations/swap_store.dart';
import '../../rif_relay/rif_relay.dart';
import '../../rootstock.dart';

@injectable
class RootstockSwapInOperation extends SwapInOperation {
  final Rootstock rootstock;
  late final RifRelay rifRelay = getIt<RifRelay>(param1: rootstock.client);
  late final ({List<int> preimage, String hash}) preimage;
  late final SwapStore _swapStore = getIt<SwapStore>();

  RootstockSwapInOperation({
    required this.rootstock,
    required super.auth,
    required super.logger,
    @factoryParam required super.params,
  }) {
    preimage = _newPreimage();
  }

  @override
  Future<void> execute() async {
    SwapInRecord? record;
    try {
      logger.i("Preimage: ${preimage.hash}, ${preimage.preimage.length}");

      /// Create a reverse submarine swap
      final swap = await _generateSwapRequest();

      // ── PERSIST IMMEDIATELY after swap creation ──
      // The preimage is the single most critical piece of data.
      // Without it, any on-chain funds locked by Boltz are UNRECOVERABLE.
      record = SwapInRecord.create(
        boltzId: swap.id,
        preimage: preimage.preimage,
        preimageHash: preimage.hash,
        onchainAmountSat: swap.onchainAmount?.toInt() ?? 0,
        timeoutBlockHeight: swap.timeoutBlockHeight.toInt(),
        chainId: rootstock.config.rootstockConfig.chainId,
      );
      await _swapStore.save(record);
      logger.i('Swap record persisted for ${swap.id} with preimage');

      emit(SwapInRequestCreated());
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
      emit(SwapInAwaitingOnChain());

      // ── Update record: we've initiated the Lightning payment ──
      record =
          (await _swapStore.updateStatus(
                swap.id,
                SwapRecordStatus.funded,
                lastBoltzStatus: 'payment.initiated',
              ))!
              as SwapInRecord;

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
              emit(SwapInPaymentProgress(paymentState: paymentState));
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

      TransactionInformation lockupTx = await rootstock.awaitTransaction(
        lockupTxId,
      );
      emit(SwapInFunded());

      // ── Update record with lockup details needed for claim ──
      record =
          (await _swapStore.updateStatus(
                swap.id,
                SwapRecordStatus.funded,
                refundAddress: lockupTx.from.with0x,
                lastBoltzStatus: swapStatus.status,
              ))!
              as SwapInRecord;

      /// Create the args record for the claim function
      final claimArgs = _generateClaimArgs(lockupTx: lockupTx, swap: swap);
      logger.i('Claim can be unlocked with arguments: $claimArgs');

      // ── Mark as claiming before broadcasting ──
      record =
          (await _swapStore.updateStatus(swap.id, SwapRecordStatus.claiming))!
              as SwapInRecord;

      /// Withdraw the funds to our own address, providing swapper with preimage to settle lightning
      /// Must send via RIF if no previous balance exists
      String tx = await _claim(claimArgs: claimArgs);
      emit(SwapInClaimed());

      // ── Persist claim tx hash ──
      record =
          (await _swapStore.updateStatus(
                swap.id,
                SwapRecordStatus.claiming,
                resolutionTxHash: tx,
              ))!
              as SwapInRecord;

      final receipt = await rootstock.awaitReceipt(tx);
      logger.i('Claim receipt: $receipt');

      // ── Mark completed ──
      await _swapStore.updateStatus(swap.id, SwapRecordStatus.completed);

      emit(SwapInCompleted());
      logger.i('Swap-in completed: $tx');
      await close();
    } on TimeoutException catch (e, st) {
      logger.e('Timeout during swap-in: $e');
      if (record != null) {
        await _swapStore.updateStatus(
          record.id,
          SwapRecordStatus.needsAction,
          errorMessage: e.toString(),
        );
      }
      emit(SwapInFailed(e, st));
    } catch (e, st) {
      logger.e('Error during swap in operation: $e');
      if (record != null) {
        // Determine whether the swap needs recovery or has truly failed.
        // If we haven't funded yet, the swap can be safely abandoned.
        // If funds are at risk (funded/claiming), mark as needsAction for recovery.
        final recoverable =
            record.status == SwapRecordStatus.funded ||
            record.status == SwapRecordStatus.claiming;
        await _swapStore.updateStatus(
          record.id,
          recoverable ? SwapRecordStatus.needsAction : SwapRecordStatus.failed,
          errorMessage: e.toString(),
        );
      }
      emit(SwapInFailed(e, st));
    }
  }

  @override
  Future<SwapInFees> estimateFees() async {
    final boltzFees = await getIt<BoltzClient>().estimateReverseSwapFees(
      invoiceAmount: params.amount,
      from: 'BTC',
      to: 'RBTC',
    );

    final etherSwap = await rootstock.getEtherSwapContract();
    final relayFees = await rifRelay.estimateSwapInClaimRelayFees(
      signer: params.evmKey,
      etherSwap: etherSwap,
      preimage: Uint8List(32),
      amountWei: params.amount.getInWei,
      refundAddress: params.evmKey.address,
      timeoutBlockHeight: BigInt.zero,
    );
    logger.d('Estimated relay fees ${relayFees.getInSats} sats');

    return SwapInFees(
      estimatedGasFees: BitcoinAmount.zero(),
      estimatedSwapFees: boltzFees,
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

  ({
    BigInt amount,
    Uint8List preimage,
    Uint8List r,
    EthereumAddress refundAddress,
    Uint8List s,
    BigInt timelock,
    BigInt v,
  })
  _generateClaimArgs({
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
    EtherSwap swapContract = await rootstock.getEtherSwapContract();
    return rifRelay.relayClaimTransaction(
      signer: params.evmKey,
      etherSwap: swapContract,
      preimage: claimArgs.preimage,
      amountWei: claimArgs.amount,
      refundAddress: claimArgs.refundAddress,
      timeoutBlockHeight: claimArgs.timelock,
    );
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
  Future<bool> recover({
    required SwapInRecord record,
    required String boltzStatus,
    required EvmChain chain,
    required SwapStore swapStore,
  }) async {
    // If Boltz already refunded itself, the swap is lost.
    if (boltzStatus == 'transaction.refunded') {
      logger.w(
        'SwapRecovery: swap-in ${record.boltzId} — Boltz refunded. '
        'Funds lost (preimage was not revealed in time).',
      );
      await swapStore.updateStatus(
        record.id,
        SwapRecordStatus.failed,
        lastBoltzStatus: boltzStatus,
        errorMessage:
            'Boltz refunded the on-chain lockup. The claim window expired.',
      );
      return false;
    }

    // If swap expired without Boltz ever locking, Lightning refunds automatically.
    if (boltzStatus == 'swap.expired' || boltzStatus == 'transaction.failed') {
      logger.i(
        'SwapRecovery: swap-in ${record.boltzId} expired/failed before lockup. '
        'Lightning payment refunded automatically.',
      );
      await swapStore.updateStatus(
        record.id,
        SwapRecordStatus.failed,
        lastBoltzStatus: boltzStatus,
        errorMessage: 'Swap expired. No on-chain funds at risk.',
      );
      return true;
    }

    // If Boltz reports invoice.settled, the claim was already processed.
    if (boltzStatus == 'invoice.settled') {
      logger.i('SwapRecovery: swap-in ${record.boltzId} already settled.');
      await swapStore.updateStatus(
        record.id,
        SwapRecordStatus.completed,
        lastBoltzStatus: boltzStatus,
      );
      return true;
    }

    // Boltz has locked on-chain, we need to claim.
    if (boltzStatus == 'transaction.mempool' ||
        boltzStatus == 'transaction.confirmed' ||
        record.status == SwapRecordStatus.funded ||
        record.status == SwapRecordStatus.claiming) {
      return await _attemptRecoveryClaim(
        record: record,
        evmKey: params.evmKey,
        chain: chain,
        swapStore: swapStore,
      );
    }

    logger.d(
      'SwapRecovery: swap-in ${record.boltzId} in status $boltzStatus — '
      'no action needed yet.',
    );
    return false;
  }

  Future<bool> _attemptRecoveryClaim({
    required SwapInRecord record,
    required EthPrivateKey evmKey,
    required EvmChain chain,
    required SwapStore swapStore,
  }) async {
    final claimP = record.claimParams;
    if (claimP == null) {
      logger.e(
        'SwapRecovery: swap-in ${record.boltzId} missing refund address '
        '(lockup tx not yet observed). Funds may be unrecoverable.',
      );
      await swapStore.updateStatus(
        record.id,
        SwapRecordStatus.failed,
        errorMessage:
            'Preimage lost or claim parameters incomplete '
            '(missing: refundAddress). Contact support with swap ID.',
      );
      return false;
    }

    try {
      final amountWei = BitcoinAmount.fromBigInt(
        BitcoinUnit.sat,
        BigInt.from(claimP.onchainAmountSat),
      ).getInWei;

      final swapContract = await chain.getEtherSwapContract();
      final relay = getIt<RifRelay>(param1: chain.client);

      final tx = await relay.relayClaimTransaction(
        signer: evmKey,
        etherSwap: swapContract,
        preimage: claimP.preimage,
        amountWei: amountWei,
        refundAddress: EthereumAddress.fromHex(claimP.refundAddress),
        timeoutBlockHeight: BigInt.from(claimP.timeoutBlockHeight),
      );

      logger.i('SwapRecovery: claim broadcast for ${record.boltzId}: $tx');
      await swapStore.updateStatus(
        record.id,
        SwapRecordStatus.claiming,
        resolutionTxHash: tx,
      );

      await chain.awaitReceipt(tx);
      logger.i('SwapRecovery: claim confirmed for ${record.boltzId}');
      await swapStore.updateStatus(record.id, SwapRecordStatus.completed);
      return true;
    } catch (e) {
      logger.e('SwapRecovery: claim failed for ${record.boltzId}: $e');
      await swapStore.updateStatus(
        record.id,
        SwapRecordStatus.needsAction,
        errorMessage: 'Claim failed: $e',
      );
      return false;
    }
  }
}
