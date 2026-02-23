import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/animated_list_item.dart';
import 'package:hostr/presentation/component/widgets/ui/app_loading_indicator.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/ndk.dart';

class ListWidget<T extends Nip01Event> extends StatefulWidget {
  final Widget Function(dynamic) builder;
  final bool loadNextOnBottom;
  final double loadNextThreshold;
  final bool reserveBottomNavigationBarSpace;
  final ScrollController? scrollController;

  /// Whether list items should animate in with a staggered fade + slide.
  final bool animateItems;

  /// When a new id is emitted the list will scroll the matching item into
  /// view. The value is reset to `null` after scrolling.
  final ValueNotifier<String?>? scrollToId;

  const ListWidget({
    super.key,
    required this.builder,
    this.loadNextOnBottom = false,
    this.loadNextThreshold = 200,
    this.reserveBottomNavigationBarSpace = false,
    this.scrollController,
    this.animateItems = true,
    this.scrollToId,
  });

  @override
  ListWidgetState createState() => ListWidgetState<T>();
}

class ListWidgetState<T extends Nip01Event> extends State<ListWidget<T>> {
  late ScrollController _scrollController;
  late bool _ownsScrollController;
  final CustomLogger logger = CustomLogger();
  bool _loadingNextPage = false;
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _attachScrollController(widget.scrollController);
    widget.scrollToId?.addListener(_onScrollToId);
  }

  @override
  void didUpdateWidget(covariant ListWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _detachScrollController();
      _attachScrollController(widget.scrollController);
    }
    if (oldWidget.scrollToId != widget.scrollToId) {
      oldWidget.scrollToId?.removeListener(_onScrollToId);
      widget.scrollToId?.addListener(_onScrollToId);
    }
  }

  @override
  void dispose() {
    widget.scrollToId?.removeListener(_onScrollToId);
    _detachScrollController();
    super.dispose();
  }

  void _onScrollToId() {
    final id = widget.scrollToId?.value;
    if (id == null) return;
    widget.scrollToId!.value = null;

    // Try precise scroll via GlobalKey first (works for already-built items).
    final key = _itemKeys[id];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: kAnimationDuration,
        curve: kAnimationCurve,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
      return;
    }

    // Fall back to index-based estimation for items not yet rendered.
    final cubit = context.read<ListCubit<T>>();
    final results = cubit.state.results;
    final index = results.indexWhere((item) => item.id == id);
    if (index < 0 || !_scrollController.hasClients) return;

    final position = _scrollController.position;
    // Estimate item height from rendered content.
    final estimatedItemHeight =
        results.isNotEmpty && position.maxScrollExtent > 0
        ? (position.maxScrollExtent + position.viewportDimension) /
              results.length
        : 200.0;
    final target = (index * estimatedItemHeight).clamp(
      0.0,
      position.maxScrollExtent,
    );

    _scrollController
        .animateTo(target, duration: kAnimationDuration, curve: kAnimationCurve)
        .then((_) {
          // After scrolling, the item should be built — refine with ensureVisible.
          final builtKey = _itemKeys[id];
          if (builtKey?.currentContext != null) {
            Scrollable.ensureVisible(
              builtKey!.currentContext!,
              duration: kAnimationDuration,
              curve: kAnimationCurve,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
            );
          }
        });
  }

  void _attachScrollController(ScrollController? externalController) {
    _ownsScrollController = externalController == null;
    _scrollController = externalController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _detachScrollController() {
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
  }

  void _onScroll() {
    if (widget.loadNextOnBottom &&
        _scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                widget.loadNextThreshold) {
      _loadNext();
    }

    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      // logger.d('Scrolling up');
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      // logger.d('Scrolling down');
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
          return Center(child: Text(AppLocalizations.of(context)!.noItems));
        }

        final isLoading = state.synching || state.fetching;
        final itemCount = state.results.length + (isLoading ? 1 : 0);
        final bottomInset = widget.reserveBottomNavigationBarSpace
            ? MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight
            : 0.0;

        return ListView.builder(
          padding: EdgeInsets.only(
            bottom: kDefaultPadding.toDouble() + bottomInset,
          ),
          controller: _scrollController,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom
            if (index == state.results.length) {
              return CustomPadding.md(
                child: Center(child: AppLoadingIndicator.medium()),
              );
            }

            final item = state.results[index];
            final itemKey = _itemKeys.putIfAbsent(item.id, () => GlobalKey());
            return _KeepAliveItem(
              key: ValueKey(item.id),
              child: KeyedSubtree(
                key: itemKey,
                child: widget.animateItems
                    ? AnimatedListItem(
                        index: index,
                        child: widget.builder(item),
                      )
                    : widget.builder(item),
              ),
            );
          },
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
