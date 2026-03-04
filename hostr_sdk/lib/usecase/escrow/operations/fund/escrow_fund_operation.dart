import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

@injectable
class EscrowFundOperation extends OnchainOperation {
  final EscrowFundParams? params;
  late ContractFundEscrowParams contractParams;

  EscrowFundOperation(
    Auth auth,
    Evm evm,
    CustomLogger logger,
    @factoryParam this.params,
  ) : super(auth, evm, logger, const OnchainInitialised()) {
    if (params != null) {
      chain = evm.getChainForEscrowService(params!.escrowService);
      contract = chain.getSupportedEscrowContract(params!.escrowService);
      contractParams = params!.toContractParams(auth.getActiveEvmKey());
    }
  }

  /// Create for recovery mode. [recoveryChain] and [recoveryContract] are pre-resolved.
  EscrowFundOperation.forRecovery(
    Auth auth,
    Evm evm,
    CustomLogger logger, {
    required EvmChain recoveryChain,
    required SupportedEscrowContract recoveryContract,
    required OnchainOperationState initialState,
  }) : params = null,
       super(auth, evm, logger, initialState) {
    chain = recoveryChain;
    contract = recoveryContract;
    final data = initialState.data;
    if (data is EscrowFundData) {
      accountIndex = data.accountIndex;
      contractParams = data.toContractParams(
        auth.getActiveEvmKey(accountIndex: accountIndex),
      );
    }
  }

  // ── OnchainOperation overrides ────────────────────────────────────

  @override
  String get storeNamespace => 'escrow_fund';

  @override
  Future<GasEstimate> estimateGas() =>
      contract.estimateEscrowFundFee(contractParams);

  @override
  BitcoinAmount get requiredOnchainValue => params != null
      ? BitcoinAmount.fromAmount(params!.amount)
      : BitcoinAmount.zero();

  @override
  String get swapInvoiceDescription => params!.swapInvoiceDescription;

  @override
  OnchainOperationData buildInitialData() => EscrowFundData(
    tradeId: contractParams.tradeId,
    reservedAmountWeiHex: BitcoinAmount.fromAmount(
      params!.amount,
    ).getInWei.toRadixString(16),
    sellerEvmAddress: contractParams.sellerEvmAddress,
    arbiterEvmAddress: contractParams.arbiterEvmAddress,
    contractAddress: params!.escrowService.contractAddress,
    chainId: params!.escrowService.chainId,
    unlockAt: contractParams.unlockAt,
    accountIndex: accountIndex,
    escrowFeeWeiHex: contractParams.escrowFee?.getInWei.toRadixString(16),
  );

  @override
  Future<TransactionInformation> executeTransaction() =>
      contract.deposit(contractParams);

  @override
  void onAddressResolved(int resolvedAccountIndex) {
    final evmKey = auth.getActiveEvmKey(accountIndex: resolvedAccountIndex);
    contractParams = params!.toContractParams(evmKey);
  }

  @override
  void onGasEstimated(GasEstimate estimate) {
    contractParams = contractParams.withGasEstimate(estimate);
  }

  @override
  void onBeforeTransaction(OnchainOperationData data) {
    final fundData = data as EscrowFundData;
    final evmKey = auth.getActiveEvmKey(accountIndex: fundData.accountIndex);
    contractParams = fundData.toContractParams(evmKey);
  }

  @override
  void onTransactionConfirmed(
    OnchainOperationData data,
    TransactionReceipt receipt,
  ) {
    final gasUsed = receipt.gasUsed?.toInt();
    final estimatedLimit = contractParams.gasEstimate?.gasLimit.toInt();
    final gasPrice = contractParams.gasEstimate?.gasPrice.getInWei;
    if (gasUsed != null && estimatedLimit != null && gasPrice != null) {
      final refundGas = estimatedLimit - gasUsed;
      final refundWei = BigInt.from(refundGas) * gasPrice;
      logger.w(
        'Gas usage: estimated=$estimatedLimit, actual=$gasUsed, '
        'refunded=$refundGas units '
        '(~${BitcoinAmount.inWei(refundWei).getInSats} sats)',
      );
    }
  }

  // ── Fee estimation (public) ───────────────────────────────────────

  Future<EscrowFundFees> estimateFees() async {
    final gasEstimate = await contract.estimateEscrowFundFee(contractParams);
    final swapDeficit = await computeSwapDeficit(gasEstimate);
    final swapFees = swapDeficit > BitcoinAmount.zero()
        ? await chain
              .swapIn(
                SwapInParams(
                  evmKey: contractParams.ethKey,
                  accountIndex: accountIndex,
                  amount: swapDeficit,
                  invoiceDescription: params!.swapInvoiceDescription,
                ),
              )
              .estimateFees()
        : SwapInFees(
            estimatedGasFees: BitcoinAmount.zero(),
            estimatedSwapFees: BitcoinAmount.zero(),
            estimatedRelayFees: BitcoinAmount.zero(),
          );
    return EscrowFundFees(
      estimatedGasFees: gasEstimate.fee,
      estimatedSwapFees: swapFees,
      estimatedEscrowFees: contractParams.escrowFee ?? BitcoinAmount.zero(),
    );
  }
}
