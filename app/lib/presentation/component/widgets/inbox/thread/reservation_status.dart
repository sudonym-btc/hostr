import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/reservation/reservation_list_item.dart';
import 'package:models/main.dart';

class ReservationStatusWidget extends StatelessWidget {
  final List<Reservation> reservations;
  final Listing listing;
  const ReservationStatusWidget({
    super.key,
    required this.reservations,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return ListingListItemWidget(
        listing: listing,
        showPrice: false,
        showFeedback: false,
        smallImage: true,
      );
    }
    return ReservationListItem(reservations: reservations);
  }
}
