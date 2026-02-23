import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/image_preloader.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/list.dart';
import 'package:models/main.dart';

import 'listing_list_item.dart';

class ListingsWidget extends StatefulWidget {
  final ScrollController? scrollController;

  /// When a new id is emitted the list scrolls the matching item into view.
  final ValueNotifier<String?>? scrollToId;

  const ListingsWidget({super.key, this.scrollController, this.scrollToId});

  @override
  State<ListingsWidget> createState() => _ListingsWidgetState();
}

class _ListingsWidgetState extends State<ListingsWidget> {
  static const int _preloadWindowSize = 5;

  final Set<String> _preloadedListingIds = <String>{};
  ScrollController? _ownedController;

  ScrollController get _effectiveController =>
      widget.scrollController ?? (_ownedController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_onScrollPreload);
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadNextWindow());
  }

  @override
  void didUpdateWidget(covariant ListingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      final oldController = oldWidget.scrollController ?? _ownedController;
      oldController?.removeListener(_onScrollPreload);
      _effectiveController.addListener(_onScrollPreload);
      WidgetsBinding.instance.addPostFrameCallback((_) => _preloadNextWindow());
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onScrollPreload);
    _ownedController?.dispose();
    super.dispose();
  }

  void _onScrollPreload() {
    _preloadNextWindow();
  }

  Future<void> _preloadNextWindow() async {
    if (!mounted) return;

    final state = context.read<ListCubit<Listing>>().state;
    final results = state.results;
    if (results.isEmpty) return;

    final controller = _effectiveController;

    // Approximation is sufficient for ahead-of-time preloading.
    const estimatedItemExtent = 320.0;
    final firstVisible = controller.hasClients
        ? (controller.position.pixels / estimatedItemExtent).floor()
        : 0;
    final visibleCount = controller.hasClients
        ? (controller.position.viewportDimension / estimatedItemExtent).ceil() +
              1
        : 1;

    final start = (firstVisible + visibleCount).clamp(0, results.length);
    final end = (start + _preloadWindowSize).clamp(0, results.length);
    if (start >= end) return;

    final preloader = getIt<ImagePreloader>();
    final futures = <Future<void>>[];

    for (var i = start; i < end; i++) {
      final listing = results[i];
      if (_preloadedListingIds.contains(listing.id)) continue;

      final refs = listing.parsedContent.images;
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
        reserveBottomNavigationBarSpace: true,
        scrollController: _effectiveController,
        scrollToId: widget.scrollToId,
        builder: (el) {
          return ListingListItemWidget(
            listing: el,
            // dateRange: searchController.state.dateRange,
          );
        },
      ),
    );
  }
}
