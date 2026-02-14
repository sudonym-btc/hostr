import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';

import 'guest_view.dart';

class ThreadReservationRequestHostViewWidget
    extends ThreadReservationRequestGuestHostComponents {
  ThreadReservationRequestHostViewWidget({
    required super.counterparty,
    required super.item,
    required super.listing,
    required super.reservations,
  });

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

  @override
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

  @override
  Widget statusText(BuildContext context) {
    switch (reservationStatus) {
      case ReservationRequestStatus.unpaid:
        return Text('Guest has not paid yet');
      case ReservationRequestStatus.unconfirmed:
        return Text(
          isSentByMe
              ? AppLocalizations.of(context)!.youSentReservationRequest
              : AppLocalizations.of(context)!.receivedReservationRequest,
          style: Theme.of(context).textTheme.bodyMedium!,
        );
      // case ReservationRequestStatus.pendingPublish:
      //   return Text('Waiting for host to confirm your booking');
      // case ReservationRequestStatus.confirmed:
      //   return Text('Confirmed by host');
      // case ReservationRequestStatus.refunded:
      //   return Text('Refunded by host');
      // case ReservationRequestStatus.unavailable:
      //   return Text('This booking is no longer available');
      default:
        return Container();
    }
  }

  Future<List<RelayBroadcastResponse>> accept(BuildContext context) {
    return context.read<Hostr>().reservations.accept(
      item,
      reservationRequest,
      counterparty.pubKey,
    );
  }
}
