import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart' show ThreadCubit;
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/reservation/actions/claim.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_timeline.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../flow/payment/escrow/fund/escrow_fund.dart';
import '../flow/payment/escrow/release/escrow_release.dart';
import '../profile/verification/verification_badges.dart';
import 'payment_status_chip.dart';

typedef _TradeMenuItem = ({String label, IconData icon, VoidCallback onTap});

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
  final StreamWithStatus<Validation<ReservationPairStatus>>? reservationStream;
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
          dateRangeStart: start.toUtc().toIso8601String(),
          dateRangeEnd: end.toUtc().toIso8601String(),
        ),
      );
    }
  }

  Widget? _buildAvailabilityBanner(BuildContext context) {
    return switch (availability) {
      TradeAvailability.available => null,
      TradeAvailability.cancelled => StatusChip(
        label: 'Cancelled',
        color: Theme.of(context).colorScheme.error,
      ),
      TradeAvailability.unavailable => StatusChip(
        label: 'Unavailable',
        color: Theme.of(context).colorScheme.error,
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

  Color _appBarScrolledColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.surfaceContainerHigh;
  }

  Color _containerColor(BuildContext context) => switch (availability) {
    TradeAvailability.invalidReservation ||
    TradeAvailability.invalidTransitions => Theme.of(
      context,
    ).colorScheme.errorContainer,
    _ => _appBarScrolledColor(context),
  };

  Widget _buildSummary(
    BuildContext context, {
    required bool showDetails,
    required bool showImages,
    required List<PaymentEvent> paymentEvents,
    List<_TradeMenuItem> menuItems = const [],
  }) {
    final availabilityBanner = _buildAvailabilityBanner(context);
    final paymentStatusChip = paymentEvents.isNotEmpty
        ? PaymentStatusChip(state: paymentEvents.last)
        : null;

    final statusBanners = [?availabilityBanner, ?paymentStatusChip];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 75),
            child: SizedBox(
              width: 75,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: listing.images.isNotEmpty
                    ? BlossomImage(
                        image: listing.images.first,
                        pubkey: listing.pubKey,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          Gap.horizontal.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _navigateToListing(context),
                  child: Text(
                    listing.title.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // Gap.vertical.xs(),
                Text(
                  formatDateRangeShort(
                    DateTimeRange(start: start, end: end),
                    Localizations.localeOf(context),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (statusBanners.isNotEmpty) Gap.vertical.sm(),
                if (statusBanners.isNotEmpty)
                  Wrap(
                    spacing: kSpace2,
                    runSpacing: kSpace2,
                    children: statusBanners,
                  ),
              ],
            ),
          ),
          if (showDetails || menuItems.isNotEmpty) Gap.horizontal.sm(),
          if (showDetails || menuItems.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<void>(
                padding: EdgeInsets.zero,
                iconSize: 20,
                tooltip: '',
                icon: const Icon(Icons.more_vert),
                itemBuilder: (ctx) => [
                  ...menuItems.map(
                    (item) => PopupMenuItem<void>(
                      onTap: item.onTap,
                      child: Row(
                        children: [
                          Icon(item.icon, size: 18),
                          Gap.horizontal.md(),
                          Text(item.label),
                        ],
                      ),
                    ),
                  ),
                  if (showDetails) ...[
                    if (menuItems.isNotEmpty) const PopupMenuDivider(),
                    PopupMenuItem<void>(
                      onTap: () => _showTradeDetailsSheet(context),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          Gap.horizontal.md(),
                          Text('Information'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(
    BuildContext context,
    List<PaymentEvent> paymentEvents,
  ) {
    if (amount == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatAmount(amount!, exact: false),
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
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
                stream: reservationStream?.list,
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
    key: const ValueKey('trade_action_cancel'),
    onPressed: () {
      showAppModal(
        context,
        child: ModalBottomSheet(
          title: AppLocalizations.of(context)!.cancelReservation,
          subtitle: AppLocalizations.of(context)!.areYouSure,
          content: const SizedBox.shrink(),
          buttons: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<ThreadCubit>().thread.trade!.execute(
                    TradeAction.cancel,
                  );
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        ),
      );
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
      side: BorderSide(color: Theme.of(context).colorScheme.error),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text('Cancel'),
  );

  Widget _payButton(BuildContext context) {
    final lastReservation = context
        .read<ThreadCubit>()
        .state
        .threadState
        .lastReservationRequest;
    final registry = getIt<Hostr>().escrowFundRegistry;
    return StreamBuilder<EscrowFundOperation?>(
      stream: registry.watchTrade(tradeId),
      initialData: registry.hasActiveFund(tradeId)
          ? null // will resolve on first stream emit
          : null,
      builder: (context, snapshot) {
        final activeOp = snapshot.data;
        if (activeOp != null) {
          return FilledButton(
            key: const ValueKey('trade_action_pay'),
            onPressed: () {
              showAppModal(
                context,
                child: EscrowFundFlowWidget(cubit: activeOp),
              );
            },
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          );
        }
        return FilledButton(
          key: const ValueKey('trade_action_pay'),
          onPressed: () => showAppModal(
            context,
            child: EscrowFundWidget(
              counterparty: listingProfile,
              negotiateReservation: lastReservation,
              listingName: listing.title,
            ),
          ),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Pay'),
        );
      },
    );
  }

  Widget _acceptButton(BuildContext context) => OutlinedButton(
    key: const ValueKey('trade_action_accept'),
    onPressed: () =>
        context.read<ThreadCubit>().thread.trade!.execute(TradeAction.accept),
    style: OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text('Accept'),
  );

  Widget _counterButton(BuildContext context) => OutlinedButton(
    key: const ValueKey('trade_action_counter'),
    onPressed: () => _showNotImplemented(context),
    style: OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text('Counter'),
  );

  // ─── Phase rows ────────────────────────────────────────────────────

  /// Negotiation phase: payment summary on the left, pay / accept / counter / cancel on the right.
  Widget? _buildNegotiationRow(
    BuildContext context,
    List<PaymentEvent> paymentEvents,
  ) {
    final hasCancel = actions.contains(TradeAction.cancel);
    final hasCounter = actions.contains(TradeAction.counter);
    final hasPay = actions.contains(TradeAction.pay);
    final hasAccept = actions.contains(TradeAction.accept);
    if (!hasCancel && !hasCounter && !hasPay && !hasAccept) {
      return null;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildPaymentSummary(context, paymentEvents)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
              child: Wrap(
                spacing: kSpace2,
                runSpacing: kSpace2,
                alignment: WrapAlignment.end,
                children: [
                  if (hasCancel) _cancelButton(context),
                  if (hasCounter) _counterButton(context),
                  if (hasPay)
                    _payButton(context)
                  else if (hasAccept)
                    _acceptButton(context),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<_TradeMenuItem> _buildCommitMenuItems(BuildContext context) {
    final items = <_TradeMenuItem>[];
    if (actions.contains(TradeAction.cancel)) {
      items.add((
        label: 'Cancel',
        icon: Icons.cancel_outlined,
        onTap: () => showAppModal(
          context,
          child: ModalBottomSheet(
            title: AppLocalizations.of(context)!.cancelReservation,
            subtitle: AppLocalizations.of(context)!.areYouSure,
            content: const SizedBox.shrink(),
            buttons: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<ThreadCubit>().thread.trade!.execute(
                      TradeAction.cancel,
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
          ),
        ),
      ));
    }
    if (actions.contains(TradeAction.messageEscrow)) {
      items.add((
        label: 'Message Escrow',
        icon: Icons.support_agent_outlined,
        onTap: () {
          final cubit = context.read<ThreadCubit>();
          final pubkey = cubit.thread.trade!.getEscrowPubkey();
          if (pubkey != null) {
            cubit.addParticipant(pubkey);
            cubit.thread.trade!.refreshActions();
          }
        },
      ));
    }
    if (actions.contains(TradeAction.refund)) {
      items.add((
        label: 'Refund',
        icon: Icons.undo_outlined,
        onTap: () {
          final cubit = context.read<ThreadCubit>();
          final selectedEscrows = cubit.state.threadState.selectedEscrows;
          if (selectedEscrows.isEmpty) return;
          final escrowService = selectedEscrows.first.service;
          final releaseOp = getIt<Hostr>().escrow.release(
            EscrowReleaseParams(escrowService: escrowService, tradeId: tradeId),
          );
          showAppModal(context, child: ReleaseFlowWidget(cubit: releaseOp));
        },
      ));
    }
    if (actions.contains(TradeAction.claim)) {
      items.add((
        label: 'Claim',
        icon: Icons.download_outlined,
        onTap: () => showAppModal(context, child: ClaimWidget()),
      ));
    } else if (actions.contains(TradeAction.review)) {
      items.add((
        label: 'Review',
        icon: Icons.star_outline,
        onTap: () => showAppModal(
          context,
          child: CustomPadding(
            child: EditReview(listing: listing, salt: 'thread_salt'),
          ),
        ),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentEvent>>(
      stream: paymentEventsStream?.list,
      initialData: paymentEventsStream?.list.value ?? const [],
      builder: (context, paymentSnapshot) {
        final paymentEvents = paymentSnapshot.data ?? const [];
        return StreamBuilder<List<Validation<ReservationPairStatus>>>(
          stream: reservationStream?.list,
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
                final isLive = isLiveSnapshot.data ?? false;
                final isCommitPhase = isLive && hasFunded;
                final commitMenuItems = isCommitPhase
                    ? _buildCommitMenuItems(context)
                    : <_TradeMenuItem>[];
                // Only show the negotiation row once subscriptions are live
                // so we know the true phase. Otherwise the row flashes open
                // and immediately animates away when the commit phase kicks in.
                final actionRow = isCommitPhase || !isLive
                    ? null
                    : _buildNegotiationRow(context, paymentEvents);

                return ShimmerPlaceholder(
                  loading: !(isLiveSnapshot.data ?? false),
                  child: Container(
                    color: _containerColor(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomPadding(
                          child: _buildSummary(
                            context,
                            showImages: true,
                            showDetails: showDetails,
                            paymentEvents: paymentEvents,
                            menuItems: commitMenuItems,
                          ),
                        ),
                        Container(
                          color: Colors.transparent,
                          child: AnimatedSize(
                            duration: kAnimationDuration,
                            curve: kAnimationCurve,
                            alignment: Alignment.topCenter,
                            child: actionRow != null
                                ? CustomPadding(
                                    top: 0,
                                    bottom: 0.5,
                                    child: actionRow,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
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
    // first build, and the StreamBuilder never picks up the real stream.
    return StreamBuilder<TradeState>(
      stream: trade.state,
      initialData: trade.state.value,
      builder: (context, stateSnapshot) {
        final tradeState = stateSnapshot.data!;

        // Wait for runtime to populate listing & profile.
        final listing = trade.listing;
        final hostProfile = trade.hostProfile;
        if (listing == null || hostProfile == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<TradeResolution>(
          stream: trade.actions$,
          builder: (context, actionsSnapshot) {
            final lastRequest = trade.thread.state.value.lastReservationRequest;
            final resolution = actionsSnapshot.data;

            return TradeHeaderView(
              listing: listing,
              listingProfile: hostProfile,
              start: tradeState.start,
              end: tradeState.end,
              amount: lastRequest.amount,
              availability:
                  resolution?.availability ?? TradeAvailability.available,
              availabilityReason: resolution?.availabilityReason,
              runtimeReady: tradeState.runtimeReady,
              actions: resolution?.actions ?? const [],
              paymentEventsStream: trade.subscriptions.paymentEvents,
              reservationStream: trade.subscriptions.reservationStream,
              tradeId: tradeState.tradeId,
              hostPubKey: trade.hostPubKey,
              transitionsStream: trade.subscriptions.transitionsStream,
              subscriptionsLive: trade.subscriptions.isLive,
            );
          },
        );
      },
    );
  }
}
