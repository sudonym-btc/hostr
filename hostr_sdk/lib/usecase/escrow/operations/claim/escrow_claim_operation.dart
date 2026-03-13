import 'package:injectable/injectable.dart';

import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import '../../../evm/main.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import '../onchain_operation.dart';
import 'escrow_claim_models.dart';

@injectable
class EscrowClaimOperation extends OnchainOperation {
  final EscrowClaimParams params;

  @override
  String get tradeId => params.tradeId;

  EscrowClaimOperation(
    Auth auth,
    Evm evm,
    CustomLogger logger,
    @factoryParam this.params,
  ) : super(auth, evm, logger, const OnchainInitialised()) {
    chain = evm.getChainForEscrowService(params.escrowService!);
    contract = chain.getSupportedEscrowContract(params.escrowService!);
  }

  // ── OnchainOperation overrides ────────────────────────────────────

  @override
  String get namespace => 'escrow_claim';

  @override
  OnchainOperationData dataFromJson(Map<String, dynamic> json) =>
      OnchainCallData.fromJson(json);

  @override
  String get swapInvoiceDescription => 'Hostr Escrow Claim';

  @override
  Future<void> preflight() => logger.span('preflight', () async {
    final canClaim = await contract.canClaim(tradeId: params.tradeId);
    if (!canClaim) {
      throw StateError(
        'Claim is not available yet. Trade must still be active and '
        'current time must be after unlockAt.',
      );
    }
  });

  @override
  OnchainOperationData buildInitialData({
    required ContractCallIntent callIntent,
    required String transport,
  }) => OnchainCallData(
    operationIdValue: params.tradeId,
    contractAddress: params.escrowService!.contractAddress,
    chainId: params.escrowService!.chainId,
    accountIndex: accountIndex,
    callIntent: callIntent,
    transport: transport,
  );

  @override
  Future<ContractCallIntent> buildDirectCallIntent() async => contract.claim(
    tradeId: params.tradeId,
    ethKey: auth.getActiveEvmKey(accountIndex: accountIndex),
  );

  @override
  Future<ContractCallIntent> buildRelayedCallIntent() => contract.claimRelayed(
    tradeId: params.tradeId,
    ethKey: auth.getActiveEvmKey(accountIndex: accountIndex),
  );
}
