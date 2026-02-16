import 'package:web3dart/web3dart.dart';

import '../../../evm/operations/swap_in/swap_in_state.dart';

sealed class EscrowClaimState {}

class EscrowClaimInitialised extends EscrowClaimState {}

class EscrowClaimSwapProgress extends EscrowClaimState {
  final SwapInState swapState;
  EscrowClaimSwapProgress(this.swapState);
}

class EscrowClaimCompleted extends EscrowClaimState {
  TransactionInformation transactionInformation;
  EscrowClaimCompleted({required this.transactionInformation});
}

class EscrowClaimFailed extends EscrowClaimState {
  final dynamic error;
  final StackTrace? stackTrace;

  EscrowClaimFailed(this.error, [this.stackTrace]);
}
