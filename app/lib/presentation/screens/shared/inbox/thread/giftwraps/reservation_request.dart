import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';

class ThreadReservationRequestWidget extends StatelessWidget {
  final String counterpartyPubkey;
  // final GiftWrap<Seal<ReservationRequest>> item;
  final GiftWrap item;

  const ThreadReservationRequestWidget(
      {super.key, required this.counterpartyPubkey, required this.item});

  @override
  Widget build(BuildContext context) {
    ReservationRequest r = (item.child as Seal).child as ReservationRequest;

    bool isSentByMe = item.child.pubkey == counterpartyPubkey;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color:
                isSentByMe ? Theme.of(context).primaryColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isSentByMe
                  ? 'Sent reservation request'
                  : 'Received reservation request',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: isSentByMe ? Colors.white : Colors.black,
                  ),
            ),
            Text(
                '${formatDateShort(r.parsedContent.start, context)} - ${formatDateShort(r.parsedContent.end, context)}',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: isSentByMe ? Colors.white : Colors.black,
                    )),
            Row(
              children: [
                FilledButton(
                    onPressed: () {
                      BlocProvider.of<PaymentsManager>(context).create(
                          LnUrlPaymentParameters(
                              to: 'paco@walletofsatoshi.com',
                              amount: Amount(
                                  currency: Currency.BTC, value: 0.00000001)));
                    },
                    child: Text('Pay'))
              ],
            )
          ])),
    );
  }
}
