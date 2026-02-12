import 'package:models/main.dart';

import '../messaging/thread.dart';

class MessagingListings {
  MessagingListings();

  static String getThreadListing({required Thread thread}) {
    ReservationRequest? r =
        (thread.messages.list.value.firstWhere((element) {
              return element.child is ReservationRequest;
            }).child
            as ReservationRequest);
    return r.listingAnchor;
  }
}
