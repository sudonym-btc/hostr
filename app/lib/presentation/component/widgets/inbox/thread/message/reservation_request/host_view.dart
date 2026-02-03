import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/data/main.dart';
import 'package:models/main.dart';

import 'guest_view.dart';

class ThreadReservationRequestHostViewWidget
    implements ThreadReservationRequestGuestHostComponents {
  final Message item;
  final ProfileMetadata counterparty;
  final ReservationRequest reservationRequest;
  final Listing listing;
  final List<Reservation> reservations;
  final bool isSentByMe;
  final ReservationRequestStatus reservationStatus;

  ThreadReservationRequestHostViewWidget({
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
         threadAnchor: (item.child as ReservationRequest).anchor!,
         paid: false,
         refunded: false,
       );

  Widget acceptButton(BuildContext context) {
    return FilledButton(
      key: ValueKey('accept'),
      onPressed: () => accept(context),
      child: Text(AppLocalizations.of(context)!.accept),
    );
  }

  Widget refundButton(BuildContext context) {
    return FilledButton(
      key: ValueKey('refund'),
      onPressed: () => {},
      // onPressed: () => accept(context),
      child: Text(AppLocalizations.of(context)!.refund),
    );
  }

  Widget actionButton(BuildContext context) {
    final action = ReservationRequest.resolveHostAction(
      status: reservationStatus,
    );
    switch (action) {
      case ReservationRequestHostAction.accept:
        return acceptButton(context);
      case ReservationRequestHostAction.refund:
        return refundButton(context);
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

  accept(BuildContext context) {
    return context.read<Hostr>().reservations.accept(
      item,
      reservationRequest,
      counterparty.pubKey,
    );
  }
}
