import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart' show ThreadCubit;
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/reservation/actions/claim.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_timeline.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/trade_action_resolver.dart';
import 'package:hostr_sdk/usecase/messaging/thread/trade_state.dart';
import 'package:models/main.dart';

import '../flow/payment/payment_method/payment_method.dart';
import 'payment_status_chip.dart';

class TradeHeader extends StatelessWidget {
  final List<TradeAction> actions;
  final ProfileMetadata listingProfile;

  const TradeHeader({
    super.key,
    required this.listingProfile,
    required this.actions,
  });

  List<Widget> _buildActionButtons(BuildContext context) {
    FilledButton actionButton(String label, VoidCallback? onPressed) {
      return FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    void notImplemented() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action not implemented yet')),
      );
    }

    final children = <Widget>[];

    for (final action in actions) {
      switch (action) {
        case TradeAction.cancel:
          children.add(
            actionButton('Cancel', () {
              context.read<ThreadCubit>().thread.trade!.execute(
                TradeAction.cancel,
              );
            }),
          );
          break;
        case TradeAction.messageEscrow:
          children.add(
            actionButton('Message Escrow', () {
              context.read<ThreadCubit>().thread.trade!.execute(
                TradeAction.messageEscrow,
              );
            }),
          );
          break;
        case TradeAction.review:
          children.add(
            actionButton(
              'Review',
              () => review(context, context.read<ThreadCubit>().state.listing!),
            ),
          );
          break;
        case TradeAction.refund:
          children.add(actionButton('Refund', notImplemented));
          break;
        case TradeAction.claim:
          children.add(ClaimWidget());
          break;
        case TradeAction.accept:
          children.add(
            actionButton(
              'Accept',
              () => context.read<ThreadCubit>().thread.trade!.execute(
                TradeAction.accept,
              ),
            ),
          );

          break;
        case TradeAction.counter:
          children.add(actionButton('Counter', notImplemented));
          break;
        case TradeAction.pay:
          children.add(
            actionButton('Pay', () {
              final lastReservationRequest = context
                  .read<ThreadCubit>()
                  .state
                  .threadState
                  .lastReservationRequest;
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return PaymentMethodWidget(
                    counterparty: listingProfile,
                    reservationRequest: lastReservationRequest,
                  );
                },
              );
            }),
          );
          break;
      }
    }

    return children;
  }

  Widget buildActions(BuildContext context) {
    final children = _buildActionButtons(context);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }

  Widget buildActionsRight(BuildContext context) {
    final children = _buildActionButtons(context);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<ThreadCubit>().thread.trade!.state,
      builder: (context, state) {
        if (!state.hasData) return const SizedBox.shrink();
        final isReservationRequestOnly = context
            .read<ThreadCubit>()
            .thread
            .trade!
            .subscriptions
            .reservationStream!
            .list
            .value
            .isEmpty;

        if (isReservationRequestOnly) {
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: CustomPadding(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: buildDescription(context, state.data!)),
                  const SizedBox(width: 12),
                  buildActionsRight(context),
                ],
              ),
            ),
          );
        }

        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: ExpansionTile(
            splashColor: Colors.transparent,
            tilePadding: EdgeInsets.all(kDefaultPadding.toDouble()),
            shape: const Border(),
            collapsedShape: const Border(),
            title: buildDescription(context, state.data!),
            children: [
              CustomPadding(
                top: 0,
                bottom: 0,
                child: TradeTimeline(
                  reservations: context
                      .read<ThreadCubit>()
                      .thread
                      .trade!
                      .subscriptions
                      .reservationStream!
                      .list
                      .value,
                  paymentEvents: context
                      .read<ThreadCubit>()
                      .thread
                      .trade!
                      .subscriptions
                      .paymentEvents!
                      .list
                      .value,
                  hostPubKey: listingProfile.pubKey,
                ),
              ),
              CustomPadding(child: buildActions(context)),
            ],
          ),
        );
      },
    );
  }

  Widget buildDescription(BuildContext context, TradeState state) {
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
                    DateTimeRange(start: state.start, end: state.end),
                    Localizations.localeOf(context),
                  ),
                ),
                const CustomPadding(top: 0.2, bottom: 0),

                Text(
                  formatAmount(state.amount),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const CustomPadding(top: 0.2, bottom: 0),

                PaymentStatusChip(
                  state: context
                      .read<ThreadCubit>()
                      .thread
                      .trade!
                      .subscriptions
                      .paymentEvents!
                      .list
                      .value
                      .lastOrNull,
                ),

                if (state.isBlocked == true) ...[
                  const CustomPadding(top: 0.2, bottom: 0),
                  Text(
                    state.blockedReason ?? 'This reservation is not available.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],

                // const CustomPadding(top: 0.2, bottom: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void review(BuildContext context, Listing listing) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: CustomPadding(
            child: EditReview(
              listing: listing,
              salt: 'thread_salt',
              // reservation: thread.reservation,
            ),
          ),
        );
      },
    );
  }
}
