import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/screens/guest/search/filters.dart';
import 'package:hostr/presentation/widgets/main.dart';

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
                    child: Listings(
                  searchController: searchController,
                ))
              ],
            ))));
  }
}
