import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';

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
    final borderRadius = embedded ? AppBorderRadii.none : AppBorderRadii.full;

    final color = AppSurface.stepped(context, 1);

    // Count extra filters beyond location & date range.
    // Promoted tag keys: T = type, c = guests, s = features, N = negotiable.
    // g = geohash (part of location) — excluded from the count.
    final tags = filterState.filter?.tags ?? {};
    final extraFilterCount = tags.keys.where((k) => k != 'g').length;

    final whenText = dateRangeState.dateRange == null
        ? AppLocalizations.of(context)!.when
        : formatDateRangeShort(
            dateRangeState.dateRange!,
            Localizations.localeOf(context),
          );

    final subtitle = extraFilterCount > 0
        ? '$whenText (+$extraFilterCount ${extraFilterCount == 1 ? 'filter' : 'filters'})'
        : whenText;

    return Opacity(
      opacity: embedded ? 1 : 0.85,
      child: Material(
        elevation: embedded ? 0 : 2.0,
        color: color,
        shadowColor: embedded ? Colors.transparent : color,
        borderRadius: borderRadius,
        child: InkWell(
          key: const ValueKey('explore_search_box_button'),
          onTap: onTap,
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          filterState.location.isEmpty
                              ? AppLocalizations.of(context)!.where
                              : filterState.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasActiveFilter || hasDateRange)
                    IconButton(
                      key: const ValueKey('explore_clear_filters_button'),
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<DateRangeCubit>().updateDateRange(null);
                        context.read<FilterCubit>().clear();
                      },
                    )
                  else
                    const Icon(Icons.filter_list),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
