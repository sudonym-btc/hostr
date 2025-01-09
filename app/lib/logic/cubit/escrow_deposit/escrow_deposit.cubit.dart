import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/payment/payment.cubit.dart';
import 'package:hostr/logic/cubit/swap/swap_in.cubit.dart';

/// TODO - When calculating the swap-in amount, should take into account the amount held in our EVM keys minus the amount committed to other escrow deposits
class EscrowDepositCubit extends Cubit<EscrowDepositState?> {
  EscrowDepositCubit() : super(EscrowDepositState());

  init() {
    checkStatus();
  }

  /// Check the status of the swap and payment associated with this escrow deposit
  checkStatus() {}
}

class EscrowDepositState {
  /// The swap in cubit associated with this escrow deposit
  SwapInCubit? swapInCubit;

  /// The EVM payment cubit associated with the escrow deposit
  /// Populated afer the swap and claim has succeeded
  PaymentCubit? paymentCubit;
}

class EscrowDepositStateInFlight extends EscrowDepositState {}

class EscrowDepositStateTerminal extends EscrowDepositState {}

class EscrowDepositStateSucceeded extends EscrowDepositStateTerminal {}

class EscrowDepositStateFailed extends EscrowDepositStateTerminal {}
