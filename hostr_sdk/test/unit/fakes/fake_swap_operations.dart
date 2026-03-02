import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_in/swap_in_operation.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_out/swap_out_operation.dart';
import 'package:mockito/mockito.dart';

/// A fake [RootstockSwapInOperation] for testing recovery.
///
/// Instead of constructing a real cubit with Rootstock/RifRelay/etc
/// dependencies, this fake lets tests configure the result of [recover()].
class FakeSwapInOperation extends Fake implements RootstockSwapInOperation {
  /// Return value for [recover()]. Defaults to true (resolved).
  bool recoverResult = true;

  /// If non-null, [recover()] will throw this.
  Object? recoverError;

  /// Count of [recover()] calls for assertions.
  int recoverCallCount = 0;

  @override
  Future<bool> recover() async {
    recoverCallCount++;
    if (recoverError != null) throw recoverError!;
    return recoverResult;
  }

  @override
  Future<void> close() async {}
}

/// A fake [RootstockSwapOutOperation] for testing recovery.
class FakeSwapOutOperation extends Fake implements RootstockSwapOutOperation {
  /// Return value for [recover()]. Defaults to true (resolved).
  bool recoverResult = true;

  /// If non-null, [recover()] will throw this.
  Object? recoverError;

  /// Count of [recover()] calls for assertions.
  int recoverCallCount = 0;

  @override
  Future<bool> recover() async {
    recoverCallCount++;
    if (recoverError != null) throw recoverError!;
    return recoverResult;
  }

  @override
  Future<void> close() async {}
}
