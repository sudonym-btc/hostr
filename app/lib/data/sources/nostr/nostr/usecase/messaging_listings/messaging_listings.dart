import 'package:models/main.dart';

import '../messaging/thread.dart';

class MessagingListings {
  MessagingListings();

  static String getThreadListing({required Thread thread}) {
    ReservationRequest? r =
        (thread.messages.firstWhere((element) {
              return element.child is ReservationRequest;
            }).child
            as ReservationRequest);
    if (r == null) throw Exception('Thread had to reservation requests');
    return r.listingAnchor;
  }
}
