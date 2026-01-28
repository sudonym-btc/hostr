import 'package:models/main.dart';

import '../messaging/thread.dart';

class MessagingListings {
  MessagingListings();

  static String getThreadListing({required Thread thread}) {
    return thread.messages
        .where((element) {
          return element.child is ReservationRequest;
        })
        .map((e) => e.child!.anchor)
        .first;
  }
}
