import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/main.dart';

class SearchBoxWidget extends StatelessWidget {
  const SearchBoxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.85,
      child: Material(
        elevation: 2.0, // Set the elevation
        color: Theme.of(context).scaffoldBackgroundColor,
        shadowColor: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(
          50,
        ), // Perfectly round border radius
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            50,
          ), // Perfectly round border radius
          clipBehavior: Clip.hardEdge,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0), // Blur effect
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withAlpha(0),
              ),
              child: ListTile(
                leading: Icon(Icons.search),
                title: BlocBuilder<FilterCubit, FilterState>(
                  builder: (context, state) {
                    final titleText = state.location.isEmpty
                        ? AppLocalizations.of(context)!.where
                        : state.location;
                    return Text(
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      titleText,
                    );
                  },
                ),
                subtitle: BlocBuilder<DateRangeCubit, DateRangeState>(
                  builder: (context, state) => state.dateRange == null
                      ? Text(AppLocalizations.of(context)!.when)
                      : Text(
                          formatDateRangeShort(
                            state.dateRange!,
                            Localizations.localeOf(context),
                          ),
                        ),
                ),
                trailing: Icon(Icons.filter_list),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
