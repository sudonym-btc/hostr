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
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/trade_action_resolver.dart';
import 'package:models/main.dart';

import '../flow/payment/escrow/fund/escrow_fund.dart';
import 'payment_status_chip.dart';

class TradeHeaderView extends StatelessWidget {
  final Listing listing;
  final DateTime start;
  final DateTime end;
  final Amount? amount;
  final TradeAvailability availability;
  final String? availabilityReason;
  final Widget actionsRightWidget;
  final Widget actionsWidget;
  final StreamWithStatus<PaymentEvent>? paymentEventsStream;
  final ValidatedStreamWithStatus<ReservationPairStatus>? reservationStream;
  final String tradeId;
  final String hostPubKey;
  final bool runtimeReady;
  final StreamWithStatus<ReservationTransition>? transitionsStream;

  const TradeHeaderView({
    super.key,
    required this.listing,
    required this.start,
    required this.end,
    required this.amount,
    required this.availability,
    this.availabilityReason,
    required this.actionsRightWidget,
    required this.actionsWidget,
    required this.tradeId,
    required this.hostPubKey,
    this.runtimeReady = true,
    this.paymentEventsStream,
    this.reservationStream,
    this.transitionsStream,
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

  Widget _buildAvailabilityBanner(BuildContext context) {
    return switch (availability) {
      TradeAvailability.available => const SizedBox.shrink(),
      TradeAvailability.cancelled => Chip(
        label: const Text('Cancelled'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        side: BorderSide.none,
        avatar: Icon(
          Icons.cancel_outlined,
          size: kIconXs,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        shape: const StadiumBorder(),
      ),
      TradeAvailability.unavailable => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          availabilityReason ?? 'This reservation is not available.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      TradeAvailability.invalidReservation => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          availabilityReason ?? 'Reservation is invalid.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      TradeAvailability.invalidTransitions => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          availabilityReason ?? 'State conflict detected.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    };
  }

  Color _containerColor(BuildContext context) => switch (availability) {
    TradeAvailability.invalidReservation ||
    TradeAvailability.invalidTransitions => Theme.of(
      context,
    ).colorScheme.errorContainer,
    _ => Colors.transparent,
  };

  Widget _buildSummary(BuildContext context, {required bool showDetails}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
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
              Gap.vertical.xs(),
              Text(
                formatDateRangeShort(
                  DateTimeRange(start: start, end: end),
                  Localizations.localeOf(context),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              _buildAvailabilityBanner(context),
            ],
          ),
        ),
        if (showDetails)
          TextButton(
            onPressed: () => _showTradeDetailsSheet(context),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Details'),
          ),
      ],
    );
  }

  Widget _buildPaymentSummary(
    BuildContext context,
    List<PaymentEvent> paymentEvents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatAmount(amount!),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        // Gap.vertical.xs(),
        PaymentStatusChip(state: paymentEvents.lastOrNull),
      ],
    );
  }

  void _showTradeDetailsSheet(BuildContext context) {
    showAppModal(
      context,
      child: StreamBuilder<List<ReservationTransition>>(
        stream: transitionsStream?.list,
        initialData: transitionsStream?.list.value ?? const [],
        builder: (context, transitionsSnapshot) {
          final transitions = transitionsSnapshot.data ?? const [];
          return StreamBuilder<List<PaymentEvent>>(
            stream: paymentEventsStream?.list,
            initialData: paymentEventsStream?.list.value ?? const [],
            builder: (context, paymentSnapshot) {
              final paymentEvents = paymentSnapshot.data ?? const [];
              return StreamBuilder<List<Validation<ReservationPairStatus>>>(
                stream: reservationStream?.stream,
                initialData: reservationStream?.list.value,
                builder: (context, reservationSnapshot) {
                  final reservationValidation =
                      (reservationSnapshot.data ?? const []).firstOrNull;
                  return ModalBottomSheet(
                    title: 'Information',
                    buttons: actionsWidget,
                    content: SingleChildScrollView(
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TradeTimeline(
                              transitions: transitions,
                              paymentEvents: paymentEvents,
                              hostPubKey: hostPubKey,
                            ),
                            if (reservationValidation
                                is Invalid<ReservationPairStatus>) ...[
                              Gap.vertical.lg(),
                              _ReservationRecords(
                                validatedReservationPair: reservationValidation,
                                listing: listing,
                                hostPubKey: hostPubKey,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentEvent>>(
      stream: paymentEventsStream?.list,
      initialData: paymentEventsStream?.list.value ?? const [],
      builder: (context, paymentSnapshot) {
        final paymentEvents = paymentSnapshot.data ?? const [];
        return StreamBuilder<List<Validation<ReservationPairStatus>>>(
          stream: reservationStream?.stream,
          initialData: reservationStream?.list.value ?? const [],
          builder: (context, reservationSnapshot) {
            final reservations = reservationSnapshot.data ?? const [];
            final showDetails =
                paymentEvents.isNotEmpty || reservations.isNotEmpty;
            return ShimmerPlaceholder(
              loading: !runtimeReady,
              child: Container(
                color: _containerColor(context),
                child: CustomPadding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummary(context, showDetails: showDetails),
                      Gap.vertical.lg(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaymentSummary(context, paymentEvents),
                          ),
                          actionsRightWidget,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReservationRecords extends StatelessWidget {
  final Validation<ReservationPairStatus> validatedReservationPair;
  final Listing listing;
  final String hostPubKey;

  const _ReservationRecords({
    required this.validatedReservationPair,
    required this.listing,
    required this.hostPubKey,
  });

  @override
  Widget build(BuildContext context) {
    final pair = validatedReservationPair;
    if (pair is Invalid<ReservationPairStatus>) {
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

class TradeHeader extends StatelessWidget {
  const TradeHeader({super.key});

  List<Widget> _buildActionButtons(
    BuildContext context,
    List<TradeAction> actionList,
    ProfileMetadata listingProfile,
    Listing listing,
  ) {
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

    for (final action in actionList) {
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
          children.add(actionButton('Review', () => _review(context, listing)));
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
              final lastNegotiateReservation = context
                  .read<ThreadCubit>()
                  .state
                  .threadState
                  .lastReservationRequest;
              showAppModal(
                context,
                child: EscrowFundWidget(
                  counterparty: listingProfile,
                  negotiateReservation: lastNegotiateReservation,
                  listingName: listing.parsedContent.title,
                ),
              );
            }),
          );
          break;
      }
    }

    return children;
  }

  Widget _buildActions(
    BuildContext context,
    List<TradeAction> actions,
    ProfileMetadata listingProfile,
    Listing listing,
  ) {
    final children = _buildActionButtons(
      context,
      actions,
      listingProfile,
      listing,
    );
    if (children.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: children);
  }

  Widget _buildActionsRight(
    BuildContext context,
    List<TradeAction> actions,
    ProfileMetadata listingProfile,
    Listing listing,
  ) {
    final hasPay = actions.contains(TradeAction.pay);
    final TradeAction? primaryAction = hasPay
        ? TradeAction.pay
        : (actions.length == 1 ? actions.first : null);

    if (primaryAction == null) return const SizedBox.shrink();

    final children = _buildActionButtons(
      context,
      [primaryAction],
      listingProfile,
      listing,
    );
    if (children.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  @override
  Widget build(BuildContext context) {
    final trade = context.read<ThreadCubit>().thread.trade!;
    return StreamBuilder<TradeResolution>(
      stream: trade.actions$,
      builder: (context, actionsSnapshot) {
        return StreamBuilder<TradeContext?>(
          stream: trade.context$,
          initialData: trade.context$.value,
          builder: (context, contextSnapshot) {
            final tradeContext = contextSnapshot.data;
            final tradeState = trade.state.value;

            if (tradeContext == null) return const SizedBox.shrink();

            final resolution = actionsSnapshot.data;
            final actions = resolution?.actions ?? const [];
            final listingProfile = tradeContext.profile;

            return TradeHeaderView(
              listing: tradeContext.listing,
              start: tradeState.start,
              end: tradeState.end,
              amount: tradeState.amount,
              availability:
                  resolution?.availability ?? TradeAvailability.available,
              availabilityReason: resolution?.availabilityReason,
              runtimeReady: tradeState.runtimeReady,
              actionsRightWidget: _buildActionsRight(
                context,
                actions,
                listingProfile,
                tradeContext.listing,
              ),
              actionsWidget: _buildActions(
                context,
                actions,
                listingProfile,
                tradeContext.listing,
              ),
              paymentEventsStream: trade.subscriptions.paymentEvents,
              reservationStream: trade.subscriptions.reservationStream,
              tradeId: tradeState.tradeId,
              hostPubKey: listingProfile.pubKey,
              transitionsStream: trade.subscriptions.transitionsStream,
            );
          },
        );
      },
    );
  }

  void _review(BuildContext context, Listing listing) {
    showAppModal(
      context,
      child: CustomPadding(
        child: EditReview(listing: listing, salt: 'thread_salt'),
      ),
    );
  }
}
