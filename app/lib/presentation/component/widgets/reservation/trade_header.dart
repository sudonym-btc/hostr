import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/blossom_image_variant.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/reservation/actions/negotiation.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import 'actions/commit.dart';
import 'payment_status_chip.dart';
import 'trade_details_sheet.dart';

class TradeHeaderView extends StatelessWidget {
  final TradeReady tradeState;
  final bool showActions;
  final bool showImages;
  final bool compact;

  const TradeHeaderView({
    super.key,
    required this.tradeState,
    this.showActions = true,
    this.showImages = true,
    this.compact = false,
  });

  // ─── Convenience accessors ───────────────────────────────────────

  Listing get listing => tradeState.listing;
  ProfileMetadata? get listingProfile => tradeState.sellerProfile;
  DateTime? get start => tradeState.start;
  DateTime? get end => tradeState.end;
  DenominatedAmount? get amount => tradeState.amount;
  TradeAvailability get availability => tradeState.availability;
  String? get availabilityReason => tradeState.availabilityReason;
  List<TradeAction> get actions => tradeState.actions;
  String get tradeId => tradeState.tradeId;
  String get sellerPubkey => tradeState.sellerPubkey;
  StreamWithStatus<PaymentEvent> get paymentEventsStream =>
      tradeState.streams.paymentEvents;
  StreamWithStatus<Validation<ReservationGroup>>? get reservationStream =>
      tradeState.streams.reservationStream;
  StreamWithStatus<ReservationTransition>? get transitionsStream =>
      tradeState.streams.transitionsStream;
  ValueStream<bool>? get subscriptionsLive =>
      tradeState.streams.subscriptionsLive;

  void _openListing(BuildContext context) {
    final anchor = listing.naddr();
    if (anchor == null) return;
    AutoRouter.of(context).push(
      ListingRoute(
        a: anchor,
        dateRangeStart: start?.toUtc().toIso8601String(),
        dateRangeEnd: end?.toUtc().toIso8601String(),
      ),
    );
  }

  Widget _listingLink(BuildContext context, Widget child) {
    if (listing.naddr() == null) return child;
    return Semantics(
      button: true,
      label: 'Open listing',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openListing(context),
          child: child,
        ),
      ),
    );
  }

  Widget? _buildAvailabilityBanner(BuildContext context) {
    return switch (availability) {
      TradeAvailability.available => null,
      TradeAvailability.cancelled => AppChip.error.xs(label: Text('Cancelled')),
      TradeAvailability.unavailable => AppChip.error.xs(
        label: Text('Unavailable'),
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
    final imageSize = compact ? 60.0 : 75.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showImages) ...[
          _listingLink(
            context,
            SizedBox.square(
              dimension: imageSize,
              child: ClipRRect(
                borderRadius: AppBorderRadii.sm,
                child: listing.images.isNotEmpty
                    ? BlossomImage(
                        image: listing.images.first,
                        pubkey: listing.pubKey,
                        imageMetas: listing.imageMetas,
                        variantHint: BlossomImageVariantHint.listingPreview,
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
              _listingLink(
                context,
                Text(
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
              // if (!compact) Gap.vertical.xs(),
              Builder(
                builder: (context) {
                  final s = start;
                  final e = end;
                  return Text(
                    s != null && e != null
                        ? formatDateRangeShort(
                            DateTimeRange(start: s, end: e),
                            Localizations.localeOf(context),
                          )
                        : '',
                    style: compact
                        ? theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : theme.textTheme.bodyMedium,
                  );
                },
              ),
              StreamBuilder<PaymentEvent>(
                stream: paymentEventsStream.replayStream,
                builder: (context, snapshot) {
                  final paymentChip = snapshot.data != null
                      ? PaymentStatusChip(
                          state: snapshot.data!,
                          onTap: () =>
                              showTradeDetailsSheet(context, tradeState),
                        )
                      : null;
                  final availabilityBanner = _buildAvailabilityBanner(context);
                  final chips = [?paymentChip, ?availabilityBanner];
                  if (chips.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: compact ? kSpace1 : kSpace2),
                      Wrap(
                        spacing: kSpace2,
                        runSpacing: kSpace2,
                        children: chips,
                      ),
                    ],
                  );
                },
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
                _buildSummary(context, showImages: showImages),
                if (showActions &&
                    tradeState.stage is NegotiationStage &&
                    availability != TradeAvailability.cancelled)
                  NegotiationWidget(tradeState: tradeState),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TradeHeader extends StatefulWidget {
  final String tradeId;
  final Iterable<String> participants;
  final bool showActions;
  final bool showImages;
  final bool compact;

  const TradeHeader({
    super.key,
    required this.tradeId,
    required this.participants,
    this.showActions = true,
    this.showImages = true,
    this.compact = false,
  });

  @override
  State<TradeHeader> createState() => _TradeHeaderState();
}

class _TradeHeaderState extends State<TradeHeader> {
  Trade? _trade;

  @override
  void initState() {
    super.initState();
    _ensureTrade();
  }

  @override
  void didUpdateWidget(covariant TradeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tradeId != widget.tradeId ||
        !_sameParticipants(oldWidget.participants, widget.participants)) {
      final previousTrade = _trade;
      _trade = null;
      previousTrade?.close();
      _ensureTrade();
    }
  }

  @override
  void dispose() {
    _trade?.close();
    super.dispose();
  }

  void _ensureTrade() {
    if (_trade != null) return;
    if (widget.participants.isEmpty) return;
    _trade = getIt<Hostr>().trade(widget.tradeId, widget.participants)..start();
  }

  bool _sameParticipants(Iterable<String> a, Iterable<String> b) =>
      Threads.normalizeParticipants(a).join('\u0000') ==
      Threads.normalizeParticipants(b).join('\u0000');

  @override
  Widget build(BuildContext context) {
    _ensureTrade();
    final trade = _trade;
    if (trade == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: AppLoadingIndicator.medium()),
      );
    }

    return BlocProvider<Trade>.value(
      value: trade,
      child: BlocBuilder<Trade, TradeState>(
        builder: (context, tradeState) {
          switch (tradeState) {
            case TradeReady():
              return TradeHeaderView(
                tradeState: tradeState,
                showActions: widget.showActions,
                showImages: widget.showImages,
                compact: widget.compact,
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
