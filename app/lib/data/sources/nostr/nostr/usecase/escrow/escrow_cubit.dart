import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
import 'package:hostr/data/sources/nostr/nostr/hostr.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/escrow.dart';
import 'package:hostr/injection.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../swap/swap_cubit.dart';

sealed class EscrowState {}

class EscrowInitialised extends EscrowState {}

class EscrowSwapProgress extends EscrowState {
  final SwapState swapState;
  EscrowSwapProgress(this.swapState);
}

class EscrowCompleted extends EscrowState {
  TransactionInformation transactionInformation;
  EscrowCompleted({required this.transactionInformation});
}

class EscrowFailed extends EscrowState {
  final dynamic error;
  final StackTrace? stackTrace;

  EscrowFailed(this.error, [this.stackTrace]);
}

class EscrowCubit extends Cubit<EscrowState> {
  CustomLogger logger = CustomLogger();
  final EscrowFundParams params;
  late EtherAmount value;
  late MultiEscrow contract;
  EscrowCubit(this.params) : super(EscrowInitialised());

  void confirm() async {
    getIt<Hostr>().escrow.fund(params).listen(emit);
  }
}
