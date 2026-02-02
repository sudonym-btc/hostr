import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../../payment/payment_method.dart';

abstract class ThreadReservationRequestGuestHostComponents {
  Widget actionButton(BuildContext context);
  Widget statusText(BuildContext context);
}

class ThreadReservationRequestGuestViewWidget
    implements ThreadReservationRequestGuestHostComponents {
  final Message item;
  final Metadata counterparty;
  final ReservationRequest reservationRequest;
  final Listing listing;
  final List<Reservation> reservations;
  final bool isSentByMe;
  final ReservationRequestStatus reservationStatus;

  ThreadReservationRequestGuestViewWidget({
    required this.counterparty,
    required this.item,
    required this.listing,
    required this.reservations,
  }) : reservationRequest = item.child as ReservationRequest,
       isSentByMe = item.child!.pubKey == counterparty.pubKey,
       reservationStatus = ReservationRequest.resolveStatus(
         request: item.child as ReservationRequest,
         listing: listing,
         reservations: reservations,
         threadAnchor: (item.child as ReservationRequest).id,
         paid: false,
         refunded: false,
       );

  pay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return PaymentMethodWidget(
          reservationRequest: reservationRequest,
          counterparty: counterparty,
          listing: listing,
        );
      },
    );
  }

  Widget actionButton(BuildContext context) {
    final action = ReservationRequest.resolveGuestAction(
      status: reservationStatus,
    );
    switch (action) {
      case ReservationRequestGuestAction.pay:
        return payButton(context);
      default:
        return Container();
    }
  }

  Widget statusText(BuildContext context) {
    switch (reservationStatus) {
      case ReservationRequestStatus.unconfirmed:
        return Text(
          isSentByMe
              ? AppLocalizations.of(context)!.youSentReservationRequest
              : AppLocalizations.of(context)!.receivedReservationRequest,
          style: Theme.of(context).textTheme.bodyMedium!,
        );
      case ReservationRequestStatus.pendingPublish:
        return Text('Waiting for host to confirm your booking');
      case ReservationRequestStatus.confirmed:
        return Text('Confirmed by host');
      case ReservationRequestStatus.refunded:
        return Text('Refunded by host');
      case ReservationRequestStatus.unavailable:
        return Text('This booking is no longer available');
    }
  }

  payButton(BuildContext context) {
    // todo check payment status here too
    return FilledButton(
      key: ValueKey('pay'),
      onPressed: () => pay(context),
      child: Text(AppLocalizations.of(context)!.pay),
    );
  }
}
