import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ListingsWidget extends StatefulWidget {
  /// When a new id is emitted the list scrolls the matching item into view.
  final ValueNotifier<String?>? scrollToId;

  /// Written by the list when a user scroll comes to rest on an item.
  final ValueNotifier<String?>? focusedItemId;

  final bool reserveBottomNavigationBarSpace;
  final Widget Function()? emptyBuilder;

  const ListingsWidget({
    super.key,
    this.scrollToId,
    this.focusedItemId,
    this.reserveBottomNavigationBarSpace = true,
    this.emptyBuilder,
  });

  @override
  State<ListingsWidget> createState() => _ListingsWidgetState();
}

class _ListingsWidgetState extends State<ListingsWidget> {
  static const int _preloadWindowSize = 5;

  final Set<String> _preloadedListingIds = <String>{};
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadNextWindow());
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  void _onPositionsChanged() {
    _preloadNextWindow();
  }

  Future<void> _preloadNextWindow() async {
    if (!mounted) return;

    final state = context.read<ListCubit<Listing>>().state;
    final results = state.results;
    if (results.isEmpty) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find the last visible index, accounting for a possible header at index 0.
    final maxVisibleIndex = positions
        .map((p) => p.index)
        .reduce((a, b) => a > b ? a : b);

    // Header occupies index 0 in the list, so data indices are offset by 1.
    final start = maxVisibleIndex.clamp(0, results.length);
    final end = (start + _preloadWindowSize).clamp(0, results.length);
    if (start >= end) return;

    final preloader = getIt<ImagePreloader>();
    final futures = <Future<void>>[];

    for (var i = start; i < end; i++) {
      final listing = results[i];
      if (_preloadedListingIds.contains(listing.id)) continue;

      final refs = listing.images;
      if (refs.isEmpty) {
        _preloadedListingIds.add(listing.id);
        continue;
      }

      // Preload only the hero image per off-screen card to keep memory/network bounded.
      futures.add(
        preloader.preloadImages([refs.first], pubkey: listing.pubKey).then((_) {
          _preloadedListingIds.add(listing.id);
        }),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures, eagerError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ListCubit<Listing>, ListCubitState>(
      listener: (context, state) {
        _preloadNextWindow();
      },
      child: ListWidget<Listing>(
        loadNextOnBottom: true,
        reserveBottomNavigationBarSpace: widget.reserveBottomNavigationBarSpace,
        emptyBuilder: widget.emptyBuilder,
        scrollToId: widget.scrollToId,
        focusedItemId: widget.focusedItemId,
        itemPositionsListener: _itemPositionsListener,
        resultCountBuilder: (count, hasMore) => CustomPadding(
          bottom: 0,
          top: 0,
          child: Row(
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.searchResultCount(count, hasMore ? 'true' : 'false'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        builder: (el) {
          return ListingListItemWidget(listing: el);
        },
      ),
    );
  }
}
