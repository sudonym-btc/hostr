import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/screens/guest/search/filters.dart';
import 'package:hostr/presentation/screens/guest/search/map_view.cubit.dart';
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
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                flexibleSpace: PreferredSize(
                    preferredSize:
                        Size.fromHeight(0.0), // Set initial height to 0
                    child: InkWell(
                      child: CustomPadding(child: SearchBox()),
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
              ),
              body: SlidingUpPanel(
                controller: panelController,
                body: SearchMap(),
                minHeight: listingStartHeight,
                snapPoint: 0.5,
                panel: Listings(),
              )));
    }));
  }
}
