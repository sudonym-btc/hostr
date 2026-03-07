import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../../../util/main.dart';
import '../../../reservations/reservations.dart';
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
    List<String> participantPubkeys,
    TradeRole role, {
    List<Reservation>? allReservations,
  }) {
    final actions = <TradeAction>[];
    final reservationStatus = Reservation.getReservationStatus(
      reservations: reservations,
    );

    // Use allReservations (includes cancelled) for escrow checks,
    // so messageEscrow is available even after cancellation.
    final escrowReservations = allReservations ?? reservations;

    final hasUsedEscrow = escrowReservations.any(
      (reservation) => reservation.proof?.escrowProof != null,
    );

    final hasTerminalReservationState =
        reservationStatus == ReservationStatus.cancelled ||
        reservationStatus == ReservationStatus.invalid ||
        reservationStatus == ReservationStatus.completed;

    final hasMessagedEscrow = participantPubkeys.any(
      (pubkey) => escrowReservations.any(
        (reservation) =>
            reservation.proof?.escrowProof?.escrowService.escrowPubkey ==
            pubkey,
      ),
    );

    if (!hasTerminalReservationState) {
      actions.add(TradeAction.cancel);
    }

    if (!hasMessagedEscrow && hasUsedEscrow) {
      actions.add(TradeAction.messageEscrow);
    }

    return actions;
  }

  Future<void> cancel() async {
    final keyPair = await trade.activeKeyPair();
    final r =
        trade.subscriptions.reservationStream!.list.value
            .whereType<Valid<ReservationPairStatus>>()
            .where((validation) => !validation.event.cancelled)
            .expand(
              (validation) => [
                validation.event.sellerReservation,
                validation.event.buyerReservation,
              ],
            )
            .whereType<Reservation>()
            .toList()
          ..sort((a, b) {
            final aMatch = a.pubKey == keyPair.publicKey ? 0 : 1;
            final bMatch = b.pubKey == keyPair.publicKey ? 0 : 1;
            if (aMatch != bMatch) return aMatch.compareTo(bMatch);
            return b.createdAt.compareTo(a.createdAt);
          });

    await reservations.cancel(r.first, keyPair);
  }
}
