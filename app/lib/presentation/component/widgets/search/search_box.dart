import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/main.dart';

class SearchBoxWidget extends StatelessWidget {
  final FilterState filterState;
  final DateRangeState dateRangeState;
  const SearchBoxWidget({
    super.key,
    required this.filterState,
    required this.dateRangeState,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter =
        filterState.filter != null || filterState.location.trim().isNotEmpty;
    final hasDateRange = dateRangeState.dateRange != null;
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
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withAlpha(0),
                ),
                child: ListTile(
                  leading: Icon(Icons.search),
                  title: Text(
                    filterState.location.isEmpty
                        ? AppLocalizations.of(context)!.where
                        : filterState.location,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    dateRangeState.dateRange == null
                        ? AppLocalizations.of(context)!.when
                        : formatDateRangeShort(
                            dateRangeState.dateRange!,
                            Localizations.localeOf(context),
                          ),
                  ),
                  trailing: (hasActiveFilter || hasDateRange)
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            context.read<DateRangeCubit>().updateDateRange(
                              null,
                            );
                            context.read<FilterCubit>().clear();
                          },
                        )
                      : const Icon(Icons.filter_list),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
