import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import 'trade_action_resolver.dart';

@injectable
class ReservationRequestActions {
  final ThreadTrade trade;

  ReservationRequestActions({required this.trade});

  static List<TradeAction> resolve(
    List<ReservationRequest> reservationRequests,
    Listing listing,
    String ourPubkey,
    ThreadPartyRole role,
  ) {
    final actions = <TradeAction>[];
    final lastRequest = reservationRequests.isNotEmpty
        ? reservationRequests.last
        : null;
    final lastRequestSentByUs = lastRequest?.pubKey == ourPubkey;
    final enoughPrice = lastRequest != null
        ? listing
                  .cost(
                    lastRequest.parsedContent.start,
                    lastRequest.parsedContent.end,
                  )
                  .value <=
              lastRequest.parsedContent.amount.value
        : false;
    if (role == ThreadPartyRole.guest) {
      actions.addAll([
        if (!lastRequestSentByUs || enoughPrice) TradeAction.pay,
      ]);
    }
    if (!lastRequestSentByUs && listing.parsedContent.allowBarter) {
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
