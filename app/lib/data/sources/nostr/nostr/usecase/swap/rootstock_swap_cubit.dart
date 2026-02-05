import 'package:hostr/data/sources/boltz/swagger_generated/boltz.swagger.dart';
import 'package:hostr/export.dart';
import 'package:web3dart/web3dart.dart' show TransactionInformation;

// import 'package:web3dart/web3dart.dart';

import '../evm/rootstock.dart';
import 'swap_cubit.dart';

bool _hasMax8Decimals(double value) {
  final scaled = value * 100000000;
  return (scaled - scaled.roundToDouble()).abs() < 1e-6;
}

class RootstockSwapCubitParams extends SwapCubitParams<Rootstock> {
  RootstockSwapCubitParams({
    required super.ethKey,
    required super.amount,
    required super.evmChain,
  }) : assert(amount.value > 0),
       assert(
         _hasMax8Decimals(amount.value),
         'Amount must have at most 8 decimal places',
       );
}

class RootstockSwapCubit extends SwapCubit<RootstockSwapCubitParams> {
  RootstockSwapCubit(super.params);

  @override
  confirm() async {
    try {
      final preimageData = params.evmChain.newPreimage();
      logger.i(
        "Preimage: ${preimageData.hash}, ${preimageData.preimage.length}",
      );

      /// Create a reverse submarine swap
      final swap = await params.evmChain.generateSwapRequest(
        amount: params.amount,
        ethKey: params.ethKey,
        preimageHash: preimageData.hash,
      );
      emit(SwapInitialised());

      logger.d('Swap ${swap.toString()}');
      PaymentCubit p = params.evmChain.getPaymentCubitForSwap(
        invoice: swap.invoice,
        amount: params.amount,
        preimageHash: preimageData.hash,
      );
      emit(SwapPaymentProgress(paymentCubit: p));
      SwapStatus swapStatus = await params.evmChain.waitForSwapOnChain(swap.id);

      emit(SwapAwaitingOnChain());

      TransactionInformation lockupTx = await params.evmChain.awaitTransaction(
        swapStatus.transaction!.id!,
      );
      emit(SwapFunded());

      /// Create the args record for the claim function
      final claimArgs = params.evmChain.generateClaimArgs(
        lockupTx: lockupTx,
        swap: swap,
        preimage: preimageData.preimage,
      );

      logger.i('Claim can be unlocked with arguments: $claimArgs');

      /// Withdraw the funds to our own address, providing swapper with preimage to settle lightning
      /// Must send via RIF if no previous balance exists
      String tx = await params.evmChain.claim(
        ethKey: params.ethKey,
        claimArgs: claimArgs,
      );
      emit(SwapClaimed());
      final receipt = await params.evmChain.awaitReceipt(tx);
      logger.i('Claim receipt: $receipt');
      emit(SwapCompleted());
      logger.i('Sent RBTC in: $tx');
    } catch (error, stackTrace) {
      logger.e('Swap failed', error: error, stackTrace: stackTrace);
      final e = SwapFailed(error, stackTrace);
      emit(e);
      throw e;
    }
  }
}
