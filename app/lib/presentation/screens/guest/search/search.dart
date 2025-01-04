import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/screens/guest/search/filters.dart';
import 'package:hostr/presentation/widgets/main.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

@RoutePage()
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchScreenState();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  late CustomSearchController searchController;
  @override
  void initState() {
    searchController = CustomSearchController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: BlocProvider<CustomSearchController>(
            create: (context) => searchController,
            child: SafeArea(
                child: Column(
              children: [
                InkWell(
                  child: SearchBox(
                    searchController: searchController,
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) {
                          return const FiltersScreen();
                        },
                        fullscreenDialog: true));
                  },
                ),
                Expanded(
                    child: SearchMap(
                  searchController: searchController,
                )),
                Expanded(
                    child: SlidingUpPanel(
                        panel: Column(
                          children: [
                            Container(
                              height: 30,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Listings(
                                searchController: searchController,
                              ),
                            ),
                          ],
                        ),
                        minHeight: MediaQuery.of(context).size.height / 2.5,
                        maxHeight: MediaQuery.of(context).size.height,
                        body: Container())),
              ],
            ))));
  }
}
