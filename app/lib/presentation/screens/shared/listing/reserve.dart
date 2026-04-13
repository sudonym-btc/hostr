import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/forms/main.dart';
import 'package:hostr/route/auth_gated_action.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

class Reserve extends StatefulWidget {
  final Listing listing;
  final Stream<List<Validation<ReservationGroup>>> reservationGroupItemsStream;

  /// Status stream from the underlying [StreamWithStatus].
  /// When provided, the reserve button is disabled until the status
  /// transitions to [StreamStatusQueryComplete] or [StreamStatusLive].
  final ValueStream<StreamStatus>? reservationsStatus;

  const Reserve({
    super.key,
    required this.listing,
    required this.reservationGroupItemsStream,
    this.reservationsStatus,
  });

  @override
  State<Reserve> createState() => _ReserveState();
}

class _ReserveState extends State<Reserve> {
  DenominatedAmount? _customAmount;
  String? _customAmountRangeKey;

  String _rangeKey(DateTimeRange range) {
    return '${range.start.millisecondsSinceEpoch}:${range.end.millisecondsSinceEpoch}';
  }

  DenominatedAmount _listingAmountFor(DateTimeRange range) {
    return widget.listing.cost(start: range.start, end: range.end);
  }

  DenominatedAmount _effectiveAmountFor(DateTimeRange range) {
    final key = _rangeKey(range);
    if (_customAmount != null && _customAmountRangeKey == key) {
      return _customAmount!;
    }
    return _listingAmountFor(range);
  }

  Future<void> _editAmount(BuildContext context, DateTimeRange range) async {
    final listingAmount = _listingAmountFor(range);
    final updated = await AmountEditorBottomSheet.show(
      context,
      initialAmount: _effectiveAmountFor(range),
      minAmount: DenominatedAmount(
        denomination: listingAmount.denomination,
        value: BigInt.one,
        decimals: listingAmount.decimals,
      ),
      maxAmount: listingAmount,
    );

    if (updated == null || !mounted) return;

    setState(() {
      _customAmount = updated;
      _customAmountRangeKey = _rangeKey(range);
    });
  }

  PageRouteInfo _reservePendingRoute(DateTimeRange? dateRange) {
    return ListingRoute(
      a: widget.listing.naddr()!,
      dateRangeStart: dateRange?.start.toIso8601String(),
      dateRangeEnd: dateRange?.end.toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Validation<ReservationGroup>>>(
      stream: widget.reservationGroupItemsStream,
      builder: (context, reservationGroupsSnapshot) {
        final reservationGroups =
            (reservationGroupsSnapshot.data ??
                    const <Validation<ReservationGroup>>[])
                .whereType<Valid<ReservationGroup>>()
                .map((validated) => validated.event)
                .toList(growable: false);

        return BlocBuilder<DateRangeCubit, DateRangeState>(
          builder: (context, dateState) => BlocProvider<ReservationCubit>(
            create: (context) => ReservationCubit(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DateRangeButtons(
                        small: true,
                        single: true,
                        selectedDateRange: dateState.dateRange,
                        onTap: () => selectDates(
                          context,
                          context.read<DateRangeCubit>(),
                          reservationGroups,
                          enforceContiguousAvailability: true,
                        ),
                      ),
                      if (dateState.dateRange != null) ...[
                        Gap.horizontal.sm(),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  formatAmount(
                                    _effectiveAmountFor(dateState.dateRange!),
                                    exact: false,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              if (widget.listing.negotiable)
                                IconButton(
                                  tooltip: 'Edit amount',
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(left: 6),
                                  iconSize: 18,
                                  onPressed: () => _editAmount(
                                    context,
                                    dateState.dateRange!,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                BlocBuilder<ReservationCubit, ReservationCubitState>(
                  builder: (context, state) {
                    final dateRange = dateState.dateRange;
                    final statusStream = widget.reservationsStatus;
                    return StreamBuilder<StreamStatus>(
                      stream: statusStream,
                      initialData: statusStream?.valueOrNull,
                      builder: (context, statusSnapshot) {
                        final reservationsReady =
                            statusStream == null ||
                            statusSnapshot.data is StreamStatusQueryComplete ||
                            statusSnapshot.data is StreamStatusLive;
                        return FilledButton(
                          onPressed:
                              state.status == ReservationCubitStatus.loading ||
                                  dateRange == null ||
                                  !reservationsReady
                              ? null
                              : () => authGatedAction(
                                  context,
                                  pendingRoute: _reservePendingRoute(dateRange),
                                  action: () async {
                                    await context
                                        .read<ReservationCubit>()
                                        .createReservationRequest(
                                          listing: widget.listing,
                                          startDate: dateRange.start,
                                          endDate: dateRange.end,
                                          amount: _effectiveAmountFor(
                                            dateRange,
                                          ),
                                          onSuccess: (reservation) {
                                            final anchor =
                                                Threads.conversationIdentifier(
                                                  [
                                                    getIt<Hostr>().auth
                                                        .getActiveKey()
                                                        .publicKey,
                                                    widget.listing.pubKey,
                                                  ],
                                                  conversationTag: reservation
                                                      .getDtag()!,
                                                );
                                            AutoRouter.of(
                                              context,
                                            ).push(ThreadRoute(anchor: anchor));
                                          },
                                        );
                                  },
                                ),
                          child: state.status == ReservationCubitStatus.loading
                              ? const AppLoadingIndicator.small()
                              : !reservationsReady
                              ? const AppLoadingIndicator.small()
                              : Text(AppLocalizations.of(context)!.reserve),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> selectDates(
  BuildContext context,
  DateRangeCubit dateRangeCubit,
  List<ReservationGroup> reservationGroups, {
  bool enforceContiguousAvailability = true,
}) async {
  bool selectableDayPredicate(
    DateTime day,
    DateTime? selectedStartDay,
    DateTime? selectedEndDay,
  ) {
    if (!day.isAfter(DateTime.now())) {
      return false;
    }

    if (selectedStartDay != null) {
      if (!day.isAfter(selectedStartDay)) {
        return false;
      }

      if (enforceContiguousAvailability) {
        return Listing.isAvailable(selectedStartDay, day, reservationGroups);
      }

      return true;
    }

    if (!Listing.isAvailable(day, day, reservationGroups)) {
      return false;
    }

    return true;
  }

  // Clear the initial selection if the previously chosen dates don't satisfy
  // the selectableDayPredicate — the date picker asserts this on init.
  final currentRange = dateRangeCubit.state.dateRange;
  final initialRange =
      currentRange != null &&
          selectableDayPredicate(currentRange.start, null, null) &&
          selectableDayPredicate(currentRange.end, currentRange.start, null)
      ? currentRange
      : null;

  final picked = await showResponsiveDateRangePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: 365)),
    selectableDayPredicate: selectableDayPredicate,
    initialDateRange: initialRange,
  );
  dateRangeCubit.updateDateRange(picked);
}
