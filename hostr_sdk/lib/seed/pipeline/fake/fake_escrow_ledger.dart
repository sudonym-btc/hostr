import '../seed_pipeline_models.dart';
import '../sink/seed_sink.dart';

/// A single trade in the fake ledger.
class FakeTrade {
  final String tradeId;
  final String buyerPrivateKey;
  final String sellerPrivateKey;
  final String arbiterPrivateKey;
  final BigInt amountWei;
  final BigInt unlockAt;
  final String txHash;
  bool settled;
  EscrowOutcome? settlementOutcome;
  String? settleTxHash;

  FakeTrade({
    required this.tradeId,
    required this.buyerPrivateKey,
    required this.sellerPrivateKey,
    required this.arbiterPrivateKey,
    required this.amountWei,
    required this.unlockAt,
    required this.txHash,
    this.settled = false,
    this.settlementOutcome,
    this.settleTxHash,
  });
}

/// In-memory escrow ledger that simulates the MultiEscrow contract.
///
/// No web3dart, no JSON-RPC, no EVM opcodes.  Operates at the
/// application semantic level: trades, balances, settlements.
///
/// Tx hashes are deterministic hex strings derived from a counter.
class FakeEscrowLedger {
  final Map<String, FakeTrade> _trades = {};
  final Map<String, BigInt> _balances = {};
  int _txCounter = 0;

  /// All trades in the ledger.
  List<FakeTrade> get allTrades => _trades.values.toList();

  /// Get a trade by its deterministic trade ID.
  FakeTrade? getTrade(String tradeId) => _trades[tradeId];

  /// Create a new trade.  Returns a deterministic tx hash.
  ///
  /// If the trade already exists (idempotent re-seed), returns the
  /// existing tx hash with [TradeResult.alreadyExisted] set.
  TradeResult createTrade(SubmitTrade intent) {
    final existing = _trades[intent.tradeId];
    if (existing != null) {
      return TradeResult(txHash: existing.txHash, alreadyExisted: true);
    }

    final txHash = '0x${_txCounter.toRadixString(16).padLeft(64, '0')}';
    _txCounter++;

    _trades[intent.tradeId] = FakeTrade(
      tradeId: intent.tradeId,
      buyerPrivateKey: intent.buyerPrivateKey,
      sellerPrivateKey: intent.sellerPrivateKey,
      arbiterPrivateKey: intent.arbiterPrivateKey,
      amountWei: intent.amountWei,
      unlockAt: intent.unlockAt,
      txHash: txHash,
    );

    return TradeResult(txHash: txHash);
  }

  /// Settle an existing trade.  Returns a deterministic tx hash.
  TradeResult settle(SettleTrade intent) {
    final trade = _trades[intent.tradeId];
    if (trade == null) {
      throw StateError('Trade ${intent.tradeId} not found in fake ledger');
    }
    if (trade.settled) {
      return TradeResult(txHash: trade.settleTxHash!, alreadyExisted: true);
    }

    final txHash = '0x${_txCounter.toRadixString(16).padLeft(64, '0')}';
    _txCounter++;

    trade.settled = true;
    trade.settlementOutcome = intent.outcome;
    trade.settleTxHash = txHash;

    return TradeResult(txHash: txHash);
  }

  /// Set the balance of an address (mirrors `anvil_setBalance`).
  void setBalance(String address, BigInt amount) {
    _balances[address.toLowerCase()] = amount;
  }

  /// Get the balance of an address.
  BigInt getBalance(String address) {
    return _balances[address.toLowerCase()] ?? BigInt.zero;
  }

  /// Reset all state.
  void reset() {
    _trades.clear();
    _balances.clear();
    _txCounter = 0;
  }
}
