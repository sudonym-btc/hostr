import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment_method/payment_method.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

abstract class ThreadReservationRequestGuestHostComponents {
  final Message item;
  final ProfileMetadata counterparty;
  final Listing listing;
  final List<Reservation> reservations;

  ReservationRequestStatus get reservationStatus =>
      ReservationRequest.resolveStatus(
        request: reservationRequest,
        listing: listing,
        reservations: reservations,
        threadAnchor: reservationRequest.anchor!,
        paid: false,
        refunded: false,
      );

  ReservationRequest get reservationRequest => item.child as ReservationRequest;
  bool get isSentByMe =>
      reservationRequest.pubKey == getIt<Hostr>().auth.activeKeyPair?.publicKey;

  const ThreadReservationRequestGuestHostComponents({
    required this.counterparty,
    required this.item,
    required this.listing,
    required this.reservations,
  });

  Widget actionButton(BuildContext context);
  Widget statusText(BuildContext context);
}

class ThreadReservationRequestGuestViewWidget
    extends ThreadReservationRequestGuestHostComponents {
  const ThreadReservationRequestGuestViewWidget({
    required super.counterparty,
    required super.item,
    required super.listing,
    required super.reservations,
  });

  Future<void> pay(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return PaymentMethodWidget(
          counterparty: counterparty,
          reservationRequest: reservationRequest,
        );
      },
    );
  }

  @override
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

  @override
  Widget statusText(BuildContext context) {
    switch (reservationStatus) {
      case ReservationRequestStatus.unavailable:
        return Text('This booking is no longer available');
      case ReservationRequestStatus.unpaid:
      default:
        return Text(
          isSentByMe
              ? AppLocalizations.of(context)!.youSentReservationRequest
              : AppLocalizations.of(context)!.receivedReservationRequest,
          style: Theme.of(context).textTheme.bodyMedium!,
        );
      // case ReservationRequestStatus.unconfirmed:
      //   return Text(
      //     'Waiting for host to confirm',
      //     style: Theme.of(context).textTheme.bodyMedium!,
      //   );
      // case ReservationRequestStatus.pendingPublish:
      //   return Text('Waiting for host to confirm your booking');
      // case ReservationRequestStatus.confirmed:
      //   return Text('Confirmed by host');
      // case ReservationRequestStatus.refunded:
      //   return Text('Refunded by host');
      // default:
      //   return Container();
    }
  }

  Widget payButton(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        switch (state.paymentEventsStreamStatus) {
          case StreamStatusError():
            return Text(
              (state.paymentEventsStreamStatus as StreamStatusError).error
                  .toString(),
            );
          case StreamStatusLive():
            return state.paymentEvents.isEmpty
                ? FilledButton(
                    key: ValueKey('pay'),
                    onPressed: () => pay(context),
                    child: Text(AppLocalizations.of(context)!.pay),
                  )
                : Container();
          default:
            return CircularProgressIndicator();
        }
      },
    );
  }
}
