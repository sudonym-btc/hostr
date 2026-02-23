import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/screens/guest/search/filters.dart';
import 'package:hostr/presentation/screens/guest/search/map_view.cubit.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<StatefulWidget> createState() {
    return SearchViewState();
  }
}

class SearchViewState extends State<SearchView> {
  final DraggableScrollableController _panelController =
      DraggableScrollableController();
  final ValueNotifier<String?> _scrollToListingId = ValueNotifier(null);

  @override
  void dispose() {
    _scrollToListingId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final totalHeight = constraints.maxHeight;
        final listingStartHeight = totalHeight / 2;
        const panelStopFraction = 0.5;
        final panelMaxHeight =
            listingStartHeight +
            (totalHeight - listingStartHeight) * panelStopFraction;
        final minChildSize = listingStartHeight / totalHeight;
        final maxChildSize = panelMaxHeight / totalHeight;

        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: BlocProvider.of<DateRangeCubit>(context)),
            BlocProvider.value(value: BlocProvider.of<FilterCubit>(context)),
            BlocProvider.value(
              value: BlocProvider.of<PostResultFilterCubit>(context),
            ),
          ],
          child: BlocProvider(
            create: (context) => MapViewCubit(),
            child: BlocListener<FilterCubit, FilterState>(
              listener: (context, state) {
                if (_panelController.isAttached) {
                  _panelController.reset();
                }
              },
              child: Scaffold(
                body: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: listingStartHeight,
                          child: Stack(
                            children: [
                              SearchMapWidget(
                                onMarkerTap: (id) {
                                  _scrollToListingId.value = id;
                                },
                              ),
                              SafeArea(
                                child: CustomPadding(
                                  top: 0.5,
                                  child: BlocBuilder<FilterCubit, FilterState>(
                                    builder: (context, filterState) {
                                      return BlocBuilder<
                                        DateRangeCubit,
                                        DateRangeState
                                      >(
                                        builder: (context, dateRangeState) {
                                          return SearchBoxWidget(
                                            filterState: filterState,
                                            dateRangeState: dateRangeState,
                                            onTap: () async {
                                              await showAppModal(
                                                context,
                                                child: MultiBlocProvider(
                                                  providers: [
                                                    BlocProvider.value(
                                                      value:
                                                          BlocProvider.of<
                                                            DateRangeCubit
                                                          >(context),
                                                    ),
                                                    BlocProvider.value(
                                                      value:
                                                          BlocProvider.of<
                                                            FilterCubit
                                                          >(context),
                                                    ),
                                                    BlocProvider.value(
                                                      value:
                                                          BlocProvider.of<
                                                            PostResultFilterCubit
                                                          >(context),
                                                    ),
                                                  ],
                                                  child: const FiltersScreen(
                                                    asBottomSheet: true,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
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
                    DraggableScrollableSheet(
                      controller: _panelController,
                      initialChildSize: minChildSize,
                      minChildSize: minChildSize,
                      maxChildSize: maxChildSize,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(120),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, -6),
                              ),
                            ],
                          ),
                          child: ListingsWidget(
                            scrollController: scrollController,
                            scrollToId: _scrollToListingId,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
