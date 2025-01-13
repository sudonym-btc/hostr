import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/screens/guest/search/filters.dart';
import 'package:hostr/presentation/screens/guest/search/map_view.cubit.dart';
import 'package:hostr/presentation/screens/shared/drawer/drawer.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SearchResultsWidget extends StatefulWidget {
  const SearchResultsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return SearchResultsWidgetState();
  }
}

class SearchResultsWidgetState extends State<SearchResultsWidget> {
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
    return Expanded(child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final totalHeight = constraints.maxHeight;
      final listingStartHeight = totalHeight / 2;

      return BlocProvider(
          create: (context) => MapViewCubit(),
          child: Scaffold(
              extendBodyBehindAppBar: true,
              endDrawer: Drawer(
                  // Add a ListView to the drawer. This ensures the user can scroll
                  // through the options in the drawer if there isn't enough vertical
                  // space to fit everything.
                  child: DrawerWidget()),
              body: SlidingUpPanel(
                controller: panelController,
                body: Stack(children: [
                  SearchMapWidget(),
                  SafeArea(
                      child: InkWell(
                    child: CustomPadding(child: SearchBoxWidget()),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return const FiltersScreen();
                          },
                          fullscreenDialog: true,
                        ),
                      );
                    },
                  )),
                ]),
                minHeight: listingStartHeight,
                snapPoint: 0.5,
                panel: ListingsWidget(),
              )));
    }));
  }
}
