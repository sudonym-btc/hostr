import 'package:hostr_sdk/datasources/boltz/boltz.dart';
import 'package:hostr_sdk/datasources/swagger_generated/boltz.swagger.dart';
import 'package:mockito/mockito.dart';

/// Fake Boltz client that returns pre-configured swap statuses and
/// cooperative refund signatures.
class FakeBoltzClient extends Fake implements BoltzClient {
  /// Map from swap id → status string.
  final Map<String, String> swapStatuses = {};

  /// Map from swap id → cooperative refund signature hex.
  final Map<String, String> cooperativeRefundSignatures = {};

  /// If true, [getSwap] will throw (simulates Boltz being unreachable).
  bool throwOnGetSwap = false;

  @override
  Future<SwapStatus> getSwap({required String id}) async {
    if (throwOnGetSwap) {
      throw Exception('Boltz API unreachable');
    }
    final status = swapStatuses[id];
    if (status == null) {
      throw Exception('Swap $id not found in fake');
    }
    return SwapStatus(status: status);
  }

  @override
  Future<SwapSubmarineIdRefundGet$Response?> getCooperativeRefundSignature({
    required String id,
  }) async {
    final sig = cooperativeRefundSignatures[id];
    if (sig == null) return null;
    return SwapSubmarineIdRefundGet$Response(signature: sig);
  }
}
