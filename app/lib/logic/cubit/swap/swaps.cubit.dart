import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';

/// TODO: should be hydrated from storage
class SwapManager extends Cubit<SwapCubit?> {
  List<SwapCubit> swaps = [];
  PaymentsManager paymentsManager;
  SwapManager({required this.paymentsManager}) : super(null);

  init() {
    swaps
        .whereType<SwapInCubit>()
        .where((swap) => swap.state is! SwapCubitTerminalState)
        .forEach((swap) {
      swap.checkStatus();
    });
  }

  swapIn() {
    SwapInCubit swap = SwapInCubit();
    swaps.add(swap);
    emit(swap);
  }

  swapOut() {
    SwapOutCubit swap = SwapOutCubit();
    swaps.add(swap);
    emit(swap);
  }
}
