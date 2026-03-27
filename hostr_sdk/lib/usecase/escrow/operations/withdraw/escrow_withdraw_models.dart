import 'package:models/main.dart';

/// Parameters for an atomic escrow-withdraw + swap-out operation.
///
/// The withdraw pulls settled funds from the escrow contract into the
/// smart-wallet, and the swap-out locks them into the Boltz submarine swap
/// contract — all in a single atomic UserOperation.
class EscrowWithdrawParams {
  final EscrowService escrowService;
  final String tradeId;

  /// The on-chain address that was awarded funds during settlement
  /// (buyer, seller, or arbiter). Must match a non-zero entry in
  /// `pendingWithdrawals[tradeId]`.
  final String beneficiaryEvmAddress;

  EscrowWithdrawParams({
    required this.escrowService,
    required this.tradeId,
    required this.beneficiaryEvmAddress,
  });
}
