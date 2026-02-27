import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_in/swap_in_operation.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_out/swap_out_operation.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_models.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_operation.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_out/swap_out_models.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_out/swap_out_operation.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_record.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';

/// A fake [RootstockSwapInOperation] for testing [SwapRecoveryService].
///
/// Instead of constructing a real cubit with Rootstock/RifRelay/etc
/// dependencies, this fake lets tests configure the result of [recover()].
class FakeSwapInOperation extends Fake implements RootstockSwapInOperation {
  /// Return value for [recover()]. Defaults to true (resolved).
  bool recoverResult = true;

  /// If non-null, [recover()] will throw this.
  Object? recoverError;

  /// Captures calls to [recover()] for assertions.
  final List<({SwapInRecord record, String boltzStatus})> recoverCalls = [];

  @override
  Future<bool> recover({
    required SwapInRecord record,
    required String boltzStatus,
    required EvmChain chain,
    required SwapStore swapStore,
  }) async {
    recoverCalls.add((record: record, boltzStatus: boltzStatus));
    if (recoverError != null) throw recoverError!;
    return recoverResult;
  }

  @override
  Future<void> close() async {}
}

/// A fake [RootstockSwapOutOperation] for testing [SwapRecoveryService].
class FakeSwapOutOperation extends Fake implements RootstockSwapOutOperation {
  /// Return value for [recover()]. Defaults to true (resolved).
  bool recoverResult = true;

  /// If non-null, [recover()] will throw this.
  Object? recoverError;

  /// Captures calls to [recover()] for assertions.
  final List<({SwapOutRecord record, String boltzStatus})> recoverCalls = [];

  @override
  Future<bool> recover({
    required SwapOutRecord record,
    required String boltzStatus,
    required EvmChain chain,
    required SwapStore swapStore,
  }) async {
    recoverCalls.add((record: record, boltzStatus: boltzStatus));
    if (recoverError != null) throw recoverError!;
    return recoverResult;
  }

  @override
  Future<void> close() async {}
}
