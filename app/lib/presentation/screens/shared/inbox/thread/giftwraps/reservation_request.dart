import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../payment/payment_method.dart';

class ThreadReservationRequestWidget extends StatelessWidget {
  final Message item;
  final Metadata counterparty;
  final ReservationRequest r;
  final bool isSentByMe;

  ThreadReservationRequestWidget({
    super.key,
    required this.counterparty,
    required this.item,
  }) : r = item.child as ReservationRequest,
       isSentByMe = item.child!.pubKey == counterparty.pubKey;

  pay(BuildContext context, Listing listing) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return PaymentMethodWidget(
          reservationRequest: r,
          counterparty: counterparty,
          listing: listing,
        );
      },
    );
  }

  accept(BuildContext context, Listing l) {
    // KeyPair k = getIt<KeyStorage>().getActiveKeyPairSync()!;
    // context.read<EventPublisherCubit>().publishEvents([
    //   Nip01Event(
    //     pubKey: k.publicKey,
    //     kind: NOSTR_KIND_RESERVATION,
    //     tags: [
    //       ['a', l.anchor, context.read<ThreadCubit>().getAnchor()],
    //       // ['c', context.read<ThreadCubit>().getAnchor()]
    //     ],
    //     content: json.encode(
    //       ReservationContent(
    //         start: r.parsedContent.start,
    //         end: r.parsedContent.end,
    //       ).toJson(),
    //     ),
    //   )..sign(k.privateKey!),
    // ]);
  }

  Widget paymentStatus(BuildContext contex, Listing l) {
    return StreamBuilder(
      stream: getIt<Hostr>().payments.checkPaymentStatus(l, r),
      builder: (context, snapshot) {
        return Text('Payment status: ${snapshot.data}');
      },
    );
  }

  Widget actionButton(BuildContext context, Listing l) {
    if (l.pubKey == getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey) {
      return Container();
      // return StreamBuilder(
      //   stream: context.read<ThreadCubit>().loadBookingState(),
      //   builder: (context, state) {
      //     if (state.data == null) {
      //       return BlocProvider<EventPublisherCubit>(
      //         create: (context) =>
      //             EventPublisherCubit(nostrService: getIt(), workflow: getIt()),
      //         child: BlocBuilder<EventPublisherCubit, EventPublisherState>(
      //           builder: (context, state) => FilledButton(
      //             key: ValueKey('accept'),
      //             onPressed: () => accept(context, l),
      //             child: Text(
      //               isSentByMe
      //                   ? AppLocalizations.of(context)!.reserve
      //                   : AppLocalizations.of(context)!.accept,
      //             ),
      //           ),
      //         ),
      //       );
      //     }
      //     return FilledButton(
      //       onPressed: null,
      //       child: Text(AppLocalizations.of(context)!.accepted),
      //     );
      //   },
      // );
    }

    // todo check payment status here too
    return FilledButton(
      key: ValueKey('pay'),
      onPressed: () => pay(context, l),
      child: Text(AppLocalizations.of(context)!.pay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EntityCubit<Listing>, EntityCubitState<Listing>>(
      builder: (context, listingState) {
        if (listingState.data == null) {
          return CircularProgressIndicator();
        }
        return Align(
          alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            children: [
              ListingListItemWidget(
                listing: listingState.data!,
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
                          '${formatDateShort(r.parsedContent.start, context)} - ${formatDateShort(r.parsedContent.end, context)}',
                          style: Theme.of(context).textTheme.bodyMedium!,
                        ),
                        Text(formatAmount(r.parsedContent.amount)),
                        paymentStatus(context, listingState.data!),
                      ],
                    ),
                  ),
                  CustomPadding(
                    top: 0,
                    child: actionButton(context, listingState.data!),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
