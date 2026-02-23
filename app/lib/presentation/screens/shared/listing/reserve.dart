import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/route/auth_gated_action.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class Reserve extends StatefulWidget {
  final Listing listing;
  const Reserve({super.key, required this.listing});

  @override
  State<StatefulWidget> createState() => ReserveState();
}

class ReserveState extends State<Reserve> {
  late final Future<List<Reservation>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _reservationsFuture = getIt<Hostr>().reservations.getListingReservations(
      listingAnchor: widget.listing.anchor!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reservation>>(
      future: _reservationsFuture,
      builder: (context, reservationsSnapshot) {
        final reservations = reservationsSnapshot.data ?? const <Reservation>[];
        final availabilityReady =
            reservationsSnapshot.connectionState == ConnectionState.done &&
            !reservationsSnapshot.hasError;

        return BlocBuilder<DateRangeCubit, DateRangeState>(
          builder: (context, dateState) => BlocProvider<ReservationCubit>(
            create: (context) => ReservationCubit(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                dateState.dateRange != null
                    ? GestureDetector(
                        onTap: availabilityReady
                            ? () => selectDates(
                                context,
                                context.read<DateRangeCubit>(),
                                reservations,
                                enforceContiguousAvailability: true,
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatAmount(
                                widget.listing.cost(
                                  dateState.dateRange!.start,
                                  dateState.dateRange!.end,
                                ),
                              ),
                            ),
                            Text(
                              '${formatDate(dateState.dateRange!.start)} - ${formatDate(dateState.dateRange!.end)}',
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        child: Text(
                          availabilityReady
                              ? AppLocalizations.of(context)!.selectDates
                              : AppLocalizations.of(context)!.loading,
                        ),
                        onTap: availabilityReady
                            ? () => selectDates(
                                context,
                                context.read<DateRangeCubit>(),
                                reservations,
                                enforceContiguousAvailability: true,
                              )
                            : null,
                      ),
                BlocBuilder<ReservationCubit, ReservationCubitState>(
                  builder: (context, state) {
                    return FilledButton(
                      onPressed:
                          !availabilityReady ||
                              state.status == ReservationCubitStatus.loading ||
                              dateState.dateRange == null
                          ? null
                          : () => authGatedAction(context, () async {
                              await context
                                  .read<ReservationCubit>()
                                  .createReservationRequest(
                                    listing: widget.listing,
                                    startDate: dateState.dateRange!.start,
                                    endDate: dateState.dateRange!.end,
                                    onSuccess: (reservationRequest) {
                                      AutoRouter.of(context).push(
                                        ThreadRoute(
                                          // If reservationRequest keeps thread anchor tag, retain. Otherwise parse it from the d tag
                                          anchor: reservationRequest.getDtag()!,
                                        ),
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
      },
    );
  }
}

Future<void> selectDates(
  BuildContext context,
  DateRangeCubit dateRangeCubit,
  List<Reservation> reservations, {
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

          if (!Listing.isAvailable(day, day, reservations)) {
            return false;
          }

          if (enforceContiguousAvailability && selectedStartDay != null) {
            return Listing.isAvailable(selectedStartDay, day, reservations);
          }

          return true;
        },
    initialDateRange: dateRangeCubit.state.dateRange,
  );
  dateRangeCubit.updateDateRange(picked);
}
