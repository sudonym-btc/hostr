import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:ndk/ndk.dart';

class ThreadReservationRequestWidget extends StatelessWidget {
  final GiftWrap item;
  final Metadata counterparty;

  const ThreadReservationRequestWidget(
      {super.key, required this.counterparty, required this.item});

  @override
  Widget build(BuildContext context) {
    ReservationRequest r = (item.child as Seal).child as ReservationRequest;

    bool isSentByMe = item.child.nip01Event.pubKey == counterparty.pubKey;

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
                      showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return CustomPadding(
                              child: Column(
                                children: [
                                  Text(
                                      'Would you like to use an escrow to settle this transfer?'),
                                  Row(
                                    children: [
                                      FilledButton(
                                          onPressed: () async {
                                            await getIt<SwapService>().escrow(
                                                amount: r.parsedContent.amount,
                                                eventId: r.nip01Event.id,
                                                timelock: DateTime.now()
                                                    .difference(
                                                        r.parsedContent.end)
                                                    .inMinutes,
                                                escrowContractAddress:
                                                    MOCK_ESCROWS[0]
                                                        .parsedContent
                                                        .contractAddress,
                                                sellerPubkey:
                                                    counterparty.pubKey,
                                                escrowPubkey: MOCK_ESCROWS[0]
                                                    .nip01Event
                                                    .pubKey);
                                          },
                                          child: Text('Pay Escrow ')),
                                      FilledButton(
                                          onPressed: () {
                                            BlocProvider.of<PaymentsManager>(
                                                    context)
                                                .create(LnUrlPaymentParameters(
                                                    to:
                                                        'paco@walletofsatoshi.com',
                                                    amount: Amount(
                                                        currency: Currency.BTC,
                                                        value: 0.00000001)));
                                          },
                                          child: Text('Pay Upfront'))
                                    ],
                                  )
                                ],
                              ),
                            );
                          });
                    },
                    child: Text('Pay'))
              ],
            )
          ])),
    );
  }
}
