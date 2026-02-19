import 'package:models/main.dart';

import 'actions/trade_action_resolver.dart';

class TradeState {
  final String tradeId;
  final DateTime start;
  final DateTime end;
  final String salt;
  final Amount amount;
  final bool active;
  final bool runtimeReady;
  final Listing? listing;
  final ProfileMetadata? listingProfile;
  final ThreadPartyRole? role;
  final List<TradeAction> availableActions;
  final bool? isBlocked;
  final String? blockedReason;

  const TradeState({
    required this.tradeId,
    required this.start,
    required this.end,
    required this.salt,
    required this.amount,
    required this.active,
    required this.runtimeReady,
    required this.role,
    required this.availableActions,
    this.listing,
    this.listingProfile,
    required this.isBlocked,
    required this.blockedReason,
  });

  factory TradeState.initial({
    required String tradeId,
    required DateTime start,
    required DateTime end,
    required String salt,
    required Amount amount,
  }) {
    return TradeState(
      tradeId: tradeId,
      start: start,
      end: end,
      salt: salt,
      amount: amount,
      active: false,
      runtimeReady: false,
      role: null,
      availableActions: const [],
      listing: null,
      listingProfile: null,
      isBlocked: null,
      blockedReason: null,
    );
  }

  TradeState copyWith({
    bool? active,
    bool? runtimeReady,
    ThreadPartyRole? role,
    List<TradeAction>? availableActions,
    Listing? listing,
    ProfileMetadata? listingProfile,
    Amount? amount,
    bool? isBlocked,
    String? blockedReason,
  }) {
    return TradeState(
      tradeId: tradeId,
      start: start,
      end: end,
      salt: salt,
      amount: amount ?? this.amount,
      active: active ?? this.active,
      runtimeReady: runtimeReady ?? this.runtimeReady,
      role: role ?? this.role,
      availableActions: availableActions ?? this.availableActions,
      listing: listing ?? this.listing,
      listingProfile: listingProfile ?? this.listingProfile,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedReason: blockedReason ?? this.blockedReason,
    );
  }
}
