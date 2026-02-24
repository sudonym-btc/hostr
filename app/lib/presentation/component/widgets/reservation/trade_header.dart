import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart' show ThreadCubit;
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/reservation/actions/claim.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_timeline.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/trade_action_resolver.dart';
import 'package:models/main.dart';

import '../flow/payment/escrow/fund/escrow_fund.dart';
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
  final bool runtimeReady;

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
    this.runtimeReady = true,
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

  Widget _buildSummary(BuildContext context) {
    return Column(
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
        Gap.vertical.xs(),
        Text(
          formatDateRangeShort(
            DateTimeRange(start: start, end: end),
            Localizations.localeOf(context),
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (isBlocked) ...[
          Gap.vertical.xs(),
          Text(
            blockedReason ?? 'This reservation is not available.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatAmount(amount),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        // Gap.vertical.xs(),
        paymentStatusWidget,
      ],
    );
  }

  void _showTradeDetailsSheet(BuildContext context) {
    final threadCubit = context.read<ThreadCubit>();
    showAppModal(
      context,
      child: StreamBuilder(
        stream: threadCubit.thread.trade!.state,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final trade = threadCubit.thread.trade!;
          final reservations =
              trade.subscriptions.reservationStream?.list.value ?? const [];
          final paymentEvents =
              trade.subscriptions.paymentEvents?.list.value ?? const [];
          return ModalBottomSheet(
            title: 'Information',
            buttons: actionsWidget,
            content: SingleChildScrollView(
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TradeTimeline(
                      reservations: reservations,
                      paymentEvents: paymentEvents,
                      hostPubKey: threadCubit.state.listingProfile!.pubKey,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isReservationRequestOnly) {
      return ShimmerPlaceholder(
        loading: !runtimeReady,
        child: CustomPadding(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildSummary(context)),
              Gap.horizontal.custom(kSpace3),
              actionsRightWidget,
            ],
          ),
        ),
      );
    }

    return ShimmerPlaceholder(
      loading: !runtimeReady,
      child: CustomPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummary(context),
            Gap.vertical.lg(),
            Row(
              children: [
                Expanded(child: _buildPaymentSummary(context)),
                IconButton(
                  icon: const Icon(Icons.expand_more),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _showTradeDetailsSheet(context);
                  },
                ),
              ],
            ),
          ],
        ),
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
      return FilledButton(
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.actionNotImplementedYet),
        ),
      );
    }

    final children = <Widget>[];

    for (final action in actions) {
      switch (action) {
        case TradeAction.cancel:
          children.add(
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                context.read<ThreadCubit>().thread.trade!.execute(
                  TradeAction.cancel,
                );
              },
            ),
          );
          break;
        case TradeAction.messageEscrow:
          children.add(
            actionButton('Message Escrow', () {
              final threadCubit = context.read<ThreadCubit>();
              final escrowPubkey = threadCubit.thread.trade!.getEscrowPubkey();
              if (escrowPubkey != null) {
                threadCubit.addParticipant(escrowPubkey);
                threadCubit.thread.trade!.refreshActions();
              }
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
              showAppModal(
                context,
                child: EscrowFundWidget(
                  counterparty: listingProfile,
                  reservationRequest: lastReservationRequest,
                ),
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

    return Row(mainAxisAlignment: MainAxisAlignment.end, children: children);
  }

  Widget buildActionsRight(BuildContext context) {
    final children = _buildActionButtons(context);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
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
          runtimeReady: tradeState.runtimeReady,
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
    showAppModal(
      context,
      child: CustomPadding(
        child: EditReview(
          listing: listing,
          salt: 'thread_salt',
          // reservation: thread.reservation,
        ),
      ),
    );
  }
}
