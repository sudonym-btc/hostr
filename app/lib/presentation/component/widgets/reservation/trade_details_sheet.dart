import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import 'trade_timeline.dart';

void showTradeDetailsSheet(BuildContext context, TradeReady tradeState) {
  final trade = context.read<Trade>();
  showAppModal(
    context,
    builder: (_) => StreamBuilder<dynamic>(
      stream: Rx.merge([
        trade.transitions$.stream.map((_) => null),
        trade.payments$.stream.map((_) => null),
        trade.reservationGroup$.stream.map((_) => null),
      ]),
      initialData: null,
      builder: (context, _) {
        final transitions = trade.transitions$.items;
        final paymentEvents = trade.payments$.items;
        final reservationValidation = trade.reservationGroup$.items.lastOrNull;
        final reservationGroup = reservationValidation?.event;

        return ModalBottomSheet(
          title: 'Information',
          content: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TradeTimeline(
                    transitions: transitions,
                    paymentEvents: paymentEvents,
                    reservationGroup: reservationGroup,
                  ),
                  if (reservationValidation is Invalid<ReservationGroup>) ...[
                    Gap.vertical.lg(),
                    _ReservationRecords(
                      validatedReservationGroup: reservationValidation,
                      listing: tradeState.listing,
                      sellerPubkey: tradeState.sellerPubkey,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _ReservationRecords extends StatelessWidget {
  final Validation<ReservationGroup> validatedReservationGroup;
  final Listing listing;
  final String sellerPubkey;

  const _ReservationRecords({
    required this.validatedReservationGroup,
    required this.listing,
    required this.sellerPubkey,
  });

  @override
  Widget build(BuildContext context) {
    final pair = validatedReservationGroup;
    if (pair is Invalid<ReservationGroup>) {
      final reason = pair.reason;
      return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reservation errors',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Gap.vertical.xs(),
          Text(reason),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
