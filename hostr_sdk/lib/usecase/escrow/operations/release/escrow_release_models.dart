import 'package:models/main.dart';

class EscrowReleaseParams {
  final EscrowService? escrowService;
  final String tradeId;

  EscrowReleaseParams({required this.escrowService, required this.tradeId});
}
