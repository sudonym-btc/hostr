import 'package:models/main.dart';

import '../messaging/thread.dart';

class MessagingListings {
  MessagingListings();

  static String getThreadListing({required Thread thread}) {
    return (thread.messages.firstWhere((element) {
              return element.child is ReservationRequest;
            }).child
            as ReservationRequest)
        .listingAnchor;
  }
}
