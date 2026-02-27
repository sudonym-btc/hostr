import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/route/auth_gated_action.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

class Reserve extends StatelessWidget {
  final Listing listing;
  final List<ReservationPairStatus> reservationPairs;

  const Reserve({
    super.key,
    required this.listing,
    required this.reservationPairs,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateRangeCubit, DateRangeState>(
      builder: (context, dateState) => BlocProvider<ReservationCubit>(
        create: (context) => ReservationCubit(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            dateState.dateRange != null
                ? GestureDetector(
                    onTap: () => selectDates(
                      context,
                      context.read<DateRangeCubit>(),
                      reservationPairs,
                      enforceContiguousAvailability: true,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatAmount(
                            listing.cost(
                              dateState.dateRange!.start,
                              dateState.dateRange!.end,
                            ),
                          ),
                        ),
                        Text(
                          formatDateRangeShort(
                            dateState.dateRange!,
                            Localizations.localeOf(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    child: TextButton(
                      onPressed: () => selectDates(
                        context,
                        context.read<DateRangeCubit>(),
                        reservationPairs,
                        enforceContiguousAvailability: true,
                      ),
                      child: Text(AppLocalizations.of(context)!.selectDates),
                    ),
                    onTap: () => selectDates(
                      context,
                      context.read<DateRangeCubit>(),
                      reservationPairs,
                      enforceContiguousAvailability: true,
                    ),
                  ),
            BlocBuilder<ReservationCubit, ReservationCubitState>(
              builder: (context, state) {
                return FilledButton(
                  onPressed:
                      state.status == ReservationCubitStatus.loading ||
                          dateState.dateRange == null
                      ? null
                      : () => authGatedAction(context, () async {
                          await context
                              .read<ReservationCubit>()
                              .createReservationRequest(
                                listing: listing,
                                startDate: dateState.dateRange!.start,
                                endDate: dateState.dateRange!.end,
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
  List<ReservationPairStatus> reservationPairs, {
  bool enforceContiguousAvailability = true,
}) async {
  final picked = await showDateRangePicker(
    builder: (context, child) {
      return Theme(
        data: Theme.of(context), // Reset to default light theme
        child: child!,
      );
    },
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: 365)),

    /// Testing blocked days
    selectableDayPredicate:
        (day, DateTime? selectedStartDay, DateTime? selectedEndDay) {
          if (!day.isAfter(DateTime.now())) {
            return false;
          }

          if (!Listing.isAvailable(day, day, reservationPairs)) {
            return false;
          }

          if (enforceContiguousAvailability && selectedStartDay != null) {
            return Listing.isAvailable(selectedStartDay, day, reservationPairs);
          }

          return true;
        },
    initialDateRange: dateRangeCubit.state.dateRange,
  );
  dateRangeCubit.updateDateRange(picked);
}
