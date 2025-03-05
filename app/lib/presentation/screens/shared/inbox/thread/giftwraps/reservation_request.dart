import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class ThreadReservationRequestWidget extends StatelessWidget {
  final Message item;
  final Metadata counterparty;
  final ReservationRequest r;
  final bool isSentByMe;

  ThreadReservationRequestWidget(
      {super.key, required this.counterparty, required this.item})
      : r = item.child as ReservationRequest,
        isSentByMe = item.child!.nip01Event.pubKey == counterparty.pubKey;

  pay(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
              child: CustomPadding(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                    style: Theme.of(context).textTheme.titleLarge!,
                    'Would you like to use an escrow to settle this transfer?'),
                CustomPadding(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: FilledButton(
                            onPressed: () async {
                              Navigator.of(context).pop();

                              await getIt<SwapService>().escrow(
                                  amount: r.parsedContent.amount,
                                  eventId: r.nip01Event.id,
                                  timelock: DateTime.now()
                                      .difference(r.parsedContent.end)
                                      .inMinutes,
                                  escrowContractAddress: MOCK_ESCROWS[0]
                                      .parsedContent
                                      .contractAddress,
                                  sellerPubkey: counterparty.pubKey,
                                  escrowPubkey:
                                      MOCK_ESCROWS[0].nip01Event.pubKey);
                            },
                            child: Text('Use Escrow'))),
                    CustomPadding(),
                    Expanded(
                        child: FilledButton(
                            key: ValueKey('pay_upfront'),
                            onPressed: () {
                              Navigator.of(context).pop();

                              BlocProvider.of<PaymentsManager>(context).create(
                                  LnUrlPaymentParameters(
                                      to: 'paco@walletofsatoshi.com',
                                      amount: r.parsedContent.amount));
                            },
                            child: Text('Pay Upfront')))
                  ],
                )
              ],
            ),
          ));
        });
  }

  accept(BuildContext context, Listing l) {
    KeyPair k = getIt<KeyStorage>().getActiveKeyPairSync()!;
    context.read<EventPublisherCubit>().publishEvents([
      Nip01Event(
          pubKey: k.publicKey,
          kind: NOSTR_KIND_RESERVATION,
          tags: [
            ['a', l.anchor, context.read<ThreadCubit>().getAnchor()],
            // ['c', context.read<ThreadCubit>().getAnchor()]
          ],
          content: json.encode(ReservationContent(
                  start: r.parsedContent.start, end: r.parsedContent.end)
              .toJson()))
        ..sign(k.privateKey!)
    ]);
  }

  Widget paymentStatus() {
    /// Look up the payment state by hashing the reservation request id
    /// Combine with escrow query as well
    return FutureBuilder(
        future: getIt<NwcService>().lookupInvoice(
            paymentHash:
                crypto.sha256.convert(r.nip01Event.id.codeUnits).toString()),
        builder: (context, snapshot) {
          return Text(
              'Payment status: ${snapshot.data?.settledAt == null ? 'unconfirmed' : 'paid'}');
        });
  }

  Widget actionButton(BuildContext context, Listing l) {
    if (l.nip01Event.pubKey ==
        getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey) {
      return StreamBuilder(
          stream: context.read<ThreadCubit>().loadBookingState(),
          builder: (context, state) {
            if (state.data == null) {
              return BlocProvider<EventPublisherCubit>(
                  create: (context) => EventPublisherCubit(),
                  child: BlocBuilder<EventPublisherCubit, EventPublisherState>(
                    builder: (context, state) => FilledButton(
                        key: ValueKey('accept'),
                        onPressed: () => accept(context, l),
                        child: Text(isSentByMe ? 'Reserve' : 'Accept')),
                  ));
            }
            return FilledButton(
              onPressed: null,
              child: Text('Accepted'),
            );
          });
    }

    // todo check payment status here too
    return FilledButton(
        key: ValueKey('pay'),
        onPressed: () => pay(context),
        child: Text('Pay'));
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
          child: Column(children: [
            ListingListItemWidget(
                listing: listingState.data!,
                showPrice: false,
                showFeedback: false,
                smallImage: true),
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
                                    ? 'You sent a reservation request'
                                    : 'Received reservation offer',
                                style: Theme.of(context).textTheme.bodyMedium!),
                            Text(
                                '${formatDateShort(r.parsedContent.start, context)} - ${formatDateShort(r.parsedContent.end, context)}',
                                style: Theme.of(context).textTheme.bodyMedium!),
                            Text(formatAmount(r.parsedContent.amount)),
                            paymentStatus()
                          ])),
                  CustomPadding(
                      top: 0, child: actionButton(context, listingState.data!))
                ])
          ]));
    });
  }
}
