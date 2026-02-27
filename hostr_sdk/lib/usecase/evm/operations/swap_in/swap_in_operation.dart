import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import '../../chain/evm_chain.dart';
import '../swap_record.dart';
import '../swap_store.dart';
import 'swap_in_models.dart';
import 'swap_in_state.dart';

abstract class SwapInOperation extends Cubit<SwapInState> {
  final CustomLogger logger;
  final Auth auth;
  final SwapInParams params;

  SwapInOperation({
    required this.auth,
    required this.logger,
    @factoryParam required this.params,
  }) : super(SwapInInitialised());

  Future<SwapInFees> estimateFees();
  Future<void> execute();

  /// Recover a persisted swap-in record.
  ///
  /// Checks the current Boltz status and either marks the swap as completed,
  /// failed, or attempts to re-claim on-chain funds using the preimage.
  ///
  /// Returns `true` if the swap was resolved (completed or terminal failure).
  Future<bool> recover({
    required SwapInRecord record,
    required String boltzStatus,
    required EvmChain chain,
    required SwapStore swapStore,
  });
}
