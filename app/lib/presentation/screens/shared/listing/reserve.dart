import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hostr/logic/forms/amount_field_controller.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/forms/main.dart';
import 'package:hostr/route/auth_gated_action.dart';
import 'package:hostr/route/listing_reservation_route.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

class Reserve extends StatefulWidget {
  final Listing listing;
  final Stream<List<Validation<OrderGroup>>> reservationGroupItemsStream;
  final DenominatedAmount? initialAmount;
  final bool autoReserve;

  /// Status stream from the underlying [StreamWithStatus].
  /// When provided, the reserve button is disabled until the status
  /// transitions to [StreamStatusQueryComplete] or [StreamStatusLive].
  final ValueStream<StreamStatus>? reservationsStatus;

  const Reserve({
    super.key,
    required this.listing,
    required this.reservationGroupItemsStream,
    this.initialAmount,
    this.autoReserve = false,
    this.reservationsStatus,
  });

  @override
  State<Reserve> createState() => _ReserveState();
}

class _ReserveState extends State<Reserve> {
  final AmountFieldController _amountController = AmountFieldController();
  DenominatedAmount? _customAmount;
  String? _customAmountRangeKey;
  String? _amountControllerSyncKey;
  String? _initialAmountSyncKey;
  bool _autoReserveAttempted = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _rangeKey(DateTimeRange range) {
    return '${range.start.millisecondsSinceEpoch}:${range.end.millisecondsSinceEpoch}';
  }

  DenominatedAmount _listingAmountFor(DateTimeRange range) {
    return widget.listing.cost(start: range.start, end: range.end);
  }

  DenominatedAmount? _customAmountFor(DateTimeRange? range) {
    if (range == null) return null;
    final key = _rangeKey(range);
    if (_customAmount != null && _customAmountRangeKey == key) {
      return _customAmount!;
    }
    return null;
  }

  DenominatedAmount _effectiveAmountFor(DateTimeRange range) {
    return _customAmountFor(range) ?? _listingAmountFor(range);
  }

  String _amountKey(DenominatedAmount amount) {
    return '${amount.denomination}:${amount.decimals}:${amount.value}';
  }

  void _syncAmountController(DateTimeRange range) {
    _syncInitialAmount(range);
    final amount = _effectiveAmountFor(range);
    final syncKey = '${_rangeKey(range)}:${_amountKey(amount)}';
    if (_amountControllerSyncKey == syncKey) {
      return;
    }
    _amountControllerSyncKey = syncKey;
    _amountController.setState(amount);
  }

  void _syncInitialAmount(DateTimeRange range) {
    if (!widget.listing.negotiable) return;
    final initialAmount = widget.initialAmount;
    if (initialAmount == null) return;
    final syncKey = '${_rangeKey(range)}:${_amountKey(initialAmount)}';
    if (_initialAmountSyncKey == syncKey) return;
    _initialAmountSyncKey = syncKey;
    _customAmount = initialAmount;
    _customAmountRangeKey = _rangeKey(range);
  }

  Widget _buildBasePrice(BuildContext context) {
    final price = widget.listing.prices.first;
    final amount = formatAmount(price.amount, exact: false);
    final frequency = price.frequency?.nip99Name;
    final amountStyle = Theme.of(
      context,
    ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      mainAxisSize: MainAxisSize.min,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            amount,
            overflow: TextOverflow.ellipsis,
            style: amountStyle,
          ),
        ),
        if (frequency != null)
          Text(' / $frequency', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  PageRouteInfo _reservePendingRoute(
    DateTimeRange? dateRange, {
    bool autoReserve = false,
  }) {
    final reserveAmount = _customAmountFor(dateRange);
    return ListingRoute(
      a: widget.listing.naddr()!,
      dateRangeStart: dateRange?.start.toIso8601String(),
      dateRangeEnd: dateRange?.end.toIso8601String(),
      reserveAmountValue: reserveAmountValueQuery(reserveAmount),
      reserveAmountDenomination: reserveAmountDenominationQuery(reserveAmount),
      reserveAmountDecimals: reserveAmountDecimalsQuery(reserveAmount),
      autoReserve: autoReserveQuery(autoReserve),
    );
  }

  Future<void> _submitReservation(
    BuildContext context,
    DateTimeRange dateRange,
  ) async {
    await metadataGatedAction(
      context,
      pendingRoute: _reservePendingRoute(dateRange, autoReserve: true),
      action: () async {
        if (!context.mounted) return;
        await context.read<ReservationCubit>().createOrderRequest(
          listing: widget.listing,
          startDate: dateRange.start,
          endDate: dateRange.end,
          amount: _effectiveAmountFor(dateRange),
          onSuccess: (reservation) {
            final anchor = Threads.conversationId(reservation.getDtag()!, [
              getIt<Hostr>().auth.getActiveKey().publicKey,
              widget.listing.pubKey,
            ]);
            AutoRouter.of(context).push(ThreadRoute(anchor: anchor));
          },
        );
      },
    );
  }

  void _scheduleAutoReserveIfReady({
    required BuildContext context,
    required DateTimeRange? dateRange,
    required bool canReserve,
  }) {
    if (!widget.autoReserve || _autoReserveAttempted || !canReserve) return;
    if (dateRange == null) return;
    _autoReserveAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_submitReservation(context, dateRange));
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Validation<OrderGroup>>>(
      stream: widget.reservationGroupItemsStream,
      builder: (context, reservationGroupsSnapshot) {
        final reservationGroups =
            (reservationGroupsSnapshot.data ?? const <Validation<OrderGroup>>[])
                .whereType<Valid<OrderGroup>>()
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
                      Gap.horizontal.sm(),
                      if (dateState.dateRange == null) ...[
                        // No dates selected — show base price / period.
                        if (widget.listing.prices.isNotEmpty)
                          Flexible(child: _buildBasePrice(context)),
                      ] else ...[
                        Flexible(
                          child: Builder(
                            builder: (context) {
                              final dateRange = dateState.dateRange!;
                              final listingAmount = _listingAmountFor(
                                dateRange,
                              );
                              _syncAmountController(dateRange);

                              return AmountTapInput(
                                key: const ValueKey(
                                  'listing_reserve_amount_input',
                                ),
                                controller: _amountController,
                                min: listingPricesMin,
                                max: [listingAmount],
                                enabled: true,
                                editable: widget.listing.negotiable,
                                exact: false,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                                onChanged: (amount) {
                                  if (amount == null) {
                                    return;
                                  }
                                  setState(() {
                                    _customAmount = amount;
                                    _customAmountRangeKey = _rangeKey(
                                      dateRange,
                                    );
                                    _amountControllerSyncKey =
                                        '${_rangeKey(dateRange)}:${_amountKey(amount)}';
                                  });
                                },
                              );
                            },
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
                        final canReserve =
                            state.status != ReservationCubitStatus.loading &&
                            dateRange != null &&
                            reservationsReady;
                        _scheduleAutoReserveIfReady(
                          context: context,
                          dateRange: dateRange,
                          canReserve: canReserve,
                        );
                        return FilledButton(
                          key: const ValueKey('listing_reserve_button'),
                          onPressed: canReserve
                              ? () => _submitReservation(context, dateRange)
                              : null,
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
  List<OrderGroup> reservationGroups, {
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
