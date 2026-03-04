import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

@injectable
class EscrowClaimOperation extends OnchainOperation {
  final EscrowClaimParams params;
  late ContractClaimEscrowParams contractParams;

  EscrowClaimOperation(
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
  EscrowClaimOperation.forRecovery(
    Auth auth,
    Evm evm,
    CustomLogger logger, {
    required EvmChain recoveryChain,
    required SupportedEscrowContract recoveryContract,
    required OnchainOperationState initialState,
  }) : params = EscrowClaimParams(
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
      contractParams = ContractClaimEscrowParams(
        tradeId: data.operationId,
        ethKey: auth.getActiveEvmKey(accountIndex: accountIndex),
      );
    }
  }

  // ── OnchainOperation overrides ────────────────────────────────────

  @override
  String get storeNamespace => 'escrow_claim';

  @override
  Future<GasEstimate> estimateGas() =>
      contract.estimateClaimFee(contractParams);

  /// Claim doesn't send value — it only needs gas.
  @override
  BitcoinAmount get requiredOnchainValue => BitcoinAmount.zero();

  @override
  String get swapInvoiceDescription => 'Hostr Escrow Claim';

  @override
  Future<void> preflight() async {
    final canClaim = await contract.canClaim(contractParams);
    if (!canClaim) {
      throw StateError(
        'Claim is not available yet. Trade must still be active and '
        'current time must be after unlockAt.',
      );
    }
  }

  @override
  OnchainOperationData buildInitialData() => EscrowClaimData(
    tradeId: params.tradeId,
    contractAddress: params.escrowService!.contractAddress,
    chainId: params.escrowService!.chainId,
    accountIndex: accountIndex,
  );

  @override
  Future<TransactionInformation> executeTransaction() =>
      contract.claim(contractParams);

  @override
  void onAddressResolved(int resolvedAccountIndex) {
    contractParams = params.toContractParams(
      auth.getActiveEvmKey(accountIndex: resolvedAccountIndex),
    );
  }

  @override
  void onBeforeTransaction(OnchainOperationData data) {
    contractParams = ContractClaimEscrowParams(
      tradeId: data.operationId,
      ethKey: auth.getActiveEvmKey(accountIndex: data.accountIndex),
    );
  }

  /// When [EscrowClaimParams.evmAddress] was supplied we already know the
  /// exact account index. Otherwise, query the on-chain trade to discover
  /// which of our HD addresses is the buyer (depositor) and resolve from
  /// that.
  @override
  Future<void> resolveAddress() async {
    if (params.evmAddress != null) return;
    final trade = await contract.getTrade(params.tradeId);
    if (trade != null) {
      // Claim is called by the buyer — try buyer first, then seller.
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
    // Fallback: normal HD scan (picks best-funded address).
    await super.resolveAddress();
  }

  // ── Fee estimation (public) ───────────────────────────────────────

  Future<EscrowClaimFees> estimateFees() async {
    final gasEstimate = await contract.estimateClaimFee(contractParams);
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
    return EscrowClaimFees(
      estimatedGasFees: gasEstimate.fee,
      estimatedSwapFees: swapFees,
    );
  }
}
