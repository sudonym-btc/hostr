import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:crypto/crypto.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/bolt11_operation.dart';
import 'package:hostr_sdk/usecase/payments/payments.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show TransactionInformation;

import '../../../../../../datasources/boltz/boltz.dart';
import '../../../../../../datasources/boltz/swagger_generated/boltz.swagger.dart';
import '../../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../../util/main.dart';
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
  }) {
    preimage = _newPreimage();
  }

  @override
  Future<void> execute() async {
    try {
      final preimageData = _newPreimage();
      logger.i(
        "Preimage: ${preimageData.hash}, ${preimageData.preimage.length}",
      );

      /// Create a reverse submarine swap
      final swap = await _generateSwapRequest();
      emit(SwapInRequestCreated());

      logger.d('Swap ${swap.toString()}');

      // Need to ignore timeout errors here, since the invoice only completes after the swap is done
      final p = _getPaymentCubitForSwap(
        invoice: swap.invoice,
        amount: params.amount,
      );

      Future<SwapStatus> swapStatus = _waitForSwapOnChain(swap.id);
      emit(SwapInAwaitingOnChain());

      // @todo: should not await completion, but should throw if payment can't even be initiated
      await for (final paymentState
          in p
              .where(
                (state) => state is PayFailed || state is PayExternalRequired,
              )
              .takeUntil(swapStatus.asStream())) {
        logger.e('Payment emitted with state: $paymentState');
        emit(SwapInPaymentProgress(paymentState: paymentState));
      }

      TransactionInformation lockupTx = await rootstock.awaitTransaction(
        (await swapStatus).transaction!.id!,
      );
      emit(SwapInFunded());

      /// Create the args record for the claim function
      final claimArgs = _generateClaimArgs(lockupTx: lockupTx, swap: swap);

      logger.i('Claim can be unlocked with arguments: $claimArgs');

      /// Withdraw the funds to our own address, providing swapper with preimage to settle lightning
      /// Must send via RIF if no previous balance exists
      String tx = await _claim(claimArgs: claimArgs);
      emit(SwapInClaimed());
      final receipt = await rootstock.awaitReceipt(tx);
      logger.i('Claim receipt: $receipt');
      emit(SwapInCompleted());
      logger.i('Sent RBTC in: $tx');
    } catch (e, st) {
      logger.e('Error during swap in operation: $e');
      emit(SwapInFailed(e, st));
      addError(SwapInFailed(e, st));
      rethrow;
    } finally {
      await close();
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
    final relayFees = await rifRelay.estimateClaimRelayFees(
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
    logger.i(
      'Using RIF smart wallet as claim address: $claimAddress, ${params.amount.getInSats} sats',
    );
    return getIt<BoltzClient>().reverseSubmarine(
      invoiceAmount: params.amount.getInSats.toDouble(),
      claimAddress: claimAddress,
      preimageHash: preimage.hash,
    );
  }

  Stream<PayState> _getPaymentCubitForSwap({
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

    /// Pay the invoice, though it won't complete until we reveal the preimage in the claim txn
    final payment = getIt<Payments>().pay(
      Bolt11PayParameters(amount: amount, to: invoice),
    );
    payment.execute();
    return payment.stream;
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
  /// until we reveil the preimage to make the claim transaction
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
        .firstWhere(
          (swapStatus) =>
              swapStatus.status == 'transaction.confirmed' ||
              swapStatus.status == 'transaction.mempool',
        );
  }
}
