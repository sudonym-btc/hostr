import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/listing/price.dart';
import 'package:models/main.dart';

import 'guest_view.dart';
import 'host_view.dart';

class ThreadReservationRequestWidget extends StatefulWidget {
  final Message item;
  final ProfileMetadata counterparty;
  final Listing listing;
  final List<Reservation> reservations;

  const ThreadReservationRequestWidget({
    super.key,
    required this.counterparty,
    required this.item,
    required this.listing,
    required this.reservations,
  });

  @override
  State<ThreadReservationRequestWidget> createState() =>
      _ThreadReservationRequestWidgetState();
}

class _ThreadReservationRequestWidgetState
    extends State<ThreadReservationRequestWidget> {
  ReservationRequest get reservationRequest =>
      widget.item.child as ReservationRequest;

  bool get isSentByMe => widget.item.pubKey == widget.counterparty.pubKey;

  ThreadReservationRequestGuestHostComponents get viewComponents =>
      widget.listing.pubKey != getIt<Hostr>().auth.activeKeyPair!.publicKey
      ? ThreadReservationRequestGuestViewWidget(
          counterparty: widget.counterparty,
          item: widget.item,
          listing: widget.listing,
          reservations: widget.reservations,
        )
      : ThreadReservationRequestHostViewWidget(
          counterparty: widget.counterparty,
          item: widget.item,
          listing: widget.listing,
          reservations: widget.reservations,
        );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        children: [
          ListingListItemWidget(
            listing: widget.listing,
            showPrice: false,
            showFeedback: false,
            smallImage: true,
          ),
          BlocProvider(
            create: (context) => getIt<Hostr>().paymentStatus.check(
              widget.listing,
              reservationRequest,
            ),
            child: Row(
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
                        formatDateRangeShort(
                          DateTimeRange(
                            start: reservationRequest.parsedContent.start,
                            end: reservationRequest.parsedContent.end,
                          ),
                          Localizations.localeOf(context),
                        ),
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
            ),
          ),
        ],
      ),
    );
  }
}
