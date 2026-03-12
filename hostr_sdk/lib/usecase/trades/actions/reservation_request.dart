import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../trade.dart';
import 'trade_action_resolver.dart';

@injectable
class ReservationRequestActions {
  final Trade trade;

  ReservationRequestActions({required this.trade});

  static List<TradeAction> resolve(
    List<Reservation> reservationRequests,
    Listing listing,
    String ourPubkey,
    TradeRole role,
  ) {
    final actions = <TradeAction>[];
    final lastRequest = reservationRequests.isNotEmpty
        ? reservationRequests.last
        : null;
    print(
      'Resolving reservation request actions with last request: $lastRequest',
    );
    final lastRequestSentByUs = lastRequest?.pubKey == ourPubkey;
    final enoughPrice = lastRequest != null && lastRequest.amount != null
        ? listing.cost(lastRequest.start, lastRequest.end).value <=
              lastRequest.amount!.value
        : false;
    if (role == TradeRole.guest) {
      actions.addAll([
        if (!lastRequestSentByUs || enoughPrice) TradeAction.pay,
      ]);
    }
    if (!lastRequestSentByUs && listing.allowBarter) {
      actions.add(TradeAction.counter);
    }

    return actions;
  }

  Future<void> counter() async {
    throw UnimplementedError(
      'Countering reservation requests is not implemented yet',
    );
  }
}
