import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/cubit/payment/payment.cubit.dart';
import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../evm/evm_chain.dart';

sealed class SwapState {
  const SwapState();
}

final class SwapInitialised extends SwapState {
  const SwapInitialised();
}

final class SwapRequestCreated extends SwapState {
  const SwapRequestCreated();
}

final class SwapPaymentProgress extends SwapState {
  final PaymentState paymentState;
  const SwapPaymentProgress({required this.paymentState});
}

final class SwapAwaitingOnChain extends SwapState {
  const SwapAwaitingOnChain();
}

final class SwapFunded extends SwapState {
  const SwapFunded();
}

final class SwapClaimed extends SwapState {
  const SwapClaimed();
}

final class SwapCompleted extends SwapState {
  const SwapCompleted();
}

final class SwapFailed extends SwapState {
  const SwapFailed(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}

class SwapCubitParams<T extends EvmChain> {
  final EthPrivateKey ethKey;
  final Amount amount;
  final T evmChain;

  SwapCubitParams({
    required this.ethKey,
    required this.amount,
    required this.evmChain,
  });
}

abstract class SwapCubit<T extends SwapCubitParams> extends Cubit<SwapState> {
  CustomLogger logger = CustomLogger();
  final T params;
  SwapCubit(this.params) : super(SwapInitialised());
  void confirm() {
    params.evmChain
        .swapIn(
          key: params.ethKey,
          amount: BitcoinAmount.fromAmount(params.amount),
        )
        .listen(emit);
  }
}
