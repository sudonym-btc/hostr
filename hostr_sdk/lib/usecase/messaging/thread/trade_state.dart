import 'package:models/main.dart';

/// Lifecycle state for a trade. Only holds mutable signals about the trade's
/// activity status. Context (listing, role) lives in [TradeContext] on
/// [ThreadTrade.context$], and available actions live in [ThreadTrade.actions$].
class TradeState {
  final String tradeId;
  final DateTime start;
  final DateTime end;
  final Amount? amount;
  final bool active;
  final bool runtimeReady;

  const TradeState({
    required this.tradeId,
    required this.start,
    required this.end,
    required this.amount,
    required this.active,
    required this.runtimeReady,
  });

  factory TradeState.initial({
    required String tradeId,
    required DateTime start,
    required DateTime end,
    required Amount? amount,
  }) {
    return TradeState(
      tradeId: tradeId,
      start: start,
      end: end,
      amount: amount,
      active: false,
      runtimeReady: false,
    );
  }

  TradeState copyWith({bool? active, bool? runtimeReady, Amount? amount}) {
    return TradeState(
      tradeId: tradeId,
      start: start,
      end: end,
      amount: amount ?? this.amount,
      active: active ?? this.active,
      runtimeReady: runtimeReady ?? this.runtimeReady,
    );
  }
}
