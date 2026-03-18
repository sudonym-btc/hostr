import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/main.dart';

class SearchBoxWidget extends StatelessWidget {
  final FilterState filterState;
  final DateRangeState dateRangeState;
  final VoidCallback? onTap;

  /// When `true`, renders flat (no elevation, square corners) for use inside
  /// a panel. When `false`, renders as a floating pill with shadow.
  final bool embedded;

  const SearchBoxWidget({
    super.key,
    required this.filterState,
    required this.dateRangeState,
    this.onTap,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter =
        filterState.filter != null || filterState.location.trim().isNotEmpty;
    final hasDateRange = dateRangeState.dateRange != null;
    final borderRadius = BorderRadius.circular(embedded ? 0 : 50);

    final color = embedded
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).scaffoldBackgroundColor;

    return Opacity(
      opacity: embedded ? 1 : 0.85,
      child: Material(
        elevation: embedded ? 0 : 2.0,
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
