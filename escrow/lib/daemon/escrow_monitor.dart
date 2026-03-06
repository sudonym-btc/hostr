import 'dart:async';

import 'package:escrow/shared/protocol.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

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
  }) =>
      TradeSnapshot(
        tradeId: tradeId,
        status: status ?? this.status,
        amountSats: amountSats ?? this.amountSats,
        lastTxHash: lastTxHash ?? this.lastTxHash,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  TradeSummary toSummary() => TradeSummary(
        tradeId: tradeId,
        status: status.name,
        amountSats: amountSats,
        txHash: lastTxHash,
        updatedAt: updatedAt,
      );
}

/// Long-running monitor that subscribes to:
///   1. On-chain escrow contract events (fund, arbitrate, release, claim).
///   2. Nostr thread messages.
///
/// Maintains an in-memory map of all known trades so the CLI can read state
/// instantly without re-querying the chain.
class EscrowMonitor {
  final Hostr hostr;
  final SupportedEscrowContract contract;
  final EscrowService escrowService;

  final Map<String, TradeSnapshot> _trades = {};
  final _tradesSubject = BehaviorSubject<Map<String, TradeSnapshot>>.seeded({});

  StreamSubscription? _eventSub;
  StreamSubscription? _threadSub;

  EscrowMonitor({
    required this.hostr,
    required this.contract,
    required this.escrowService,
  });

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start listening to contract events and Nostr threads.
  void start() {
    _startContractListener();
    _startThreadListener();
    print('[monitor] Escrow monitor started');
  }

  /// Stop all subscriptions.
  Future<void> stop() async {
    await _eventSub?.cancel();
    await _threadSub?.cancel();
    _tradesSubject.close();
  }

  /// All tracked trades.
  Map<String, TradeSnapshot> get trades => Map.unmodifiable(_trades);

  /// Stream that emits whenever the trade map changes.
  ValueStream<Map<String, TradeSnapshot>> get trades$ => _tradesSubject.stream;

  /// Only pending (funded, unresolved) trades.
  List<TradeSnapshot> get pendingTrades =>
      _trades.values.where((t) => t.status == TradeStatus.funded).toList();

  /// Lookup a single trade.
  TradeSnapshot? getTrade(String tradeId) => _trades[tradeId];

  // ── Contract events ───────────────────────────────────────────────────────

  void _startContractListener() {
    final streamer = contract.allEvents(
      ContractEventsParams(
        arbiterEvmAddress: hostr.auth.getActiveEvmKey().address,
      ),
      null,
    );

    streamer.status.listen((status) {
      print('[monitor] Contract event stream status: $status');
    });

    _eventSub = streamer.stream.listen(
      _onEscrowEvent,
      onError: (e, st) => print('[monitor] Contract event error: $e'),
    );
  }

  void _onEscrowEvent(EscrowEvent event) {
    final now = DateTime.now();

    if (event is EscrowFundedEvent) {
      print('[monitor] Trade funded: ${event.tradeId}  '
          '${event.amount.getInSats} sats');
      _trades[event.tradeId] = TradeSnapshot(
        tradeId: event.tradeId,
        status: TradeStatus.funded,
        amountSats: event.amount.getInSats.toInt(),
        lastTxHash: event.transactionHash,
        updatedAt: now,
      );
    } else if (event is EscrowArbitratedEvent) {
      print('[monitor] Trade arbitrated: ${event.tradeId}  '
          'forwarded=${event.forwarded}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.arbitrated,
          lastTxHash: event.transactionHash,
          updatedAt: now,
        );
      }
    } else if (event is EscrowReleasedEvent) {
      print('[monitor] Trade released: ${event.tradeId}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.released,
          lastTxHash: event.transactionHash,
          updatedAt: now,
        );
      }
    } else if (event is EscrowClaimedEvent) {
      print('[monitor] Trade claimed: ${event.tradeId}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.claimed,
          lastTxHash: event.transactionHash,
          updatedAt: now,
        );
      }
    }

    _tradesSubject.add(_trades);
  }

  // ── Nostr thread messages ─────────────────────────────────────────────────

  void _startThreadListener() {
    hostr.messaging.threads.sync();
    _threadSub = hostr.messaging.threads.threadStream.listen(
      (thread) {
        print('[monitor] New/updated thread: ${thread.anchor}');
      },
      onError: (e) => print('[monitor] Thread stream error: $e'),
    );
  }
}
