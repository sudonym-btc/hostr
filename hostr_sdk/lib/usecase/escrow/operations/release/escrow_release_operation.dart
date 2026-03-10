import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';
import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import '../../../evm/main.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import '../onchain_operation.dart';
import 'escrow_release_models.dart';
import 'escrow_release_state.dart';

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

  /// Create for recovery mode.
  EscrowReleaseOperation.forRecovery(
    Auth auth,
    Evm evm,
    CustomLogger logger, {
    required EvmChain recoveryChain,
    required SupportedEscrowContract recoveryContract,
    required OnchainOperationState initialState,
  }) : params = EscrowReleaseParams(
         // Placeholder — recovery doesn't use params directly.
         escrowService: null,
         tradeId: initialState.data!.operationId,
       ),
       super(auth, evm, logger, initialState) {
    chain = recoveryChain;
    contract = recoveryContract;
    final data = initialState.data;
    if (data != null) {
      accountIndex = data.accountIndex;
      contractParams = ContractReleaseEscrowParams(
        tradeId: data.operationId,
        ethKey: auth.getActiveEvmKey(accountIndex: accountIndex),
      );
    }
  }

  // ── OnchainOperation overrides ────────────────────────────────────

  @override
  String get namespace => 'escrow_release';

  @override
  OnchainOperationData dataFromJson(Map<String, dynamic> json) =>
      EscrowReleaseData.fromJson(json);

  @override
  Future<GasEstimate> estimateGas() => logger.span(
    'estimateGas',
    () => contract.estimateReleaseFee(contractParams),
  );

  /// EscrowRelease doesn't send value — it only needs gas.
  @override
  BitcoinAmount get requiredOnchainValue => BitcoinAmount.zero();

  @override
  String get swapInvoiceDescription => 'Hostr Escrow Release';

  @override
  Future<void> preflight() => logger.span('preflight', () async {
    final canRelease = await contract.canRelease(contractParams);
    if (!canRelease) {
      throw StateError('Release is not available. Trade must still be active.');
    }
  });

  @override
  OnchainOperationData buildInitialData() => EscrowReleaseData(
    tradeId: params.tradeId,
    contractAddress: params.escrowService!.contractAddress,
    chainId: params.escrowService!.chainId,
    accountIndex: accountIndex,
  );

  @override
  Future<TransactionInformation> executeTransaction() =>
      logger.span('executeTransaction', () => contract.release(contractParams));

  @override
  void onAddressResolved(int resolvedAccountIndex) =>
      logger.spanSync('onAddressResolved', () {
        contractParams = params.toContractParams(
          auth.getActiveEvmKey(accountIndex: resolvedAccountIndex),
        );
      });

  @override
  void onBeforeTransaction(OnchainOperationData data) =>
      logger.spanSync('onBeforeTransaction', () {
        contractParams = ContractReleaseEscrowParams(
          tradeId: data.operationId,
          ethKey: auth.getActiveEvmKey(accountIndex: data.accountIndex),
        );
      });

  /// When [EscrowReleaseParams.evmAddress] was supplied we already know the
  /// exact account index. Otherwise, query the on-chain trade to discover
  /// which of our HD addresses is the buyer or seller and resolve from that.
  @override
  Future<void> resolveAddress() => logger.span('resolveAddress', () async {
    final trade = await contract.getTrade(params.tradeId);
    if (trade != null) {
      // Release can be called by buyer or seller — try both.
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

  // ── Fee estimation (public) ───────────────────────────────────────

  Future<EscrowReleaseFees> estimateFees() =>
      logger.span('estimateFees', () async {
        final gasEstimate = await contract.estimateReleaseFee(contractParams);
        final swapDeficit = await computeSwapDeficit(gasEstimate);
        final swapFees = swapDeficit > BitcoinAmount.zero()
            ? await chain
                  .swapIn(
                    SwapInParams(
                      evmKey: contractParams.ethKey,
                      accountIndex: accountIndex,
                      amount: swapDeficit,
                      invoiceDescription: swapInvoiceDescription,
                    ),
                  )
                  .estimateFees()
            : SwapInFees(
                estimatedGasFees: BitcoinAmount.zero(),
                estimatedSwapFees: BitcoinAmount.zero(),
                estimatedRelayFees: BitcoinAmount.zero(),
              );
        return EscrowReleaseFees(
          estimatedGasFees: gasEstimate.fee,
          estimatedSwapFees: swapFees,
        );
      });
}
