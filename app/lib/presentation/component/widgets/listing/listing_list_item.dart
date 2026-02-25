import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/listing/preload_listing_images.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'price_tag.dart';

class ListingListItemView extends StatelessWidget {
  final Listing listing;
  final bool showPrice;
  final bool showFeedback;
  final bool smallImage;
  final WidgetBuilder? bottom;
  final bool showAvailability;
  final Widget? availabilityWidget;
  final VoidCallback? onTap;

  const ListingListItemView({
    super.key,
    required this.listing,
    required this.showPrice,
    required this.showFeedback,
    required this.smallImage,
    this.bottom,
    required this.showAvailability,
    this.availabilityWidget,
    this.onTap,
  });

  Widget _buildImage() {
    return SmallListingCarousel(height: 200, listing: listing);
  }

  Widget _buildDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.parsedContent.title.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Gap.vertical.sm(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.parsedContent.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Gap.vertical.sm(),
            if (showAvailability && availabilityWidget != null)
              availabilityWidget!,
            if (showAvailability && availabilityWidget != null)
              Gap.vertical.sm(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (showPrice) ...[
                  PriceTagWidget(price: listing.parsedContent.price[0]),
                  Text(
                    AppLocalizations.of(context)!.perDayLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (showFeedback) ...[
                  const Spacer(),
                  if (showPrice) Gap.horizontal.md(),
                  ReviewsReservationsWidget(listing: listing),
                ],
              ],
            ),
            if (bottom != null) bottom!(context),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CustomPadding(
        child: smallImage
            ? Row(
                children: [
                  SizedBox(height: 100, width: 100, child: _buildImage()),
                  Gap.horizontal.lg(),
                  Expanded(child: _buildDetails(context)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(),
                  Gap.vertical.sm(),
                  _buildDetails(context),
                ],
              ),
      ),
    );
  }
}

class ListingListItemWidget extends StatefulWidget {
  final Listing listing;
  final DateTimeRange? dateRange;
  final bool showPrice;
  final bool showFeedback;
  final bool smallImage;
  final WidgetBuilder? bottom;

  /// Optional externally-provided reservations stream.
  /// When supplied the widget skips creating its own subscription.
  final StreamWithStatus<Reservation>? reservationsStream;

  const ListingListItemWidget({
    super.key,
    required this.listing,
    this.dateRange,
    this.showPrice = true,
    this.showFeedback = true,
    this.smallImage = false,
    this.bottom,
    this.reservationsStream,
  });

  @override
  State createState() => ListingListItemWidgetState();
}

class ListingListItemWidgetState extends State<ListingListItemWidget> {
  ListingListItemWidgetState();

  static const _streamInitDelay = Duration(seconds: 2);

  StreamWithStatus<Reservation>? _reservationsStream;
  StreamSubscription<List<Reservation>>? _reservationsSubscription;
  AvailabilityCubit? _availabilityCubit;
  DateRangeCubit? _localDateRangeCubit;
  List<Reservation> _latestReservations = const [];
  Timer? _initTimer;
  bool _ownsStream = false;

  @override
  initState() {
    super.initState();
    if (widget.reservationsStream != null) {
      _attachReservationsStream(widget.reservationsStream!);
    } else {
      _initTimer = Timer(_streamInitDelay, _initOwnReservationsStream);
    }
  }

  void _initOwnReservationsStream() {
    if (!mounted) return;
    final anchor = widget.listing.anchor;
    if (anchor == null) return;

    final stream = getIt<Hostr>().reservations.query(
      name: 'ListingListItem-$anchor-reservations',
      Filter(
        tags: {
          kListingRefTag: [anchor],
        },
      ),
    );
    _ownsStream = true;
    _attachReservationsStream(stream);
  }

  void _attachReservationsStream(StreamWithStatus<Reservation> stream) {
    _reservationsStream = stream;
    _reservationsSubscription = stream.list.listen((items) {
      _latestReservations = items;
      _availabilityCubit?.updateReservations(items);
    });
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_availabilityCubit != null) return;

    DateRangeCubit? dateRangeCubit;
    try {
      dateRangeCubit = BlocProvider.of<DateRangeCubit>(context);
    } catch (_) {
      dateRangeCubit = null;
    }

    _localDateRangeCubit ??= DateRangeCubit();
    _availabilityCubit = AvailabilityCubit(
      dateRangeCubit: dateRangeCubit ?? _localDateRangeCubit!,
      reservations: _latestReservations,
    );
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    _reservationsSubscription?.cancel();
    if (_ownsStream) _reservationsStream?.close();
    _availabilityCubit?.close();
    _localDateRangeCubit?.close();
    super.dispose();
  }

  Widget _buildAvailabilityText(BuildContext context) {
    final cubit = _availabilityCubit;
    if (cubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<AvailabilityCubit, AvailabilityCubitState>(
      bloc: cubit,
      builder: (context, state) {
        final hasSelectedRange = cubit.dateRangeCubit.state.dateRange != null;
        if (!hasSelectedRange) {
          return const SizedBox.shrink();
        }

        if (state is AvailabilityLoading) {
          return Text(
            'Availability: Loading',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        if (state is AvailabilityAvailable) {
          return Text(
            'Available',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        if (state is AvailabilityUnavailable) {
          return Text(
            'Unavailable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAvailability =
        _availabilityCubit?.dateRangeCubit.state.dateRange != null;

    return PreloadListingImages(
      listing: widget.listing,
      child: ListingListItemView(
        listing: widget.listing,
        showPrice: widget.showPrice,
        showFeedback: widget.showFeedback,
        smallImage: widget.smallImage,
        bottom: widget.bottom,
        showAvailability: showAvailability,
        availabilityWidget: showAvailability
            ? _buildAvailabilityText(context)
            : null,
        onTap: widget.listing.anchor != null
            ? () {
                DateTimeRange? dr = widget.dateRange;
                if (dr == null) {
                  try {
                    dr = context.read<DateRangeCubit>().state.dateRange;
                  } catch (_) {}
                }
                AutoRouter.of(context).push(
                  ListingRoute(
                    a: widget.listing.anchor!,
                    dateRangeStart: dr?.start.toIso8601String(),
                    dateRangeEnd: dr?.end.toIso8601String(),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
