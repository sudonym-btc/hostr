import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../../../util/bitcoin_amount.dart';
import '../../../escrow/supported_escrow_contract/supported_escrow_contract.dart';

/// The lifecycle status of an escrow lock.
///
/// Tracks where the escrow fund operation is in its multi-step flow so that
/// a background worker can resume from the right point after a crash.
enum EscrowLockStatus {
  /// Lock acquired, swap-in may be in progress. Balance is reserved but
  /// no deposit has been attempted.
  swapping,

  /// Swap-in completed (or was not needed). The on-chain balance is ready
  /// for the deposit transaction but it hasn't been broadcast yet.
  readyToDeposit,

  /// The deposit transaction has been broadcast. [EscrowLock.depositTxHash]
  /// contains the hash to monitor.
  depositing,
}

/// A lock representing an in-flight escrow operation that is currently using
/// (or about to use) the on-chain balance.
///
/// Locks are persisted to disk so a background worker can read them even if
/// the foreground app is not running. The lock carries enough information to
/// reconstruct a [ContractFundEscrowParams] and call `contract.deposit()`
/// without needing the original [EscrowFundParams] objects.
class EscrowLock {
  /// The unique trade identifier for the escrow operation.
  final String tradeId;

  /// Amount of on-chain funds reserved by this escrow operation, stored as
  /// a hex-encoded BigInt (wei).
  final BigInt reservedAmountWei;

  /// When the lock was first acquired.
  final DateTime acquiredAt;

  /// Current lifecycle status of the escrow operation.
  final EscrowLockStatus status;

  // ── Contract parameters (needed to resume the deposit) ──────────────

  /// EVM address of the seller (payee).
  final String sellerEvmAddress;

  /// EVM address of the escrow arbiter.
  final String arbiterEvmAddress;

  /// The escrow contract address on-chain.
  final String contractAddress;

  /// The EVM chain ID where the escrow contract is deployed.
  final int chainId;

  /// Unix timestamp (seconds) when the escrow funds unlock.
  final int unlockAt;

  /// Tx hash of the deposit transaction once broadcast. `null` until the
  /// deposit is sent.
  final String? depositTxHash;

  EscrowLock({
    required this.tradeId,
    required this.reservedAmountWei,
    required this.acquiredAt,
    this.status = EscrowLockStatus.swapping,
    required this.sellerEvmAddress,
    required this.arbiterEvmAddress,
    required this.contractAddress,
    required this.chainId,
    required this.unlockAt,
    this.depositTxHash,
  });

  /// Create a copy with updated fields.
  EscrowLock copyWith({EscrowLockStatus? status, String? depositTxHash}) {
    return EscrowLock(
      tradeId: tradeId,
      reservedAmountWei: reservedAmountWei,
      acquiredAt: acquiredAt,
      status: status ?? this.status,
      sellerEvmAddress: sellerEvmAddress,
      arbiterEvmAddress: arbiterEvmAddress,
      contractAddress: contractAddress,
      chainId: chainId,
      unlockAt: unlockAt,
      depositTxHash: depositTxHash ?? this.depositTxHash,
    );
  }

  /// Deserialise from JSON (stored in [KeyValueStorage]).
  factory EscrowLock.fromJson(Map<String, dynamic> json) {
    return EscrowLock(
      tradeId: json['tradeId'] as String,
      reservedAmountWei: BigInt.parse(
        json['reservedAmountWei'] as String,
        radix: 16,
      ),
      acquiredAt: DateTime.fromMillisecondsSinceEpoch(
        json['acquiredAt'] as int,
      ),
      status: EscrowLockStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EscrowLockStatus.swapping,
      ),
      sellerEvmAddress: json['sellerEvmAddress'] as String? ?? '',
      arbiterEvmAddress: json['arbiterEvmAddress'] as String? ?? '',
      contractAddress: json['contractAddress'] as String? ?? '',
      chainId: json['chainId'] as int? ?? 0,
      unlockAt: json['unlockAt'] as int? ?? 0,
      depositTxHash: json['depositTxHash'] as String?,
    );
  }

  /// Serialise to JSON for disk persistence.
  Map<String, dynamic> toJson() => {
    'tradeId': tradeId,
    'reservedAmountWei': reservedAmountWei.toRadixString(16),
    'acquiredAt': acquiredAt.millisecondsSinceEpoch,
    'status': status.name,
    'sellerEvmAddress': sellerEvmAddress,
    'arbiterEvmAddress': arbiterEvmAddress,
    'contractAddress': contractAddress,
    'chainId': chainId,
    'unlockAt': unlockAt,
    if (depositTxHash != null) 'depositTxHash': depositTxHash,
  };

  /// Whether this lock is in a state where the deposit can be retried.
  bool get canResumeDeposit =>
      status == EscrowLockStatus.readyToDeposit ||
      status == EscrowLockStatus.depositing;

  /// Reconstruct the [ContractFundEscrowParams] needed to call
  /// `contract.deposit()` from the persisted lock fields.
  ///
  /// The [ethKey] must be supplied at call time because private keys are
  /// never persisted. Typically derived from `auth.getActiveEvmKey()`.
  ContractFundEscrowParams toContractParams(EthPrivateKey ethKey) {
    return ContractFundEscrowParams(
      tradeId: tradeId,
      amount: BitcoinAmount.inWei(reservedAmountWei),
      sellerEvmAddress: sellerEvmAddress,
      arbiterEvmAddress: arbiterEvmAddress,
      ethKey: ethKey,
      unlockAt: unlockAt,
    );
  }

  @override
  String toString() =>
      'EscrowLock(tradeId: $tradeId, status: ${status.name}, '
      'reservedAmountWei: $reservedAmountWei, '
      'contract: $contractAddress, chainId: $chainId, '
      'depositTxHash: $depositTxHash, acquiredAt: $acquiredAt)';
}
