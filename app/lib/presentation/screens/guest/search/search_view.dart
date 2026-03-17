import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/presentation/screens/guest/search/filters.dart';
import 'package:hostr/presentation/screens/guest/search/map_view.cubit.dart';
import 'package:models/main.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<StatefulWidget> createState() {
    return SearchViewState();
  }
}

class SearchViewState extends State<SearchView> {
  final ValueNotifier<String?> _scrollToListingId = ValueNotifier(null);
  final ValueNotifier<String?> _focusedListingId = ValueNotifier(null);
  final ListingMapController _listingMapController = ListingMapController();
  double? _cachedHeight;

  // Panel drag state – replaces DraggableScrollableSheet which is
  // incompatible with ScrollablePositionedList (no external ScrollController).
  double _panelFraction = 0;
  bool _isDragging = false;
  late double _minFraction;
  late double _maxFraction;

  @override
  void initState() {
    super.initState();
    _focusedListingId.addListener(_handleFocusedListingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ListCubit<Listing>>().next();
    });
  }

  @override
  void dispose() {
    _focusedListingId.removeListener(_handleFocusedListingChanged);
    _listingMapController.dispose();
    _scrollToListingId.dispose();
    _focusedListingId.dispose();
    super.dispose();
  }

  void _handleFocusedListingChanged() {
    final listingId = _focusedListingId.value;
    if (listingId == null) {
      _listingMapController.focusAll();
      return;
    }

    _listingMapController.select(listingId);
  }

  void _resetPanel() {
    setState(() {
      _panelFraction = _minFraction;
      _isDragging = false;
    });
  }

  void _onPanelDragUpdate(DragUpdateDetails details) {
    final totalHeight = _cachedHeight ?? 0;
    if (totalHeight <= 0) return;
    setState(() {
      _isDragging = true;
      _panelFraction = (_panelFraction - details.delta.dy / totalHeight).clamp(
        _minFraction,
        _maxFraction,
      );
    });
  }

  void _onPanelDragEnd(DragEndDetails details) {
    final mid = (_minFraction + _maxFraction) / 2;
    setState(() {
      _isDragging = false;
      _panelFraction = _panelFraction > mid ? _maxFraction : _minFraction;
    });
  }

  Future<void> _showFiltersModal(BuildContext context) async {
    await showAppModal(
      context,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: BlocProvider.of<DateRangeCubit>(context)),
          BlocProvider.value(value: BlocProvider.of<FilterCubit>(context)),
          BlocProvider.value(
            value: BlocProvider.of<PostResultFilterCubit<Listing>>(context),
          ),
        ],
        child: const FiltersScreen(asBottomSheet: true),
      ),
    );
  }

  void _clearFilters(BuildContext context) {
    context.read<DateRangeCubit>().updateDateRange(null);
    context.read<FilterCubit>().clear();
  }

  Widget _buildSearchBox(BuildContext context) {
    return BlocBuilder<FilterCubit, FilterState>(
      builder: (context, filterState) {
        return BlocBuilder<DateRangeCubit, DateRangeState>(
          builder: (context, dateRangeState) {
            return SearchBoxWidget(
              filterState: filterState,
              dateRangeState: dateRangeState,
              onTap: () => _showFiltersModal(context),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return EmtyResultsWidget(
      leading: Icon(
        Icons.search_off_rounded,
        size: kIconHero,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: 'No results found',
      subtitle:
          'Try adjusting your dates or clearing filters to see more stays.',
      action: FilledButton.tonal(
        onPressed: () => _clearFilters(context),
        child: Text('Clear filters'),
      ),
    );
  }

  Widget _buildListings(
    BuildContext context, {
    bool reserveBottomNavigationBarSpace = true,
  }) {
    return ListingsWidget(
      emptyBuilder: () => _buildEmptyResults(context),
      scrollToId: _scrollToListingId,
      focusedItemId: _focusedListingId,
      reserveBottomNavigationBarSpace: reserveBottomNavigationBarSpace,
    );
  }

  Widget _buildCompactLayout(BuildContext context, BoxConstraints constraints) {
    _cachedHeight = constraints.maxHeight;
    final totalHeight = _cachedHeight!;
    final listingStartHeight = totalHeight / 2;
    const panelStopFraction = 0.5;
    final panelMaxHeight =
        listingStartHeight +
        (totalHeight - listingStartHeight) * panelStopFraction;
    _minFraction = listingStartHeight / totalHeight;
    _maxFraction = panelMaxHeight / totalHeight;
    if (_panelFraction == 0) _panelFraction = _minFraction;

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(
              height: listingStartHeight,
              child: Stack(
                children: [
                  SearchMapWidget(
                    controller: _listingMapController,
                    onMarkerTap: (id) {
                      _focusedListingId.value = id;
                      _scrollToListingId.value = id;
                    },
                  ),
                  SafeArea(
                    child: CustomPadding(
                      top: 0.5,
                      child: _buildSearchBox(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ],
        ),
        AnimatedPositioned(
          duration: _isDragging ? Duration.zero : kAnimationDuration,
          curve: kAnimationCurve,
          left: 0,
          right: 0,
          bottom: 0,
          height: totalHeight * _panelFraction,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withAlpha(120),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onVerticalDragUpdate: _onPanelDragUpdate,
                  onVerticalDragEnd: _onPanelDragEnd,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: kSpace3),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: kSpace1,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(60),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SafeArea(top: false, child: _buildListings(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return AppPageGutter(
      maxWidth: kAppWideContentMaxWidth,
      padding: EdgeInsets.zero,
      child: AppPaneLayout(
        panes: [
          AppPane(
            flex: 2,
            panelTone: AppPanelTone.primary,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchBox(context),
                  Gap.vertical.sm(),
                  Expanded(
                    child: SafeArea(
                      bottom: false,
                      child: _buildListings(
                        context,
                        reserveBottomNavigationBarSpace: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppPane(
            flex: 3,
            child: SearchMapWidget(
              controller: _listingMapController,
              onMarkerTap: (id) {
                _focusedListingId.value = id;
                _scrollToListingId.value = id;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final layout = AppLayoutSpec.of(context);

        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: BlocProvider.of<DateRangeCubit>(context)),
            BlocProvider.value(value: BlocProvider.of<FilterCubit>(context)),
            BlocProvider.value(
              value: BlocProvider.of<PostResultFilterCubit<Listing>>(context),
            ),
          ],
          child: BlocProvider(
            create: (context) => MapViewCubit(),
            child: BlocListener<FilterCubit, FilterState>(
              listener: (context, state) {
                _focusedListingId.value = null;
                _listingMapController.focusAll();
                if (!layout.showsSearchSplit) {
                  _resetPanel();
                }
              },
              child: layout.showsSearchSplit
                  ? _buildWideLayout(context)
                  : _buildCompactLayout(context, constraints),
            ),
          ),
        );
      },
    );
  }
}
