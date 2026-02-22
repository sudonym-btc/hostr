import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart' show ThreadCubit;
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/listing/preload_listing_images.dart';
import 'package:hostr/presentation/component/widgets/reservation/actions/claim.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_timeline.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/trade_action_resolver.dart';
import 'package:models/main.dart';

import '../flow/payment/payment_method/payment_method.dart';
import 'payment_status_chip.dart';

class TradeHeaderView extends StatelessWidget {
  final Listing listing;
  final DateTime start;
  final DateTime end;
  final Amount amount;
  final bool isBlocked;
  final String? blockedReason;
  final bool isReservationRequestOnly;
  final Widget paymentStatusWidget;
  final Widget actionsRightWidget;
  final Widget actionsWidget;
  final Widget timelineWidget;

  const TradeHeaderView({
    super.key,
    required this.listing,
    required this.start,
    required this.end,
    required this.amount,
    required this.isBlocked,
    required this.blockedReason,
    required this.isReservationRequestOnly,
    required this.paymentStatusWidget,
    required this.actionsRightWidget,
    required this.actionsWidget,
    required this.timelineWidget,
  });

  void _navigateToListing(BuildContext context) {
    if (listing.anchor != null) {
      AutoRouter.of(context).push(
        ListingRoute(
          a: listing.anchor!,
          dateRangeStart: start.toIso8601String(),
          dateRangeEnd: end.toIso8601String(),
        ),
      );
    }
  }

  Widget _buildDescription(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _navigateToListing(context),
          child: PreloadListingImages(
            listing: listing,
            child: SmallListingCarousel(
              width: 100,
              height: 100,
              listing: listing,
            ),
          ),
        ),
        Expanded(
          child: CustomPadding(
            left: 0.5,
            right: 0,
            bottom: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _navigateToListing(context),
                  child: Text(
                    listing.parsedContent.title.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  formatDateRangeShort(
                    DateTimeRange(start: start, end: end),
                    Localizations.localeOf(context),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const CustomPadding(top: 0.2, bottom: 0),
                Row(
                  children: [
                    Text(
                      formatAmount(amount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    paymentStatusWidget,
                  ],
                ),
                if (isBlocked) ...[
                  const CustomPadding(top: 0.2, bottom: 0),
                  Text(
                    blockedReason ?? 'This reservation is not available.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isReservationRequestOnly) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: CustomPadding(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildDescription(context)),
              const SizedBox(width: 12),
              actionsRightWidget,
            ],
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ExpansionTile(
        splashColor: Colors.transparent,
        onExpansionChanged: (_) => FocusScope.of(context).unfocus(),
        tilePadding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding.toDouble(),
          vertical: kDefaultPadding.toDouble() / 2,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        title: _buildDescription(context),
        children: [
          CustomPadding(top: 0, bottom: 0, child: timelineWidget),
          CustomPadding(child: actionsWidget),
        ],
      ),
    );
  }
}

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
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label),
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
        final tradeState = state.data!;
        if (tradeState.listing == null) return const SizedBox.shrink();

        final trade = context.read<ThreadCubit>().thread.trade!;
        final reservations =
            trade.subscriptions.reservationStream?.list.value ?? const [];
        final paymentEvents =
            trade.subscriptions.paymentEvents?.list.value ?? const [];

        return TradeHeaderView(
          listing: tradeState.listing!,
          start: tradeState.start,
          end: tradeState.end,
          amount: tradeState.amount,
          isBlocked: tradeState.isBlocked == true,
          blockedReason: tradeState.blockedReason,
          isReservationRequestOnly: reservations.isEmpty,
          paymentStatusWidget: PaymentStatusChip(
            state: paymentEvents.lastOrNull,
          ),
          actionsRightWidget: buildActionsRight(context),
          actionsWidget: buildActions(context),
          timelineWidget: TradeTimeline(
            reservations: reservations,
            paymentEvents: paymentEvents,
            hostPubKey: listingProfile.pubKey,
          ),
        );
      },
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
