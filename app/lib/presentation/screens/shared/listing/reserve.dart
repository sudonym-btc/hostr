import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/forms/main.dart';
import 'package:hostr/route/auth_gated_action.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

class Reserve extends StatefulWidget {
  final Listing listing;
  final List<ReservationPair> reservationPairs;

  const Reserve({
    super.key,
    required this.listing,
    required this.reservationPairs,
  });

  @override
  State<Reserve> createState() => _ReserveState();
}

class _ReserveState extends State<Reserve> {
  Amount? _customAmount;
  String? _customAmountRangeKey;

  String _rangeKey(DateTimeRange range) {
    return '${range.start.millisecondsSinceEpoch}:${range.end.millisecondsSinceEpoch}';
  }

  Amount _listingAmountFor(DateTimeRange range) {
    return widget.listing.cost(range.start, range.end);
  }

  Amount _effectiveAmountFor(DateTimeRange range) {
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
      minAmount: Amount(currency: listingAmount.currency, value: BigInt.one),
      maxAmount: listingAmount,
    );

    if (updated == null || !mounted) return;

    setState(() {
      _customAmount = updated;
      _customAmountRangeKey = _rangeKey(range);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      widget.reservationPairs,
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (widget.listing.allowBarter)
                            IconButton(
                              tooltip: 'Edit amount',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(left: 6),
                              iconSize: 18,
                              onPressed: () =>
                                  _editAmount(context, dateState.dateRange!),
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
                return FilledButton(
                  onPressed:
                      state.status == ReservationCubitStatus.loading ||
                          dateRange == null
                      ? null
                      : () => authGatedAction(context, () async {
                          await context
                              .read<ReservationCubit>()
                              .createReservationRequest(
                                listing: widget.listing,
                                startDate: dateRange.start,
                                endDate: dateRange.end,
                                amount: _effectiveAmountFor(dateRange),
                                onSuccess: (reservation) {
                                  AutoRouter.of(context).push(
                                    ThreadRoute(anchor: reservation.getDtag()!),
                                  );
                                },
                              );
                        }),
                  child: state.status == ReservationCubitStatus.loading
                      ? const AppLoadingIndicator.small()
                      : Text(AppLocalizations.of(context)!.reserve),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> selectDates(
  BuildContext context,
  DateRangeCubit dateRangeCubit,
  List<ReservationPair> reservationPairs, {
  bool enforceContiguousAvailability = true,
}) async {
  // Clear the initial selection if the previously chosen dates are no longer
  // available — the date picker asserts that initialDateRange satisfies the
  // selectableDayPredicate.
  final currentRange = dateRangeCubit.state.dateRange;
  final initialRange =
      currentRange != null &&
          Listing.isAvailable(
            currentRange.start,
            currentRange.end,
            reservationPairs,
          )
      ? currentRange
      : null;

  final picked = await showResponsiveDateRangePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: 365)),

    /// Testing blocked days
    selectableDayPredicate:
        (day, DateTime? selectedStartDay, DateTime? selectedEndDay) {
          if (!day.isAfter(DateTime.now())) {
            return false;
          }

          if (selectedStartDay != null) {
            if (!day.isAfter(selectedStartDay)) {
              return false;
            }

            if (enforceContiguousAvailability) {
              return Listing.isAvailable(
                selectedStartDay,
                day,
                reservationPairs,
              );
            }

            return true;
          }

          if (!Listing.isAvailable(day, day, reservationPairs)) {
            return false;
          }

          return true;
        },
    initialDateRange: initialRange,
  );
  dateRangeCubit.updateDateRange(picked);
}
