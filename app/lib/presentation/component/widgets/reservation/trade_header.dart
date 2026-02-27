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
import 'package:hostr_sdk/usecase/messaging/thread/trade_state.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../flow/payment/escrow/fund/escrow_fund.dart';
import 'payment_status_chip.dart';

class TradeHeaderView extends StatelessWidget {
  final Listing listing;
  final ProfileMetadata listingProfile;
  final DateTime start;
  final DateTime end;
  final Amount? amount;
  final TradeAvailability availability;
  final String? availabilityReason;
  final List<TradeAction> actions;
  final StreamWithStatus<PaymentEvent>? paymentEventsStream;
  final ValidatedStreamWithStatus<ReservationPairStatus>? reservationStream;
  final String tradeId;
  final String hostPubKey;
  final bool runtimeReady;
  final StreamWithStatus<ReservationTransition>? transitionsStream;
  final ValueStream<bool>? subscriptionsLive;

  const TradeHeaderView({
    super.key,
    required this.listing,
    required this.listingProfile,
    required this.start,
    required this.end,
    required this.amount,
    required this.availability,
    this.availabilityReason,
    this.actions = const [],
    required this.tradeId,
    required this.hostPubKey,
    this.runtimeReady = true,
    this.paymentEventsStream,
    this.reservationStream,
    this.transitionsStream,
    this.subscriptionsLive,
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
    if (amount == null) return const SizedBox.shrink();
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

  // ─── Button helpers ────────────────────────────────────────────────

  void _showNotImplemented(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.actionNotImplementedYet),
        ),
      );

  Widget _cancelButton(BuildContext context) => OutlinedButton(
    onPressed: () =>
        context.read<ThreadCubit>().thread.trade!.execute(TradeAction.cancel),
    style: OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
      side: BorderSide(color: Theme.of(context).colorScheme.error),
    ),
    child: const Text('Cancel'),
  );

  Widget _messageEscrowButton(BuildContext context) => OutlinedButton(
    onPressed: () {
      final cubit = context.read<ThreadCubit>();
      final pubkey = cubit.thread.trade!.getEscrowPubkey();
      if (pubkey != null) {
        cubit.addParticipant(pubkey);
        cubit.thread.trade!.refreshActions();
      }
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.secondary,
    ),
    child: const Text('Message Escrow'),
  );

  Widget _payButton(BuildContext context) {
    final lastReservation = context
        .read<ThreadCubit>()
        .state
        .threadState
        .lastReservationRequest;
    return FilledButton(
      onPressed: () => showAppModal(
        context,
        child: EscrowFundWidget(
          counterparty: listingProfile,
          negotiateReservation: lastReservation,
          listingName: listing.parsedContent.title,
        ),
      ),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.comfortable,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Pay'),
    );
  }

  Widget _acceptButton(BuildContext context) => OutlinedButton(
    onPressed: () =>
        context.read<ThreadCubit>().thread.trade!.execute(TradeAction.accept),
    child: const Text('Accept'),
  );

  Widget _counterButton(BuildContext context) => OutlinedButton(
    onPressed: () => _showNotImplemented(context),
    child: const Text('Counter'),
  );

  Widget _refundButton(BuildContext context) => OutlinedButton(
    onPressed: () => _showNotImplemented(context),
    child: const Text('Refund'),
  );

  Widget _reviewButton(BuildContext context) => OutlinedButton(
    onPressed: () => showAppModal(
      context,
      child: CustomPadding(
        child: EditReview(listing: listing, salt: 'thread_salt'),
      ),
    ),
    child: const Text('Review'),
  );

  // ─── Phase rows ────────────────────────────────────────────────────

  /// Negotiation phase: payment summary on the left, pay / accept / counter / cancel on the right.
  Widget _buildNegotiationRow(
    BuildContext context,
    List<PaymentEvent> paymentEvents,
  ) {
    final hasCancel = actions.contains(TradeAction.cancel);
    final hasCounter = actions.contains(TradeAction.counter);
    final hasPay = actions.contains(TradeAction.pay);
    final hasAccept = actions.contains(TradeAction.accept);
    if (!hasCancel && !hasCounter && !hasPay && !hasAccept) {
      return const SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (amount != null)
          Expanded(child: _buildPaymentSummary(context, paymentEvents))
        else
          const Spacer(),
        if (hasCancel) _cancelButton(context),
        if (hasCounter) ...[
          if (hasCancel) const SizedBox(width: 8),
          _counterButton(context),
        ],
        if (hasPay || hasAccept) const SizedBox(width: 8),
        if (hasPay)
          _payButton(context)
        else if (hasAccept)
          _acceptButton(context),
      ],
    );
  }

  /// Commit phase: cancel / message-escrow on the left, claim / refund / review on the right.
  Widget _buildCommitRow(BuildContext context) {
    final hasCancel = actions.contains(TradeAction.cancel);
    final hasMessageEscrow = actions.contains(TradeAction.messageEscrow);
    final hasClaim = actions.contains(TradeAction.claim);
    final hasRefund = actions.contains(TradeAction.refund);
    final hasReview = actions.contains(TradeAction.review);
    if (!hasCancel &&
        !hasMessageEscrow &&
        !hasClaim &&
        !hasRefund &&
        !hasReview) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (hasCancel) _cancelButton(context),
        if (hasMessageEscrow) ...[
          if (hasCancel) Gap.horizontal.md(),
          _messageEscrowButton(context),
        ],
        if (hasClaim)
          ClaimWidget()
        else if (hasRefund)
          _refundButton(context)
        else if (hasReview)
          _reviewButton(context),
      ],
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
            final hasFunded = paymentEvents.isNotEmpty;
            if (!runtimeReady) return const ShimmerCard(height: 100);
            return StreamBuilder<bool>(
              stream: subscriptionsLive,
              initialData: subscriptionsLive?.value ?? false,
              builder: (context, isLiveSnapshot) {
                return ShimmerPlaceholder(
                  loading: !(isLiveSnapshot.data ?? false),
                  child: Container(
                    color: _containerColor(context),
                    child: CustomPadding(
                      bottom: 0.5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummary(context, showDetails: showDetails),
                          Gap.vertical.lg(),
                          if (hasFunded)
                            _buildCommitRow(context)
                          else
                            _buildNegotiationRow(context, paymentEvents),
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

  @override
  Widget build(BuildContext context) {
    final trade = context.read<ThreadCubit>().thread.trade!;
    // Subscribe to trade.state so this widget rebuilds when runtimeReady
    // changes. Without this, actions$ is captured as Stream.empty() on the
    // first build (context$ emits before _actions$ is assigned in
    // _doEnsureRuntime), and the StreamBuilder never picks up the real stream.
    return StreamBuilder<TradeState>(
      stream: trade.state,
      initialData: trade.state.value,
      builder: (context, stateSnapshot) {
        final tradeState = stateSnapshot.data!;
        return StreamBuilder<TradeResolution>(
          stream: trade.actions$,
          builder: (context, actionsSnapshot) {
            return StreamBuilder<TradeContext?>(
              stream: trade.context$,
              initialData: trade.context$.value,
              builder: (context, contextSnapshot) {
                final tradeContext = contextSnapshot.data;
                final lastRequest =
                    trade.thread.state.value.lastReservationRequest;

                if (tradeContext == null) return const SizedBox.shrink();

                final resolution = actionsSnapshot.data;

                return TradeHeaderView(
                  listing: tradeContext.listing,
                  listingProfile: tradeContext.profile,
                  start: tradeState.start,
                  end: tradeState.end,
                  amount: lastRequest.parsedContent.amount,
                  availability:
                      resolution?.availability ?? TradeAvailability.available,
                  availabilityReason: resolution?.availabilityReason,
                  runtimeReady: tradeState.runtimeReady,
                  actions: resolution?.actions ?? const [],
                  paymentEventsStream: trade.subscriptions.paymentEvents,
                  reservationStream: trade.subscriptions.reservationStream,
                  tradeId: tradeState.tradeId,
                  hostPubKey: tradeContext.profile.pubKey,
                  transitionsStream: trade.subscriptions.transitionsStream,
                  subscriptionsLive: trade.subscriptions.isLive,
                );
              },
            );
          },
        );
      },
    );
  }
}
