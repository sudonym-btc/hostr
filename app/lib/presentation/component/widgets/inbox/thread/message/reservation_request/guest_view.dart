import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment_method/payment_method.dart';
import 'package:models/main.dart';

import 'payment_status_cubit.dart';

abstract class ThreadReservationRequestGuestHostComponents {
  Widget actionButton(BuildContext context);
  Widget statusText(BuildContext context);
}

class ThreadReservationRequestGuestViewWidget
    implements ThreadReservationRequestGuestHostComponents {
  final Message item;
  final ProfileMetadata counterparty;
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
         threadAnchor: (item.child as ReservationRequest).anchor!,
         paid: false,
         refunded: false,
       );

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

    // getIt<Hostr>().reservations.createSelfSigned(
    //   threadId: item.threadAnchor,
    //   reservationRequest: reservationRequest,
    //   listing: listing,
    //   hoster: counterparty,
    //   zapProof: null,
    //   escrowProof: EscrowProof(
    //     method: 'EVM',
    //     chainId: (await chain.client.getChainId()).toString(),
    //     txHash: escrowCompleted.txHash,
    //     hostsTrustedEscrows: escrows.hostTrust,
    //     hostsEscrowMethods: escrows.hostMethod,
    //   ),
    // );

    // @Todo: ideally would create a transaction listener on all chains we can handle and then automatically trigger self-signed. Don't want to rely on escrow call completing as app might go into background.
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

  Widget payButton(BuildContext context) {
    return BlocBuilder<PaymentStatusCubit, PaymentStatusCubitState>(
      builder: (context, state) {
        switch (state) {
          case PaymentStatusCubitDone():
            // todo check payment status here too
            return FilledButton(
              key: ValueKey('pay'),
              onPressed: () => pay(context),
              child: Text(AppLocalizations.of(context)!.pay),
            );
          case PaymentStatusCubitPaid():
            return Text('Paid');
          default:
            return CircularProgressIndicator();
        }
      },
    );
  }
}
