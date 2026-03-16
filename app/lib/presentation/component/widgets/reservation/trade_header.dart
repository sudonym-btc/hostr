import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/reservation/actions/negotiation.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../profile/verification/verification_badges.dart';
import 'actions/commit.dart';
import 'payment_status_chip.dart';

class TradeHeaderView extends StatelessWidget {
  final TradeReady tradeState;
  final bool showActions;
  final bool showImages;
  final bool compact;
  final VoidCallback? onTap;

  const TradeHeaderView({
    super.key,
    required this.tradeState,
    this.showActions = true,
    this.showImages = true,
    this.compact = false,
    this.onTap,
  });

  // ─── Convenience accessors ───────────────────────────────────────

  Listing get listing => tradeState.listing;
  ProfileMetadata? get listingProfile => tradeState.hostProfile;
  DateTime get start => tradeState.start;
  DateTime get end => tradeState.end;
  Amount? get amount => tradeState.amount;
  TradeAvailability get availability => tradeState.availability;
  String? get availabilityReason => tradeState.availabilityReason;
  List<TradeAction> get actions => tradeState.actions;
  String get tradeId => tradeState.tradeId;
  String get hostPubKey => tradeState.hostPubKey;
  StreamWithStatus<PaymentEvent> get paymentEventsStream =>
      tradeState.streams.paymentEvents;
  StreamWithStatus<Validation<ReservationPair>>? get reservationStream =>
      tradeState.streams.reservationStream;
  StreamWithStatus<ReservationTransition>? get transitionsStream =>
      tradeState.streams.transitionsStream;
  ValueStream<bool>? get subscriptionsLive =>
      tradeState.streams.subscriptionsLive;

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

  Color _containerColor(BuildContext context) => switch (availability) {
    TradeAvailability.invalidReservation ||
    TradeAvailability.invalidTransitions => Theme.of(
      context,
    ).colorScheme.errorContainer,
    _ => Colors.transparent,
  };

  Widget _buildSummary(BuildContext context, {required bool showImages}) {
    final theme = Theme.of(context);
    final availabilityBanner = _buildAvailabilityBanner(context);
    final paymentStatusChip = StreamBuilder<PaymentEvent>(
      stream: paymentEventsStream.replayStream,
      builder: (context, snapshot) {
        final event = snapshot.data;
        if (event != null) {
          return PaymentStatusChip(state: event);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
    final statusBanners = [?availabilityBanner, paymentStatusChip];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showImages) ...[
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: compact ? 60 : 75),
              child: SizedBox(
                width: compact ? 60 : 75,
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
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap ?? () => _navigateToListing(context),
                  child: Text(
                    listing.title.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          )
                        : theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                ),
                if (!compact) Gap.vertical.xs(),
                Text(
                  formatDateRangeShort(
                    DateTimeRange(start: start, end: end),
                    Localizations.localeOf(context),
                  ),
                  style: compact
                      ? theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : theme.textTheme.bodyMedium,
                ),
                if (statusBanners.isNotEmpty)
                  SizedBox(height: compact ? kSpace1 : kSpace2),
                if (statusBanners.isNotEmpty)
                  Wrap(
                    spacing: kSpace2,
                    runSpacing: kSpace2,
                    children: statusBanners,
                  ),
              ],
            ),
          ),
          if (showActions && tradeState.stage is CommitStage) ...[
            Gap.horizontal.sm(),
            Align(
              alignment: Alignment.centerRight,
              child: CommitMenu(tradeState: tradeState),
            ),
          ],
        ],
      ),
    );
  }
  // ─── Phase rows ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: subscriptionsLive,
      initialData: subscriptionsLive?.value ?? false,
      builder: (context, isLiveSnapshot) {
        final isLive = isLiveSnapshot.data ?? false;
        return ShimmerPlaceholder(
          loading: !isLive,
          child: Container(
            color: _containerColor(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                compact
                    ? _buildSummary(context, showImages: showImages)
                    : CustomPadding(
                        child: _buildSummary(context, showImages: showImages),
                      ),
                if (showActions && tradeState.stage is NegotiationStage)
                  NegotiationWidget(tradeState: tradeState),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TradeHeader extends StatelessWidget {
  final String tradeId;
  final bool showActions;
  final bool showImages;
  final bool compact;
  final VoidCallback? onTap;
  const TradeHeader({
    super.key,
    required this.tradeId,
    this.showActions = true,
    this.showImages = true,
    this.compact = false,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return BlocProvider<Trade>(
      create: (_) => getIt<Hostr>().trade(tradeId)..start(),
      child: BlocBuilder<Trade, TradeState>(
        builder: (context, tradeState) {
          switch (tradeState) {
            case TradeReady():
              return TradeHeaderView(
                tradeState: tradeState,
                showActions: showActions,
                showImages: showImages,
                compact: compact,
                onTap: onTap,
              );
            case TradeInitialising():
              return const SizedBox(
                height: 100,
                child: Center(child: AppLoadingIndicator.medium()),
              );
            case TradeError():
              return Text(tradeState.message);
          }
        },
      ),
    );
  }
}
