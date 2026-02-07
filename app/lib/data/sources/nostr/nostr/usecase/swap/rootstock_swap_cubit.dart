// import 'package:web3dart/web3dart.dart';

import '../evm/rootstock.dart';
import 'swap_cubit.dart';

class RootstockSwapCubitParams extends SwapCubitParams<Rootstock> {
  RootstockSwapCubitParams({
    required super.ethKey,
    required super.amount,
    required super.evmChain,
  });
}

class RootstockSwapCubit extends SwapCubit<RootstockSwapCubitParams> {
  RootstockSwapCubit(super.params);

  @override
  confirm() async {
    try {} catch (error, stackTrace) {
      logger.e('Swap failed', error: error, stackTrace: stackTrace);
      final e = SwapFailed(error, stackTrace);
      emit(e);
      throw e;
    }
  }
}
