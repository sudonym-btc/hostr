import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import 'trade_action_resolver.dart';

@injectable
class ReservationActions {
  final ThreadTrade trade;
  final Reservations reservations;

  ReservationActions({required this.trade, required this.reservations});

  static resolve(
    List<Reservation> reservations,
    StreamStatus reservationStreamStatus,
    Listing listing,
    List<String> participantPubkeys,
    ThreadPartyRole role,
  ) {
    final actions = <TradeAction>[];
    final reservationStatus = Reservation.getReservationStatus(
      reservations: reservations,
      listing: listing,
    );

    final hasUsedEscrow = reservations.any(
      (reservation) => reservation.parsedContent.proof?.escrowProof != null,
    );

    final hasTerminalReservationState =
        reservationStatus == ReservationStatus.cancelled ||
        reservationStatus == ReservationStatus.invalid ||
        reservationStatus == ReservationStatus.completed;

    final hasMessagedEscrow = participantPubkeys.any(
      (pubkey) => reservations.any(
        (reservation) =>
            reservation
                .parsedContent
                .proof
                ?.escrowProof
                ?.escrowService
                .parsedContent
                .pubkey ==
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
    final mine =
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
            .where((reservation) => reservation.pubKey == keyPair.publicKey)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mine.isEmpty) {
      throw Exception('No reservation found to cancel');
    }

    await reservations.cancel(mine.first, keyPair);
  }
}
