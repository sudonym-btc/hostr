import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/animated_list_item.dart';
import 'package:hostr/presentation/component/widgets/ui/app_loading_indicator.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/ndk.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ListWidget<T extends Nip01Event> extends StatefulWidget {
  final Widget Function(dynamic) builder;
  final bool loadNextOnBottom;
  final double loadNextThreshold;
  final bool reserveBottomNavigationBarSpace;

  /// Whether list items should animate in with a staggered fade + slide.
  final bool animateItems;

  /// When a new id is emitted the list will scroll the matching item into
  /// view. The value is reset to `null` after scrolling.
  final ValueNotifier<String?>? scrollToId;

  /// Optional builder shown above the list displaying the result count.
  /// [hasMore] indicates whether additional results may exist beyond the
  /// current page.
  final Widget Function(int resultCount, bool hasMore)? resultCountBuilder;

  /// Exposed so parent widgets (e.g. [ListingsWidget]) can listen to which
  /// items are currently visible — useful for image preloading.
  final ItemPositionsListener? itemPositionsListener;

  /// Written with the id of the topmost visible data item after a user-
  /// initiated scroll comes to rest (and optionally snaps). This is NOT
  /// written after programmatic scrolls triggered via [scrollToId].
  final ValueNotifier<String?>? focusedItemId;

  final Widget Function()? emptyBuilder;

  /// When `true` the [resultCountBuilder] header is placed above the
  /// scrollable list so it stays visible while scrolling. When `false`
  /// (the default) the header scrolls with the list items.
  final bool stickyHeader;

  const ListWidget({
    super.key,
    required this.builder,
    this.emptyBuilder,
    this.loadNextOnBottom = false,
    this.loadNextThreshold = 200,
    this.reserveBottomNavigationBarSpace = false,
    this.animateItems = true,
    this.scrollToId,
    this.resultCountBuilder,
    this.itemPositionsListener,
    this.focusedItemId,
    this.stickyHeader = false,
  });

  @override
  ListWidgetState createState() => ListWidgetState<T>();
}

class ListWidgetState<T extends Nip01Event> extends State<ListWidget<T>> {
  final CustomLogger logger = CustomLogger();
  bool _loadingNextPage = false;

  final ItemScrollController _itemScrollController = ItemScrollController();
  late final ItemPositionsListener _itemPositionsListener;
  final ScrollOffsetController _scrollOffsetController =
      ScrollOffsetController();
  final ScrollOffsetListener _scrollOffsetListener =
      ScrollOffsetListener.create();
  StreamSubscription<double>? _offsetSub;
  Timer? _snapTimer;
  bool _isProgrammaticScroll = false;

  /// Number of non-data items at the top of the list. When [stickyHeader]
  /// is active the header lives outside the `ScrollablePositionedList` so
  /// this is 0; otherwise 1 when a [resultCountBuilder] is provided.
  int get _headerCount {
    if (widget.resultCountBuilder == null) return 0;
    return widget.stickyHeader ? 0 : 1;
  }

  @override
  void initState() {
    super.initState();
    _itemPositionsListener =
        widget.itemPositionsListener ?? ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
    widget.scrollToId?.addListener(_onScrollToId);
    _offsetSub = _scrollOffsetListener.changes.listen(_onScrollOffsetChanged);
  }

  @override
  void didUpdateWidget(covariant ListWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollToId != widget.scrollToId) {
      oldWidget.scrollToId?.removeListener(_onScrollToId);
      widget.scrollToId?.addListener(_onScrollToId);
    }
  }

  @override
  void dispose() {
    widget.scrollToId?.removeListener(_onScrollToId);
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    _offsetSub?.cancel();
    _snapTimer?.cancel();
    super.dispose();
  }

  // ── Scroll-to-item (deterministic, no estimation) ──────────────────

  void _onScrollToId() {
    final id = widget.scrollToId?.value;
    if (id == null) return;
    widget.scrollToId!.value = null;

    final cubit = context.read<ListCubit<T>>();
    final results = cubit.state.results;
    final headerCount = _headerCount;

    final dataIndex = results.indexWhere((item) => item.id == id);
    if (dataIndex < 0) return;

    final listIndex = dataIndex + headerCount;

    if (_itemScrollController.isAttached) {
      _isProgrammaticScroll = true;
      _itemScrollController
          .scrollTo(
            index: listIndex,
            duration: kAnimationDuration,
            curve: kAnimationCurve,
          )
          .whenComplete(() => _isProgrammaticScroll = false);
    }
  }

  // ── Update focused item after user scroll ─────────────────────────

  void _onScrollOffsetChanged(double _) {
    if (_isProgrammaticScroll) return;
    _snapTimer?.cancel();
    _snapTimer = Timer(
      const Duration(milliseconds: 50),
      _emitNearestFocusedItem,
    );
  }

  void _emitNearestFocusedItem() {
    if (!mounted || !_itemScrollController.isAttached) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Items whose trailing edge is on-screen.
    final visible = positions.where((p) => p.itemTrailingEdge > 0).toList();
    if (visible.isEmpty) return;
    visible.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));

    final topItem = visible.first;

    final cubit = context.read<ListCubit<T>>();
    final headerCount = _headerCount;
    final maxIndex = headerCount + cubit.state.results.length - 1;

    // Already well-aligned – just notify the focused item.
    if (topItem.itemLeadingEdge.abs() < 0.01) {
      _emitFocusedItem(topItem.index, headerCount, cubit);
      return;
    }

    final itemExtent = topItem.itemTrailingEdge - topItem.itemLeadingEdge;
    if (itemExtent <= 0) return;

    // If more than half the item is visible, snap to it; otherwise next.
    final snapIndex = topItem.itemLeadingEdge > -(itemExtent / 2)
        ? topItem.index
        : topItem.index + 1;

    if (snapIndex > maxIndex || snapIndex < 0) return;

    // Emit the nearest visible item without forcing the list to snap.
    _emitFocusedItem(snapIndex, headerCount, cubit);
  }

  void _emitFocusedItem(int listIndex, int headerCount, ListCubit<T> cubit) {
    final dataIndex = listIndex - headerCount;
    if (dataIndex >= 0 && dataIndex < cubit.state.results.length) {
      widget.focusedItemId?.value = cubit.state.results[dataIndex].id;
    }
  }

  // ── Load-next-on-bottom via item positions ─────────────────────────

  void _onPositionsChanged() {
    if (!widget.loadNextOnBottom || !mounted) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final cubit = context.read<ListCubit<T>>();
    final state = cubit.state;
    final headerCount = _headerCount;
    final totalItems = headerCount + state.results.length;

    // Check if the last data item (or near-last) is visible.
    final maxVisibleIndex = positions
        .map((p) => p.index)
        .reduce((a, b) => a > b ? a : b);

    if (maxVisibleIndex >= totalItems - 2) {
      _loadNext();
    }
  }

  Future<void> _loadNext() async {
    if (_loadingNextPage || !mounted) return;

    final cubit = context.read<ListCubit<T>>();
    final state = cubit.state;
    if (state.fetching || state.synching || state.hasMore == false) {
      return;
    }

    _loadingNextPage = true;
    try {
      await cubit.next();
    } finally {
      _loadingNextPage = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListCubit<T>, ListCubitState>(
      builder: (context, state) {
        // Only show centered loading if we have no results yet
        if ((state.synching || state.fetching) && state.results.isEmpty) {
          return const Center(child: AppLoadingIndicator.large());
        }

        if (state.results.isEmpty) {
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

        final isLoading = state.synching || state.fetching;
        final hasResultCountHeader = widget.resultCountBuilder != null;
        final useSticky = widget.stickyHeader && hasResultCountHeader;
        // When sticky, the header lives outside the list so items start at 0.
        final headerCount = (hasResultCountHeader && !useSticky) ? 1 : 0;
        final itemCount =
            headerCount + state.results.length + (isLoading ? 1 : 0);
        final bottomInset = widget.reserveBottomNavigationBarSpace
            ? MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight
            : 0.0;

        final list = ScrollablePositionedList.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          scrollOffsetController: _scrollOffsetController,
          scrollOffsetListener: _scrollOffsetListener,
          padding: EdgeInsets.only(
            bottom: kDefaultPadding.toDouble() + bottomInset,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Result count header as first scrollable item (non-sticky mode)
            if (hasResultCountHeader && !useSticky && index == 0) {
              return widget.resultCountBuilder!(
                state.results.length,
                state.hasMore ?? false,
              );
            }

            final adjustedIndex = index - headerCount;

            // Show loading indicator at the bottom
            if (adjustedIndex == state.results.length) {
              return CustomPadding.md(
                child: Center(child: AppLoadingIndicator.medium()),
              );
            }

            final item = state.results[adjustedIndex];
            return _KeepAliveItem(
              key: ValueKey(item.id),
              child: widget.animateItems
                  ? AnimatedListItem(
                      index: adjustedIndex,
                      child: widget.builder(item),
                    )
                  : widget.builder(item),
            );
          },
        );

        if (!useSticky) return list;

        // Sticky mode: header sits above the scrollable list.
        return Column(
          children: [
            widget.resultCountBuilder!(
              state.results.length,
              state.hasMore ?? false,
            ),
            Expanded(child: list),
          ],
        );
      },
    );
  }
}

class _KeepAliveItem extends StatefulWidget {
  final Widget child;
  const _KeepAliveItem({super.key, required this.child});

  @override
  State<_KeepAliveItem> createState() => _KeepAliveItemState();
}

class _KeepAliveItemState extends State<_KeepAliveItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
