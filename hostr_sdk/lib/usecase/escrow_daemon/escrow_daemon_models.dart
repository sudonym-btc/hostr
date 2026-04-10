import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart' show Web3Client;

import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../evm/chain/evm_chain.dart';

/// Status of a tracked escrow trade.
enum TradeStatus { funded, arbitrated, released, claimed, unknown }

/// In-memory snapshot of a trade derived from on-chain events.
class TradeSnapshot {
  final String tradeId;
  final TradeStatus status;
  final int amountSats;
  final String? lastTxHash;
  final DateTime updatedAt;

  TradeSnapshot({
    required this.tradeId,
    required this.status,
    required this.amountSats,
    this.lastTxHash,
    required this.updatedAt,
  });

  TradeSnapshot copyWith({
    TradeStatus? status,
    int? amountSats,
    String? lastTxHash,
    DateTime? updatedAt,
  }) => TradeSnapshot(
    tradeId: tradeId,
    status: status ?? this.status,
    amountSats: amountSats ?? this.amountSats,
    lastTxHash: lastTxHash ?? this.lastTxHash,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'tradeId': tradeId,
    'status': status.name,
    'amountSats': amountSats,
    'txHash': lastTxHash,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Configuration for the escrow daemon bootstrap.
class EscrowDaemonConfig {
  /// Fee percentage for the escrow service (e.g. 1 for 1%).
  final double feePercent;

  /// Maximum trade duration.
  final Duration maxDuration;

  /// Which chain index to use from [Evm.configuredChains].
  /// Defaults to 0 (the first configured chain).
  final int chainIndex;

  const EscrowDaemonConfig({
    this.feePercent = 1,
    this.maxDuration = const Duration(days: 365),
    this.chainIndex = 0,
  });
}

/// All the long-lived objects the daemon needs after bootstrap.
class EscrowDaemonContext {
  final EscrowService escrowService;
  final SupportedEscrowContract contract;
  final EvmChain configuredChain;
  final Web3Client web3client;

  EscrowDaemonContext({
    required this.escrowService,
    required this.contract,
    required this.configuredChain,
    required this.web3client,
  });
}
