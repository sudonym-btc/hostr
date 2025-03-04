import 'package:auto_route/auto_route.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/router.dart';
import 'package:ndk/ndk.dart';

class Reserve extends StatelessWidget {
  final Listing listing;
  const Reserve({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateRangeCubit, DateRangeState>(
        builder: (context, dateState) => BlocProvider<EventPublisherCubit>(
            create: (context) => EventPublisherCubit(),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  dateState.dateRange != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatAmount(
                                listing.cost(dateState.dateRange!))),
                            Text(
                                '${formatDate(dateState.dateRange!.start)} - ${formatDate(dateState.dateRange!.end)}')
                          ],
                        )
                      : GestureDetector(
                          child: Text('Select dates'),
                          onTap: () => selectDates(
                              context, context.read<DateRangeCubit>()),
                        ),
                  BlocBuilder<EventPublisherCubit, EventPublisherState>(
                      builder: (context, state) {
                    return FilledButton(
                        onPressed: dateState.dateRange == null
                            ? null
                            : () async {
                                ReservationRequest req = ReservationRequest
                                    .fromNostrEvent(Nip01Event(
                                        kind: NOSTR_KIND_RESERVATION_REQUEST,
                                        tags: [
                                          ['a', MOCK_LISTINGS[0].anchor],
                                        ],
                                        content: ReservationRequestContent(
                                                start: DateTime.now(),
                                                end: DateTime.now()
                                                    .add(Duration(days: 1)),
                                                quantity: 1,
                                                amount: listing
                                                    .cost(dateState.dateRange!),
                                                commitmentHash: 'hash',
                                                commitmentHashPreimageEnc:
                                                    'does')
                                            .toString(),
                                        pubKey: MockKeys.hoster.publicKey)
                                      ..sign(MockKeys.hoster.privateKey!));
                                final id =
                                    '${listing.anchor}/${crypto.sha256.convert(req.toString().codeUnits).bytes}';
                                Nip01Event msg = Nip01Event(
                                    pubKey: MockKeys.hoster.publicKey,
                                    kind: NOSTR_KIND_DM,
                                    tags: [
                                      ['a', id],
                                      [
                                        'p',
                                        MockKeys.guest.publicKey,
                                      ]
                                    ],
                                    content: req.toString());
                                await context
                                    .read<EventPublisherCubit>()
                                    .publishEvents([
                                  giftWrapAndSeal(
                                          listing.nip01Event.pubKey,
                                          getIt<KeyStorage>()
                                              .getActiveKeyPairSync()!,
                                          msg,
                                          null)
                                      .nip01Event,
                                  giftWrapAndSeal(
                                          getIt<KeyStorage>()
                                              .getActiveKeyPairSync()!
                                              .publicKey,
                                          getIt<KeyStorage>()
                                              .getActiveKeyPairSync()!,
                                          msg,
                                          null)
                                      .nip01Event,
                                ]);

                                AutoRouter.of(context)
                                    .push(ThreadRoute(id: id));
                              },
                        child: Text('Reserve'));
                  }),
                ])));
  }
}

selectDates(BuildContext context, DateRangeCubit dateRangeCubit) async {
  final picked = await showDateRangePicker(
      builder: (context, child) {
        return Theme(
          data: Theme.of(context), // Reset to default light theme
          child: child!,
        );
      },
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),

      /// Testing blocked days
      selectableDayPredicate:
          (day, DateTime? selectedStartDay, DateTime? selectedEndDay) =>
              day.isAfter(DateTime.now()),
      initialDateRange: dateRangeCubit.state.dateRange);
  dateRangeCubit.updateDateRange(picked);
}
