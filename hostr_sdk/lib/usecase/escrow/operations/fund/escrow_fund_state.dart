import 'package:web3dart/web3dart.dart';

import '../../../evm/operations/swap_in/swap_in_state.dart';

sealed class EscrowFundState {}

class EscrowFundInitialised extends EscrowFundState {}

class EscrowFundSwapProgress extends EscrowFundState {
  final SwapInState swapState;
  EscrowFundSwapProgress(this.swapState);
}

class EscrowFundDepositing extends EscrowFundState {
  final String? txHash;
  EscrowFundDepositing({this.txHash});
}

class EscrowFundCompleted extends EscrowFundState {
  TransactionInformation transactionInformation;
  EscrowFundCompleted({required this.transactionInformation});
}

class EscrowFundFailed extends EscrowFundState {
  final dynamic error;
  final StackTrace? stackTrace;

  EscrowFundFailed(this.error, [this.stackTrace]);
}
