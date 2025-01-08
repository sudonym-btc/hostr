import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/models/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/screens/guest/search/filters.dart';
import 'package:hostr/presentation/screens/guest/search/search_results.dart';
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
  @override
  Widget build(BuildContext context) {
    // const mapHeight = 400.0; // Fixed map height

    // var totalHeight = MediaQuery.of(context).size.height;
    // var topHeight = totalHeight - listingStartHeight;

    return Scaffold(
        body: MultiBlocProvider(
            providers: [
          BlocProvider(create: (context) => DateRangeCubit()),

          /// Initialize a list with cubits for updating search settings
          BlocProvider(create: (context) => SortCubit<Listing>()),
          BlocProvider(create: (context) => FilterCubit()),
          BlocProvider(create: (context) => PostResultFilterCubit()),
          BlocProvider(
              create: (context) => ListCubit<Listing>(
                  sortCubit: context.read<SortCubit>(),
                  postResultFilterCubit: context.read<PostResultFilterCubit>(),
                  filterCubit: context.read<FilterCubit>())),
        ],
            child: SafeArea(
                child: Column(
              children: [
                InkWell(
                  child: SearchBox(),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) {
                          return const FiltersScreen();
                        },
                        fullscreenDialog: true));
                  },
                ),
                SearchResultsWidget()
              ],
            ))));
  }
}
