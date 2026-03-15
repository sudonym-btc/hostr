import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';
import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import '../../../evm/chain/rootstock/rif_relay/rif_relay.dart';
import '../../../evm/main.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import '../onchain_operation.dart';
import 'escrow_fund_models.dart';
import 'escrow_fund_state.dart';

@injectable
class EscrowFundOperation extends OnchainOperation {
  final EscrowFundParams? params;
  EthereumAddress? _relaySmartWalletAddress;
  GasEstimate? _gasEstimate;

  @override
  String get tradeId => params!.negotiateReservation.getDtag()!;

  EscrowFundOperation(
    Auth auth,
    TradeAccountAllocator tradeAccountAllocator,
    Evm evm,
    CustomLogger logger,
    @factoryParam this.params,
  ) : super(
        auth,
        tradeAccountAllocator,
        evm,
        logger,
        const OnchainInitialised(),
      ) {
    if (params != null) {
      chain = evm.getChainForEscrowService(params!.escrowService);
      contract = chain.getSupportedEscrowContract(params!.escrowService);
    }
  }

  /// Create for recovery mode. [recoveryChain] and [recoveryContract] are pre-resolved.
  EscrowFundOperation.forRecovery(
    Auth auth,
    TradeAccountAllocator tradeAccountAllocator,
    Evm evm,
    CustomLogger logger, {
    required EvmChain recoveryChain,
    required SupportedEscrowContract recoveryContract,
    required OnchainOperationState initialState,
  }) : params = null,
       super(auth, tradeAccountAllocator, evm, logger, initialState) {
    chain = recoveryChain;
    contract = recoveryContract;
    final data = initialState.data;
    if (data is EscrowFundData) {
      accountIndex = data.accountIndex;
    }
  }

  // ── OnchainOperation overrides ────────────────────────────────────

  @override
  String get namespace => 'escrow_fund';

  @override
  OnchainOperationData dataFromJson(Map<String, dynamic> json) =>
      EscrowFundData.fromJson(json);

  @override
  Future<void> initialize() async {
    await super.initialize();
    await _ensureSwapClaimAddress();
  }

  @override
  String get swapInvoiceDescription => params!.swapInvoiceDescription;

  EthereumAddress? _swapClaimAddress;

  @override
  EthereumAddress get swapClaimAddress {
    final address = _swapClaimAddress;
    if (address == null) {
      throw StateError('swapClaimAddress accessed before initialization');
    }
    return address;
  }

  @override
  EthereumAddress? get swapClaimDestination =>
      contract.supportsClaimSwapAndFund ? contract.address : null;

  @override
  OnchainOperationData buildInitialData({
    required ContractCallIntent callIntent,
    required String transport,
  }) {
    final params = _requireParams();
    return EscrowFundData(
      tradeId: params.negotiateReservation.getDtag()!,
      contractAddress: params.escrowService.contractAddress,
      chainId: params.escrowService.chainId,
      accountIndex: accountIndex,
      callIntent: callIntent,
      transport: transport,
    );
  }

  @override
  Future<ContractCallIntent> buildDirectCallIntent() async {
    final params = _requireParams();
    return contract.fund(await _buildFundArgs(params));
  }

  @override
  SwapInClaimCallback? get swapClaimCallback =>
      contract.supportsClaimSwapAndFund ? _claimAndFund : null;

  @override
  void onGasEstimated(GasEstimate estimate) =>
      logger.spanSync('onGasEstimated', () {
        _gasEstimate = estimate;
      });

  @override
  void onTransactionConfirmed(
    OnchainOperationData data,
    TransactionReceipt receipt,
  ) => logger.spanSync('onTransactionConfirmed', () {
    final gasUsed = receipt.gasUsed?.toInt();
    final estimatedLimit = data.callIntent?.maxGas;
    final gasPrice = data.callIntent?.gasPrice?.getInWei;
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
        final params = _requireParams();
        final fundArgs = await _buildFundArgs(params);
        final ethKey = fundArgs.ethKey;
        final etherSwap = await chain.getEtherSwapContract();
        final sender = ethKey.address;
        final senderBalance = await chain.getBalance(sender);
        final intent = contract.claimSwapAndFund(
          ClaimSwapAndFundArgs(
            swapContract: etherSwap.self.address,
            claimArgs: claimArgs,
            fundArgs: fundArgs,
          ),
        );
        logger.i(
          'Submitting claimAndFund from ${sender.eip55With0x} '
          'with balance=${senderBalance.getInWei} wei, '
          'swapContract=${etherSwap.self.address.eip55With0x}, '
          'tradeId=${fundArgs.tradeId}',
        );
        final usesRelayForClaimAndFund = _usesRelayForClaimAndFund();
        final txHash = usesRelayForClaimAndFund
            ? ((await contract.rifRelay!.relayCall(
                    ethKey,
                    intent,
                  )).txHash?.toString() ??
                  '')
            : await broadcastContractCallIntent(intent, ethKey);

        if (txHash.isEmpty) {
          throw StateError(
            'Could not extract transaction hash from claimAndFund transaction',
          );
        }
        return txHash;
      });

  Future<void> _ensureSwapClaimAddress() =>
      logger.span('ensureSwapClaimAddress', () async {
        final ethKey = await _activeEthKey();
        _swapClaimAddress = contract.supportsClaimSwapAndFund
            ? ethKey.address
            : (_relaySmartWalletAddress ?? ethKey.address);
        if (!_usesRelayForClaimAndFund()) {
          _relaySmartWalletAddress = null;
          return;
        }

        final rifRelay = contract.rifRelay!;

        _relaySmartWalletAddress = (await rifRelay.getSmartWalletAddress(
          ethKey,
        )).address;
        _swapClaimAddress = contract.supportsClaimSwapAndFund
            ? ethKey.address
            : (_relaySmartWalletAddress ?? ethKey.address);
      });

  // ── Fee estimation (public) ───────────────────────────────────────

  Future<EscrowFundFees> estimateFees() =>
      logger.span('estimateFees', () async {
        final params = _requireParams();
        final fundArgs = await _buildFundArgs(params);
        await _ensureSwapClaimAddress();
        final quote = await estimateOperationFees();
        return EscrowFundFees(
          estimatedGasFees: quote.gasEstimate.fee,
          estimatedSwapFees: quote.swapFees,
          estimatedEscrowFees: fundArgs.escrowFee ?? BitcoinAmount.zero(),
        );
      });

  EscrowFundParams _requireParams() {
    final params = this.params;
    if (params == null) {
      throw StateError(
        'EscrowFundOperation params are unavailable in recovery',
      );
    }
    return params;
  }

  Future<EthPrivateKey> _activeEthKey() =>
      auth.hd.getActiveEvmKey(accountIndex: accountIndex);

  Future<FundArgs> _buildFundArgs(EscrowFundParams params) async {
    final amount = BitcoinAmount.fromAmount(params.amount);
    return FundArgs(
      tradeId: params.negotiateReservation.getDtag()!,
      amount: amount,
      sellerEvmAddress: params.sellerProfile.evmAddress!,
      arbiterEvmAddress: params.escrowService.evmAddress,
      unlockAt: params.negotiateReservation.end.millisecondsSinceEpoch ~/ 1000,
      escrowFee: BitcoinAmount.fromInt(
        BitcoinUnit.sat,
        params.escrowService.escrowFee(amount.getInSats.toInt()),
      ),
      ethKey: await _activeEthKey(),
      gasEstimate: _gasEstimate,
    );
  }

  bool _usesRelayForClaimAndFund() =>
      contract.supportsClaimSwapAndFund && contract.rifRelay != null;
}
