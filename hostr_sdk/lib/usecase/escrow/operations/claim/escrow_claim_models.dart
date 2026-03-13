import 'package:models/main.dart';

class EscrowClaimParams {
  final EscrowService? escrowService;
  final String tradeId;

  EscrowClaimParams({required this.escrowService, required this.tradeId});
}
