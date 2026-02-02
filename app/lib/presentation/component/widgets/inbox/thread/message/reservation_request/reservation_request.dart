import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/listing/price.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'guest_view.dart';
import 'host_view.dart';

class ThreadReservationRequestWidget extends StatelessWidget {
  final Message item;
  final Metadata counterparty;
  final ReservationRequest reservationRequest;
  final Listing listing;
  final List<Reservation> reservations;
  final bool isSentByMe;
  late final ThreadReservationRequestGuestHostComponents viewComponents;

  ThreadReservationRequestWidget({
    super.key,
    required this.counterparty,
    required this.item,
    required this.listing,
    required this.reservations,
  }) : reservationRequest = item.child as ReservationRequest,
       isSentByMe = item.child!.pubKey == counterparty.pubKey,
       viewComponents =
           listing.pubKey != getIt<Hostr>().auth.activeKeyPair!.publicKey
           ? ThreadReservationRequestGuestViewWidget(
               counterparty: counterparty,
               item: item,
               listing: listing,
               reservations: reservations,
             )
           : ThreadReservationRequestHostViewWidget(
               counterparty: counterparty,
               item: item,
               listing: listing,
               reservations: reservations,
             );
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
          StreamBuilder(
            stream: getIt<Hostr>().payments.checkPaymentStatus(
              listing,
              reservationRequest,
            ),
            builder: (context, snapshot) {
              return Row(
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
                          '${formatDateShort(reservationRequest.parsedContent.start, context)} - ${formatDateShort(reservationRequest.parsedContent.end, context)}',
                          style: Theme.of(context).textTheme.bodyMedium!,
                        ),
                        PriceText(
                          formatAmount(reservationRequest.parsedContent.amount),
                        ),
                        viewComponents.statusText(context),
                      ],
                    ),
                  ),
                  CustomPadding(
                    top: 0,
                    child: viewComponents.actionButton(context),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
