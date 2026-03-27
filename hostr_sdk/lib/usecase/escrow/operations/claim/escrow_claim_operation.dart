import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import '../../../evm/main.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../escrow_call.dart';
import 'escrow_claim_models.dart';

@injectable
class EscrowClaimOperation extends EscrowCall {
  final EscrowClaimParams params;

  EscrowClaimOperation(
    Auth auth,
    TradeAccountAllocator tradeAccountAllocator,
    Evm evm,
    CustomLogger logger,
    @factoryParam this.params,
  ) : super(auth, tradeAccountAllocator, evm, logger) {
    configuredChain = evm.getChainForEscrowService(params.escrowService!);
    contract = configuredChain.escrow.getSupportedEscrowContract(
      params.escrowService!,
    );
  }

  @override
  EscrowService get escrowService => params.escrowService!;

  @override
  String get tradeId => params.tradeId;

  @override
  Future<void> preflight() async {
    final canClaim = await contract.canClaim(tradeId: params.tradeId);
    if (!canClaim) {
      throw StateError(
        'Claim is not available yet. Trade must still be active and '
        'current time must be after unlockAt.',
      );
    }
  }

  @override
  List<CallIntent> buildCallIntents() => [
    contract.claim(tradeId: params.tradeId, ethKey: signer),
  ];
}
