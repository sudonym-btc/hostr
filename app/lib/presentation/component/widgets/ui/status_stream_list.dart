import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/ui/app_loading_indicator.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'emty_results.dart';

class StatusStreamListWidget<T> extends StatefulWidget {
  final StreamWithStatus<T> stream;
  final Widget Function(T) builder;
  final Key? Function(T item)? itemKeyBuilder;
  final int Function(T a, T b)? sort;
  final Widget? Function(BuildContext context, T? previous, T current)?
  sectionHeaderBuilder;
  final bool reserveBottomNavigationBarSpace;

  /// Whether list items should animate in with a staggered fade + slide.
  final bool animateItems;

  /// Optional builder shown above the list displaying the result count.
  /// [hasMore] indicates whether additional results may exist beyond the
  /// current page.
  final Widget Function(int resultCount, bool hasMore)? resultCountBuilder;

  final Widget Function()? emptyBuilder;

  const StatusStreamListWidget({
    super.key,
    required this.builder,
    this.itemKeyBuilder,
    this.sort,
    this.sectionHeaderBuilder,
    this.emptyBuilder,
    this.reserveBottomNavigationBarSpace = true,
    this.animateItems = true,
    this.resultCountBuilder,
    required this.stream,
  });

  @override
  ListWidgetState createState() => ListWidgetState<T>();

  static Widget empty(
    BuildContext context, {
    Widget? leading,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return EmtyResultsWidget(
      leading:
          leading ??
          Icon(
            Icons.inbox_outlined,
            size: kIconHero,
            color: Theme.of(context).colorScheme.primary,
          ),
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }
}

class ListWidgetState<T> extends State<StatusStreamListWidget<T>> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.stream.itemsStream,
      builder: (context, _) {
        final items = List<T>.of(widget.stream.items);
        if (widget.sort != null) {
          items.sort(widget.sort);
        }

        // Only show centered loading if we have no results yet
        if (widget.stream.status.value is! StreamStatusLive) {
          return const Center(child: AppLoadingIndicator.large());
        }

        if (items.isEmpty) {
          return widget.emptyBuilder?.call() ??
              Center(
                child: Text(
                  AppLocalizations.of(context)!.noItems,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
        }

        return ListView.separated(
          addAutomaticKeepAlives: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => Container(),
          itemBuilder: (context, index) {
            final current = items[index];
            final previous = index > 0 ? items[index - 1] : null;
            final sectionHeader = widget.sectionHeaderBuilder?.call(
              context,
              previous,
              current,
            );
            final child = sectionHeader == null
                ? widget.builder(current)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [sectionHeader, widget.builder(current)],
                  );
            final key = widget.itemKeyBuilder?.call(current);

            if (key == null) {
              return child;
            }

            return KeyedSubtree(key: key, child: child);
          },
        );
      },
    );
  }
}
