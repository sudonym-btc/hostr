import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:intl/intl.dart';

class SearchBoxWidget extends StatelessWidget {
  const SearchBoxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
        elevation: 2.0, // Set the elevation
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            BorderRadius.circular(50), // Perfectly round border radius
        child: ClipRRect(
            borderRadius:
                BorderRadius.circular(50), // Perfectly round border radius
            child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Blur effect
                child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withAlpha(50), // Semi-transparent background
                      borderRadius: BorderRadius.circular(
                          50), // Perfectly round border radius
                    ),
                    child: ListTile(
                        leading: Icon(Icons.search),
                        title: Text(
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                            'Where?'),
                        subtitle: BlocBuilder<DateRangeCubit, DateRangeState>(
                            builder: (context, state) => state.dateRange == null
                                ? Text('When?')
                                : Text(
                                    '${formatDateShort(state.dateRange!.start, context)} - ${formatDateShort(state.dateRange!.end, context)}')),
                        trailing: Icon(Icons.filter_list))))));
  }
}

formatDateShort(DateTime date, BuildContext context) {
  final now = DateTime.now();
  final dayDateFormat =
      DateFormat('MMM d', Localizations.localeOf(context).toString());
  final yearFormat =
      DateFormat('MMM d yyyy', Localizations.localeOf(context).toString());
  return date.year == now.year
      ? dayDateFormat.format(date)
      : yearFormat.format(date);
}
