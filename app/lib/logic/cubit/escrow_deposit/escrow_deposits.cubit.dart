import 'package:flutter_bloc/flutter_bloc.dart';

import '../payment/payments.cubit.dart';
import '../swap/swaps.cubit.dart';
import 'escrow_deposit.cubit.dart';

/// TODO: should be hydrated from storage
class EscrowDepositManager extends Cubit<EscrowDepositCubit?> {
  final List<EscrowDepositCubit> escrowDeposits = [];
  final SwapManager swapManager;
  final PaymentsManager paymentsManager;
  EscrowDepositManager({
    required this.swapManager,
    required this.paymentsManager,
  }) : super(null);

  /// Once we have re-synched emitted contract logs to current EVM state
  /// check status of swaps and payments accompanying statuses
  /// Pick up where we left off for each escrow deposit if required
  init() {
    escrowDeposits
        .where((escrowDeposit) =>
            escrowDeposit.state is! EscrowDepositStateTerminal)
        .forEach((escrowDeposit) {
      escrowDeposit.checkStatus();
    });
  }
}
