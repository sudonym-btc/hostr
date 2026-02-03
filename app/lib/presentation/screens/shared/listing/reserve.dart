import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

class Reserve extends StatefulWidget {
  final Listing listing;
  const Reserve({super.key, required this.listing});

  @override
  State<StatefulWidget> createState() => ReserveState();
}

class ReserveState extends State<Reserve> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateRangeCubit, DateRangeState>(
      builder: (context, dateState) => BlocProvider<ReservationCubit>(
        create: (context) => ReservationCubit(nostrService: getIt()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            dateState.dateRange != null
                ? Column(
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
                  )
                : GestureDetector(
                    child: Text(AppLocalizations.of(context)!.selectDates),
                    onTap: () =>
                        selectDates(context, context.read<DateRangeCubit>()),
                  ),
            BlocBuilder<ReservationCubit, ReservationCubitState>(
              builder: (context, state) {
                return FilledButton(
                  onPressed:
                      state.status == ReservationCubitStatus.loading ||
                          dateState.dateRange == null
                      ? null
                      : () async {
                          await context
                              .read<ReservationCubit>()
                              .createReservationRequest(
                                listing: widget.listing,
                                startDate: dateState.dateRange!.start,
                                endDate: dateState.dateRange!.end,
                                onSuccess: (id) {
                                  AutoRouter.of(
                                    context,
                                  ).push(ThreadRoute(id: id));
                                },
                              );
                        },
                  child: state.status == ReservationCubitStatus.loading
                      ? CircularProgressIndicator(
                          constraints: BoxConstraints(
                            minWidth: 5,
                            minHeight: 5,
                          ),
                        )
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
) async {
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
        (day, DateTime? selectedStartDay, DateTime? selectedEndDay) =>
            day.isAfter(DateTime.now()),
    initialDateRange: dateRangeCubit.state.dateRange,
  );
  dateRangeCubit.updateDateRange(picked);
}
