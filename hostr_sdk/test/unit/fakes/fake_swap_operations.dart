import 'package:hostr_sdk/usecase/evm/chain/operations/swap_in/swap_in_operation.dart';
import 'package:hostr_sdk/usecase/evm/chain/operations/swap_out/swap_out_operation.dart';
import 'package:mockito/mockito.dart';

/// A fake [EvmSwapInOperation] for testing recovery.
///
/// Instead of constructing a real cubit with EVM chain dependencies,
/// this fake lets tests configure the result of [recover()].
class FakeSwapInOperation extends Fake implements EvmSwapInOperation {
  /// Return value for [recover()]. Defaults to true (resolved).
  bool recoverResult = true;

  /// If non-null, [recover()] will throw this.
  Object? recoverError;

  /// Count of [recover()] calls for assertions.
  int recoverCallCount = 0;

  @override
  Future<bool> recover({bool isBackground = false}) async {
    recoverCallCount++;
    if (recoverError != null) throw recoverError!;
    return recoverResult;
  }

  @override
  Future<void> close() async {}
}

/// A fake [EvmSwapOutOperation] for testing recovery.
class FakeSwapOutOperation extends Fake implements EvmSwapOutOperation {
  /// Return value for [recover()]. Defaults to true (resolved).
  bool recoverResult = true;

  /// If non-null, [recover()] will throw this.
  Object? recoverError;

  /// Count of [recover()] calls for assertions.
  int recoverCallCount = 0;

  @override
  Future<bool> recover({bool isBackground = false}) async {
    recoverCallCount++;
    if (recoverError != null) throw recoverError!;
    return recoverResult;
  }

  @override
  Future<void> close() async {}
}
