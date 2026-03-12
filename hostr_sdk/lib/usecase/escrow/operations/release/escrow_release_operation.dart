import 'package:injectable/injectable.dart';

import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import '../../../evm/main.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import '../onchain_operation.dart';
import 'escrow_release_models.dart';

@injectable
class EscrowReleaseOperation extends OnchainOperation {
  final EscrowReleaseParams params;
  late ContractReleaseEscrowParams contractParams;

  EscrowReleaseOperation(
    Auth auth,
    Evm evm,
    CustomLogger logger,
    @factoryParam this.params,
  ) : super(auth, evm, logger, const OnchainInitialised()) {
    chain = evm.getChainForEscrowService(params.escrowService!);
    contract = chain.getSupportedEscrowContract(params.escrowService!);
    if (params.evmAddress != null) {
      accountIndex = auth.findEvmAccountIndex(params.evmAddress!);
    }
    contractParams = params.toContractParams(
      auth.getActiveEvmKey(accountIndex: accountIndex),
    );
  }

  // ── OnchainOperation overrides ────────────────────────────────────

  @override
  String get namespace => 'escrow_release';

  @override
  OnchainOperationData dataFromJson(Map<String, dynamic> json) =>
      OnchainCallData.fromJson(json);

  @override
  String get swapInvoiceDescription => 'Hostr Escrow Release';

  @override
  Future<void> initialize() => logger.span('initialize', () async {
    if (params.evmAddress != null) return;

    final trade = await contract.getTrade(params.tradeId);
    if (trade != null) {
      for (final candidate in [trade.buyer, trade.seller]) {
        try {
          accountIndex = auth.findEvmAccountIndex(candidate);
          onAddressResolved(accountIndex);
          return;
        } on StateError catch (_) {
          continue;
        }
      }
    }

    throw StateError('No matching EVM account found for release.');
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
  Future<ContractCallIntent> buildDirectCallIntent() async =>
      contract.release(contractParams);

  @override
  Future<ContractCallIntent> buildRelayedCallIntent() =>
      contract.releaseRelayed(contractParams);

  @override
  void onAddressResolved(int resolvedAccountIndex) =>
      logger.spanSync('onAddressResolved', () {
        contractParams = params.toContractParams(
          auth.getActiveEvmKey(accountIndex: resolvedAccountIndex),
        );
      });
}
