import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../../util/main.dart';
import '../../reservations/reservations.dart';
import '../trade.dart';
import 'trade_action_resolver.dart';

@injectable
class ReservationActions {
  final Trade trade;
  final Reservations reservations;

  ReservationActions({required this.trade, required this.reservations});

  static List<TradeAction> resolve(
    List<Reservation> reservations,
    StreamStatus reservationStreamStatus,
    TradeRole role, {
    List<Reservation>? allReservations,
  }) {
    final actions = <TradeAction>[];
    final reservationStatus = Reservation.getReservationStatus(
      reservations: reservations,
    );

    final escrowReservations = allReservations ?? reservations;

    final hasUsedEscrow = escrowReservations.any(
      (reservation) =>
          reservation.proof?.escrowProof != null ||
          reservation.parsedTags.getTagValueByMarker('p', 'escrow') != null,
    );

    final hasTerminalReservationState =
        reservationStatus == ReservationStatus.cancelled ||
        reservationStatus == ReservationStatus.invalid ||
        reservationStatus == ReservationStatus.completed;
    if (!hasTerminalReservationState) {
      actions.add(TradeAction.cancel);
    }

    if (hasUsedEscrow) {
      actions.add(TradeAction.messageEscrow);
    }

    return actions;
  }

  Future<void> cancel() async {
    final keyPair = await trade.activeKeyPair();

    await reservations.cancel(
      trade.currentReservationGroups
          .whereType<Valid<ReservationGroup>>()
          .first
          .event,
      keyPair,
    );
  }
}
