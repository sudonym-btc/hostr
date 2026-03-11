import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';
import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import '../../../evm/chain/rootstock/rif_relay/rif_relay.dart';
import '../../../evm/main.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import '../onchain_operation.dart';
import 'escrow_fund_models.dart';
import 'escrow_fund_state.dart';

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
  String get namespace => 'escrow_fund';

  @override
  OnchainOperationData dataFromJson(Map<String, dynamic> json) =>
      EscrowFundData.fromJson(json);

  @override
  // Hardcode the address so that we can use a funded address and force a swap for testing
  resolveAddress() async {
    accountIndex = 1;
    onAddressResolved(accountIndex);
  }

  @override
  Future<GasEstimate> estimateGas() => logger.span(
    'estimateGas',
    () => contract.estimateEscrowFundFee(contractParams),
  );

  @override
  BitcoinAmount get requiredOnchainValue => params != null
      ? BitcoinAmount.fromAmount(params!.amount)
      : BitcoinAmount.zero();

  @override
  Future<BitcoinAmount> computeSwapDeficit(GasEstimate gasEstimate) =>
      logger.span('computeSwapDeficit', () async {
        final forcedSwapAmount = contractParams.amount.roundUp(BitcoinUnit.sat);
        logger.i(
          'Forcing escrow funding swap for testing: '
          '${forcedSwapAmount.getInSats} sats',
        );
        return forcedSwapAmount;
      });

  @override
  String get swapInvoiceDescription => params!.swapInvoiceDescription;

  @override
  EthereumAddress get swapClaimAddress => contractParams.ethKey.address;

  @override
  EthereumAddress get swapClaimDestination => contract.address;

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
      logger.span('executeTransaction', () => contract.deposit(contractParams));

  @override
  SwapInClaimCallback? get swapClaimCallback => _claimAndFund;

  @override
  void onAddressResolved(int resolvedAccountIndex) =>
      logger.spanSync('onAddressResolved', () {
        final evmKey = auth.getActiveEvmKey(accountIndex: resolvedAccountIndex);
        contractParams = params!.toContractParams(evmKey);
      });

  @override
  void onGasEstimated(GasEstimate estimate) =>
      logger.spanSync('onGasEstimated', () {
        contractParams = contractParams.withGasEstimate(estimate);
      });

  @override
  void onBeforeTransaction(OnchainOperationData data) => logger.spanSync(
    'onBeforeTransaction',
    () {
      final fundData = data as EscrowFundData;
      final evmKey = auth.getActiveEvmKey(accountIndex: fundData.accountIndex);
      contractParams = fundData.toContractParams(evmKey);
    },
  );

  @override
  void onTransactionConfirmed(
    OnchainOperationData data,
    TransactionReceipt receipt,
  ) => logger.spanSync('onTransactionConfirmed', () {
    final gasUsed = receipt.gasUsed?.toInt();
    final estimatedLimit = contractParams.gasEstimate?.gasLimit.toInt();
    final gasPrice = contractParams.gasEstimate?.gasPrice.getInWei;
    if (gasUsed != null && estimatedLimit != null && gasPrice != null) {
      final refundGas = estimatedLimit - gasUsed;
      final refundWei = BigInt.from(refundGas) * gasPrice;
      logger.d(
        'Gas usage: estimated=$estimatedLimit, actual=$gasUsed, '
        'refunded=$refundGas units '
        '(~${BitcoinAmount.inWei(refundWei).getInSats} sats)',
      );
    }
  });

  @override
  OnchainOperationData onNestedSwapFinished(
    OnchainOperationData data,
    SwapInState swapState,
  ) {
    final claimTxHash = swapState.data?.claimTxHash;
    if (claimTxHash == null || claimTxHash.isEmpty) {
      return data;
    }
    return data.copyWithTxHash(claimTxHash);
  }

  Future<String> _claimAndFund(ClaimArgs claimArgs) =>
      logger.span('claimAndFundSwapClaim', () async {
        final etherSwap = await chain.getEtherSwapContract();
        final sender = contractParams.ethKey.address;
        final senderBalance = await chain.getBalance(sender);
        logger.i(
          'Submitting claimAndFund from ${sender.eip55With0x} '
          'with balance=${senderBalance.getInWei} wei, '
          'swapContract=${etherSwap.self.address.eip55With0x}, '
          'tradeId=${contractParams.tradeId}',
        );
        final tx = await contract.claimAndFund(
          ContractClaimAndFundEscrowParams(
            swapContract: etherSwap.self.address,
            claimArgs: claimArgs,
            fundParams: contractParams,
          ),
        );

        final txHash = extractTxHash(tx);
        if (txHash == null) {
          throw StateError(
            'Could not extract transaction hash from claimAndFund transaction',
          );
        }
        return txHash;
      });

  // ── Fee estimation (public) ───────────────────────────────────────

  Future<EscrowFundFees> estimateFees() => logger.span(
    'estimateFees',
    () async {
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
                    claimAddress: swapClaimAddress,
                    claimDestination: swapClaimDestination,
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
    },
  );
}
