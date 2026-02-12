import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:models/main.dart';

class ReservationStatusWidget extends StatelessWidget {
  final Reservation? reservation;
  final Listing listing;
  const ReservationStatusWidget({
    super.key,
    this.reservation,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    if (reservation == null) {
      return ListingListItemWidget(
        listing: listing,
        showPrice: false,
        showFeedback: false,
        smallImage: true,
      );
    }
    return const SizedBox.shrink();
  }
}
