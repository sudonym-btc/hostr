import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/screens/guest/search/filters.dart';
import 'package:hostr/presentation/screens/guest/search/map_view.cubit.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<StatefulWidget> createState() {
    return SearchViewState();
  }
}

class SearchViewState extends State<SearchView> {
  PanelController panelController = PanelController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // panelController.animatePanelToSnapPoint(
    //     duration: Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final totalHeight = constraints.maxHeight;
        final listingStartHeight = totalHeight / 2;

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
            child: Scaffold(
              body: Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: listingStartHeight,
                        child: SearchMapWidget(),
                      ),
                      SafeArea(
                        child: InkWell(
                          child: CustomPadding(
                            top: 0.5,
                            child: SearchBoxWidget(),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (x) => MultiBlocProvider(
                                providers: [
                                  BlocProvider.value(
                                    value: BlocProvider.of<DateRangeCubit>(
                                      context,
                                    ),
                                  ),
                                  BlocProvider.value(
                                    value: BlocProvider.of<FilterCubit>(
                                      context,
                                    ),
                                  ),
                                  BlocProvider.value(
                                    value:
                                        BlocProvider.of<PostResultFilterCubit>(
                                          context,
                                        ),
                                  ),
                                ],
                                child: const FiltersScreen(),
                              ),
                            );
                            // Navigator.of(context).push(
                            //   MaterialPageRoute(
                            //     builder: (BuildContext context) {
                            //       return const FiltersScreen();
                            //     },
                            //     fullscreenDialog: true,
                            //   ),
                            // );
                          },
                        ),
                      ),
                    ],
                  ),
                  SlidingUpPanel(
                    controller: panelController,
                    body: Container(),
                    minHeight: listingStartHeight,
                    snapPoint: 0.5,

                    /// todo being clipped at top so not showing
                    panel: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(100), // Shadow color
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: Offset(
                              0,
                              -3,
                            ), // Shadow position (going upwards)
                          ),
                        ],
                      ),
                      child: ListingsWidget(panelController: panelController),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
