import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart'
    show ThreadCubitState, ThreadCubit;
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/reservation/payment_timeline_item.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';
import 'package:timelines_plus/timelines_plus.dart';

import 'payment_status_chip.dart';

class ReservationListItem extends StatelessWidget {
  const ReservationListItem({super.key});

  Widget buildActions(BuildContext context, ThreadCubitState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ...state.paymentEvents.any(
              (element) => terminalStates.contains(element),
            )
            ? [
                FilledButton.tonal(
                  onPressed: () {},
                  child: Text('Refund'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const CustomPadding(right: 0.2, left: 0, top: 0, bottom: 0),
              ]
            : [],
        FilledButton.tonal(
          onPressed: () {
            final escrowPubkey = state.reservations
                .firstWhere(
                  (reservation) =>
                      reservation
                          .parsedContent
                          .proof
                          ?.escrowProof
                          ?.escrowService !=
                      null,
                )
                .parsedContent
                .proof
                ?.escrowProof
                ?.escrowService
                .parsedContent
                .pubkey;
            if (escrowPubkey == null) {
              throw Exception('No escrow service found for this reservation');
            }
            context.read<ThreadCubit>().addParticipant(escrowPubkey);
          },
          child: Text('Message Escrow'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.comfortable,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        ...(state.reservations.any((element) => element.parsedContent.cancelled)
            ? []
            : [
                const CustomPadding(right: 0.2, left: 0, top: 0, bottom: 0),
                FilledButton.tonal(
                  onPressed: state.isCancellingReservation
                      ? null
                      : () => context.read<ThreadCubit>().cancelMyReservation(),
                  child: Text('Cancel'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ]),
      ],
    );
  }

  Widget buildHistory(BuildContext context, ThreadCubitState state) {
    final List<dynamic> events = [...state.reservations, ...state.paymentEvents]
      ..sort((a, b) {
        final timestampA = a is Reservation
            ? DateTime.fromMillisecondsSinceEpoch(a.createdAt * 1000)
            : (a is EscrowEvent
                  ? a.block.timestamp
                  : DateTime.fromMillisecondsSinceEpoch(0));

        final timestampB = b is Reservation
            ? DateTime.fromMillisecondsSinceEpoch(b.createdAt * 1000)
            : (b is EscrowEvent
                  ? b.block.timestamp
                  : DateTime.fromMillisecondsSinceEpoch(0));
        return timestampA.compareTo(timestampB);
      });
    if (events.isEmpty) return const SizedBox.shrink();

    const maxHistoryHeight = 320.0;
    final surface = Theme.of(context).colorScheme.surface;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxHistoryHeight),
      child: Stack(
        children: [
          Timeline.tileBuilder(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: kDefaultPadding.toDouble()),
            theme: TimelineThemeData(
              nodePosition: 0,
              connectorTheme: ConnectorThemeData(
                thickness: 2.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              indicatorTheme: IndicatorThemeData(
                size: 20.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            builder: TimelineTileBuilder.connected(
              connectionDirection: ConnectionDirection.before,
              connectorBuilder: (_, index, ___) => SolidLineConnector(
                color: Theme.of(context).colorScheme.primary,
              ),
              indicatorBuilder: (context, index) => DotIndicator(
                color: Theme.of(context).colorScheme.primary,
                // child: Icon(Icons.check, size: 12, color: Colors.white),
              ),
              contentsAlign: ContentsAlign.basic,
              contentsBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: PaymentTimelineItem(
                  event: events[index],
                  listing: state.listing!,
                ),
              ),
              itemCount: events.length,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: kDefaultPadding.toDouble(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [surface.withValues(alpha: 0), surface],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: ExpansionTile(
            splashColor: Colors.transparent,
            tilePadding: EdgeInsets.all(kDefaultPadding.toDouble()),
            // childrenPadding: EdgeInsets.fromLTRB(
            //   kDefaultPadding.toDouble(),
            //   0,
            //   kDefaultPadding.toDouble(),
            //   kDefaultPadding.toDouble(),
            // ),
            shape: const Border(),
            collapsedShape: const Border(),
            title: buildDescription(context, state),
            children: [
              CustomPadding(
                top: 0,
                bottom: 0,
                child: buildHistory(context, state),
              ),
              CustomPadding(child: buildActions(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget buildDescription(BuildContext context, ThreadCubitState state) {
    return Row(
      children: [
        SmallListingCarousel(width: 100, height: 100, listing: state.listing!),

        Expanded(
          child: CustomPadding(
            left: 1,
            right: 0,
            bottom: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.listing!.parsedContent.title.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4.0),
                Text(
                  formatDateRangeShort(
                    DateTimeRange(
                      start: state.reservations.first.parsedContent.start,
                      end: state.reservations.first.parsedContent.end,
                    ),
                    Localizations.localeOf(context),
                  ),
                ),
                const CustomPadding(top: 0.2, bottom: 0),

                PaymentStatusChip(
                  state: state.paymentEvents.isNotEmpty
                      ? state.paymentEvents.last
                      : null,
                ),

                // const CustomPadding(top: 0.2, bottom: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

List<Type> terminalStates = [
  PaymentClaimedEvent,
  PaymentArbitratedEvent,
  PaymentReleasedEvent,
];
