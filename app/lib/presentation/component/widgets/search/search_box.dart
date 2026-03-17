import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';

class SearchBoxWidget extends StatelessWidget {
  final FilterState filterState;
  final DateRangeState dateRangeState;
  final VoidCallback? onTap;
  const SearchBoxWidget({
    super.key,
    required this.filterState,
    required this.dateRangeState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    final isWide = layout.showsSearchSplit;
    final hasActiveFilter =
        filterState.filter != null || filterState.location.trim().isNotEmpty;
    final hasDateRange = dateRangeState.dateRange != null;
    final borderRadius = BorderRadius.circular(isWide ? 0 : 50);

    final color = isWide
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).scaffoldBackgroundColor;

    return Opacity(
      opacity: isWide ? 1 : 0.85,
      child: Material(
        elevation: isWide ? 0 : 2.0,
        color: color,
        shadowColor: color,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: ListTile(
            minVerticalPadding: 0,
            leading: Icon(Icons.search),
            titleAlignment: ListTileTitleAlignment.center,
            title: Text(
              filterState.location.isEmpty
                  ? AppLocalizations.of(context)!.where
                  : filterState.location,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
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
                      context.read<DateRangeCubit>().updateDateRange(null);
                      context.read<FilterCubit>().clear();
                    },
                  )
                : const Icon(Icons.filter_list),
          ),
        ),
      ),
    );
  }
}
