import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/listing/price.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../payment/payment_method.dart';

class ThreadReservationRequestWidget extends StatelessWidget {
  final Message item;
  final Metadata counterparty;
  final ReservationRequest reservationRequest;
  final Listing listing;
  final List<Reservation> reservations;
  final bool isSentByMe;

  ThreadReservationRequestWidget({
    super.key,
    required this.counterparty,
    required this.item,
    required this.listing,
    required this.reservations,
  }) : reservationRequest = item.child as ReservationRequest,
       isSentByMe = item.child!.pubKey == counterparty.pubKey;

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

  accept(BuildContext context) {
    return context.read<Hostr>().reservations.accept(
      item,
      reservationRequest,
      counterparty.pubKey,
    );
  }

  Widget paymentStatus(BuildContext context) {
    ReservationRequest.canAttemptPay(
      listing: listing,
      request: reservationRequest,
      ourKey: getIt<Hostr>().auth.activeKeyPair!,
    );
    ReservationRequest.isAvailableForReservation(
      reservationRequest: reservationRequest,
      reservations: reservations,
    );
    return StreamBuilder(
      stream: getIt<Hostr>().payments.checkPaymentStatus(
        listing,
        reservationRequest,
      ),
      builder: (context, snapshot) {
        return Text('Payment status: ${snapshot.data}');
      },
    );
  }

  Widget actionButton(BuildContext context) {
    final reservationStatus = ReservationRequest.getStatus(
      anchor: item.threadAnchor!,
      reservations: reservations,
      listing: listing,
      ourKey: getIt<Hostr>().auth.activeKeyPair!,
    );
    switch (reservationStatus) {
      case ReservationStatus.pending:
        if (isSentByMe) {
          return payButton(context);
        } else {
          return FilledButton(
            key: ValueKey('accept'),
            onPressed: () => accept(context),
            child: Text(AppLocalizations.of(context)!.accept),
          );
        }
      case ReservationStatus.accepted:
        return payButton(context);
      case ReservationStatus.completed:
        return Text('completed');
      default:
        return Container();
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

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        children: [
          ListingListItemWidget(
            listing: listing,
            showPrice: false,
            showFeedback: false,
            smallImage: true,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomPadding(
                right: 0,
                top: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSentByMe
                          ? AppLocalizations.of(
                              context,
                            )!.youSentReservationRequest
                          : AppLocalizations.of(
                              context,
                            )!.receivedReservationRequest,
                      style: Theme.of(context).textTheme.bodyMedium!,
                    ),
                    Text(
                      '${formatDateShort(reservationRequest.parsedContent.start, context)} - ${formatDateShort(reservationRequest.parsedContent.end, context)}',
                      style: Theme.of(context).textTheme.bodyMedium!,
                    ),
                    PriceText(
                      formatAmount(reservationRequest.parsedContent.amount),
                    ),
                    // paymentStatus(context, listing),
                  ],
                ),
              ),
              CustomPadding(top: 0, child: actionButton(context)),
            ],
          ),
        ],
      ),
    );
  }
}
