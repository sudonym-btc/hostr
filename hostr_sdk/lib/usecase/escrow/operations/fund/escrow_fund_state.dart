import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';
import '../../../evm/operations/swap_in/swap_in_state.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';

// ── Escrow fund recovery data ─────────────────────────────────────────────

/// Immutable snapshot of escrow-fund recovery data.
///
/// Created at the start of [EscrowFundOperation.execute] and threaded through
/// every state from [EscrowFundSwapProgress] onward.
class EscrowFundData {
  final String tradeId;
  final String reservedAmountWeiHex;
  final String sellerEvmAddress;
  final String arbiterEvmAddress;
  final String contractAddress;
  final int chainId;
  final int unlockAt;
  final int accountIndex;

  /// Gas price (in wei) pinned at estimation time.
  ///
  /// Persisted so that the deposit transaction uses the exact gas parameters
  /// the swap-in budget was calculated against — no drift between estimation
  /// and broadcast.
  final String? gasPriceWei;

  /// Gas limit pinned at estimation time. See [gasPriceWei].
  final String? gasLimit;

  /// The escrow fee in sats, persisted so the deposit call uses the same
  /// value that was included in the gas estimation calldata.
  final int? escrowFee;

  /// The Boltz swap ID of the nested swap-in, if a swap was required.
  /// Used by [EscrowFundRecoverer] to check swap completion without
  /// re-running the swap.
  final String? swapId;
  final String? depositTxHash;
  final String? errorMessage;

  const EscrowFundData({
    required this.tradeId,
    required this.reservedAmountWeiHex,
    required this.sellerEvmAddress,
    required this.arbiterEvmAddress,
    required this.contractAddress,
    required this.chainId,
    required this.unlockAt,
    required this.accountIndex,
    this.gasPriceWei,
    this.gasLimit,
    this.escrowFee,
    this.swapId,
    this.depositTxHash,
    this.errorMessage,
  });

  EscrowFundData copyWith({
    String? gasPriceWei,
    String? gasLimit,
    int? escrowFee,
    String? swapId,
    String? depositTxHash,
    String? errorMessage,
  }) => EscrowFundData(
    tradeId: tradeId,
    reservedAmountWeiHex: reservedAmountWeiHex,
    sellerEvmAddress: sellerEvmAddress,
    arbiterEvmAddress: arbiterEvmAddress,
    contractAddress: contractAddress,
    chainId: chainId,
    unlockAt: unlockAt,
    accountIndex: accountIndex,
    gasPriceWei: gasPriceWei ?? this.gasPriceWei,
    gasLimit: gasLimit ?? this.gasLimit,
    escrowFee: escrowFee ?? this.escrowFee,
    swapId: swapId ?? this.swapId,
    depositTxHash: depositTxHash ?? this.depositTxHash,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  /// Reconstruct [ContractFundEscrowParams] for the deposit call.
  ///
  /// If [gasPriceWei] and [gasLimit] were persisted, the returned params
  /// carry the original [GasEstimate] so the deposit uses the exact gas
  /// parameters the swap-in budget was calculated against.
  ContractFundEscrowParams toContractParams(EthPrivateKey ethKey) {
    GasEstimate? estimate;
    if (gasPriceWei != null && gasLimit != null) {
      final price = BigInt.parse(gasPriceWei!);
      final limit = BigInt.parse(gasLimit!);
      estimate = GasEstimate(
        fee: BitcoinAmount.inWei(price * limit),
        gasPrice: EtherAmount.inWei(price),
        gasLimit: limit,
      );
    }
    return ContractFundEscrowParams(
      tradeId: tradeId,
      amount: BitcoinAmount.inWei(
        BigInt.parse(reservedAmountWeiHex, radix: 16),
      ),
      sellerEvmAddress: sellerEvmAddress,
      arbiterEvmAddress: arbiterEvmAddress,
      ethKey: ethKey,
      unlockAt: unlockAt,
      escrowFee: escrowFee,
      gasEstimate: estimate,
    );
  }

  Map<String, dynamic> toJson() => {
    'tradeId': tradeId,
    'reservedAmountWeiHex': reservedAmountWeiHex,
    'sellerEvmAddress': sellerEvmAddress,
    'arbiterEvmAddress': arbiterEvmAddress,
    'contractAddress': contractAddress,
    'chainId': chainId,
    'unlockAt': unlockAt,
    'accountIndex': accountIndex,
    if (gasPriceWei != null) 'gasPriceWei': gasPriceWei,
    if (gasLimit != null) 'gasLimit': gasLimit,
    if (escrowFee != null) 'escrowFee': escrowFee,
    if (swapId != null) 'swapId': swapId,
    if (depositTxHash != null) 'depositTxHash': depositTxHash,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory EscrowFundData.fromJson(Map<String, dynamic> json) => EscrowFundData(
    tradeId: json['tradeId'] as String,
    reservedAmountWeiHex: json['reservedAmountWeiHex'] as String,
    sellerEvmAddress: json['sellerEvmAddress'] as String,
    arbiterEvmAddress: json['arbiterEvmAddress'] as String,
    contractAddress: json['contractAddress'] as String,
    chainId: json['chainId'] as int,
    unlockAt: json['unlockAt'] as int,
    accountIndex: json['accountIndex'] as int? ?? 0,
    gasPriceWei: json['gasPriceWei'] as String?,
    gasLimit: json['gasLimit'] as String?,
    escrowFee: json['escrowFee'] as int?,
    swapId: json['swapId'] as String?,
    depositTxHash: json['depositTxHash'] as String?,
    errorMessage: json['errorMessage'] as String?,
  );

  @override
  String toString() => 'EscrowFundData($tradeId)';
}

// ── Escrow fund cubit states ──────────────────────────────────────────────

sealed class EscrowFundState {
  const EscrowFundState();

  /// Persisted data. Non-null once the operation has started.
  EscrowFundData? get data => null;

  /// Unique operation ID for persistence.
  String? get operationId => data?.tradeId;

  /// Whether this is a terminal state.
  bool get isTerminal => false;

  /// Serialise for [OperationStateStore] persistence.
  Map<String, dynamic> toJson();

  /// Deserialise from persisted JSON.
  static EscrowFundState fromJson(Map<String, dynamic> json) {
    final state = json['state'] as String;
    return switch (state) {
      'initialised' => EscrowFundInitialised(),
      'swapProgress' => EscrowFundSwapProgress(EscrowFundData.fromJson(json)),
      'depositing' => EscrowFundDepositing(EscrowFundData.fromJson(json)),
      'completed' => EscrowFundCompleted(EscrowFundData.fromJson(json)),
      'failed' => EscrowFundFailed(
        json['errorMessage'] ?? 'Unknown error',
        data: EscrowFundData.fromJson(json),
      ),
      _ => EscrowFundInitialised(),
    };
  }
}

class EscrowFundInitialised extends EscrowFundState {
  @override
  Map<String, dynamic> toJson() => {'state': 'initialised'};
}

class EscrowFundSwapProgress extends EscrowFundState {
  @override
  final EscrowFundData data;

  /// Live swap state for UI. Null when restored from persisted JSON.
  final SwapInState? swapState;
  EscrowFundSwapProgress(this.data, {this.swapState});

  @override
  Map<String, dynamic> toJson() => {
    'state': 'swapProgress',
    'id': data.tradeId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

class EscrowFundDepositing extends EscrowFundState {
  @override
  final EscrowFundData data;
  EscrowFundDepositing(this.data);

  /// Convenience getter for UI.
  String? get txHash => data.depositTxHash;

  @override
  Map<String, dynamic> toJson() => {
    'state': 'depositing',
    'id': data.tradeId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

class EscrowFundCompleted extends EscrowFundState {
  @override
  final EscrowFundData data;

  /// The full tx info — ephemeral (not serialised).
  final TransactionInformation? transactionInformation;
  EscrowFundCompleted(this.data, {this.transactionInformation});

  @override
  bool get isTerminal => true;

  @override
  Map<String, dynamic> toJson() => {
    'state': 'completed',
    'id': data.tradeId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

class EscrowFundFailed extends EscrowFundState {
  @override
  final EscrowFundData? data;
  final dynamic error;
  final StackTrace? stackTrace;

  EscrowFundFailed(this.error, {this.data, this.stackTrace});

  @override
  bool get isTerminal => true;

  @override
  Map<String, dynamic> toJson() => {
    'state': 'failed',
    if (data != null) 'id': data!.tradeId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    if (data != null) ...data!.toJson(),
    'errorMessage': error.toString(),
  };
}
