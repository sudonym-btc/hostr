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

  /// Whether to keep list items alive when scrolled off screen.
  /// Defaults to `true`. Set to `false` when items hold expensive resources
  /// (e.g. Trade cubits with live Nostr subscriptions).
  final bool addAutomaticKeepAlives;

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
    this.addAutomaticKeepAlives = true,
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
  // Tracks the stream instance the current StreamBuilder is subscribed to.
  // When the parent passes a different StreamWithStatus (e.g. after
  // logout → login, where userSubscriptions.start() replaces the late field
  // with a new object), the key changes and Flutter tears down the old
  // StreamBuilder and creates a fresh one subscribed to the new stream.
  late StreamWithStatus<T> _trackedStream;

  @override
  void initState() {
    super.initState();
    _trackedStream = widget.stream;
  }

  @override
  void didUpdateWidget(covariant StatusStreamListWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.stream, widget.stream)) {
      setState(() => _trackedStream = widget.stream);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      key: ObjectKey(_trackedStream),
      stream: _trackedStream.itemsStream,
      builder: (context, _) {
        final items = List<T>.of(_trackedStream.items);
        if (widget.sort != null) {
          items.sort(widget.sort);
        }

        // Only show centered loading if we have no results yet
        if (_trackedStream.status.value is! StreamStatusLive) {
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
          padding: EdgeInsets.zero,
          addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
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
