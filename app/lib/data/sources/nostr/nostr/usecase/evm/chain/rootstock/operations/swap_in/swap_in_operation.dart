import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:crypto/crypto.dart';
import 'package:hostr/core/util/bitcoin_amount.dart';
import 'package:hostr/data/sources/boltz/boltz.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:hostr/data/sources/boltz/swagger_generated/boltz.swagger.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/evm/chain/rootstock/rif_relay/rif_relay.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/evm/chain/rootstock/rootstock.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/evm/operations/swap_in/swap_in_operation.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/payments/payments.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/payment/bolt11_payment.cubit.dart';
import 'package:hostr/logic/cubit/payment/payment.cubit.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show TransactionInformation;

import '../../../../operations/swap_in/swap_in_state.dart';

@injectable
class RootstockSwapInOperation extends SwapInOperation {
  final Rootstock rootstock;
  late final RifRelay rifRelay = getIt<RifRelay>(param1: rootstock.client);
  late final ({List<int> preimage, String hash}) preimage;
  RootstockSwapInOperation({
    required this.rootstock,
    required super.auth,
    @factoryParam required super.params,
  }) {
    preimage = _newPreimage();
  }

  @override
  Stream<SwapInState> execute() async* {
    try {
      final preimageData = _newPreimage();
      logger.i(
        "Preimage: ${preimageData.hash}, ${preimageData.preimage.length}",
      );

      /// Create a reverse submarine swap
      final swap = await _generateSwapRequest();
      yield SwapInRequestCreated();

      logger.d('Swap ${swap.toString()}');

      // Need to ignore timeout errors here, since the invoice only completes after the swap is done
      PaymentCubit p = _getPaymentCubitForSwap(
        invoice: swap.invoice,
        amount: params.amount,
      );

      Future<SwapStatus> swapStatus = _waitForSwapOnChain(swap.id);

      // @todo: should not await completion, but should throw if payment can't even be initiated
      await for (final paymentState
          in p.stream
              .where((state) => state.status == PaymentStatus.failed)
              .takeUntil(swapStatus.asStream())) {
        logger.e('Payment failed with state: $paymentState');
        yield SwapInPaymentProgress(paymentState: paymentState);
      }

      yield SwapInAwaitingOnChain();

      TransactionInformation lockupTx = await rootstock.awaitTransaction(
        (await swapStatus).transaction!.id!,
      );
      yield SwapInFunded();

      /// Create the args record for the claim function
      final claimArgs = _generateClaimArgs(lockupTx: lockupTx, swap: swap);

      logger.i('Claim can be unlocked with arguments: $claimArgs');

      /// Withdraw the funds to our own address, providing swapper with preimage to settle lightning
      /// Must send via RIF if no previous balance exists
      String tx = await _claim(claimArgs: claimArgs);
      yield SwapInClaimed();
      final receipt = await rootstock.awaitReceipt(tx);
      logger.i('Claim receipt: $receipt');
      yield SwapInCompleted();
      logger.i('Sent RBTC in: $tx');
    } catch (e, st) {
      logger.e('Error during swap in operation: $e');
      yield SwapInFailed(e, st);
      rethrow;
    }
  }

  @override
  Future<BitcoinAmount> estimateFees() {
    // @todo: For simplicity, we return a fixed fee here. In a real implementation, you would call the Boltz API to get the current fees.
    return Future.value(BitcoinAmount.fromInt(BitcoinUnit.sat, 1000));
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

  PaymentCubit _getPaymentCubitForSwap({
    required String invoice,
    required BitcoinAmount amount,
  }) {
    Bolt11PaymentRequest pr = Bolt11PaymentRequest(invoice);
    final invoiceAmount = BitcoinAmount.fromDecimal(
      BitcoinUnit.bitcoin,
      pr.amount.toString(),
    );
    print('Invoice amount: ${pr.amount}, ${pr.amount.toString()}');
    logger.i(
      'Invoice to pay: ${invoiceAmount.getInWei} against ${amount.getInWei} planned, hash: ${pr.tags.firstWhere((t) => t.type == 'payment_hash').data} against planned ${preimage.hash}',
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
      Bolt11PaymentParameters(amount: amount, to: invoice),
    );
    payment.execute();
    return payment;
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
