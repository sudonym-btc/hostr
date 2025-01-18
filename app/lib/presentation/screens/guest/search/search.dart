import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/models/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/screens/guest/search/search_view.dart';

@RoutePage()
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      /// Use widget page query parameters to discover initial search parameters
      BlocProvider<DateRangeCubit>(create: (context) => DateRangeCubit()),

      /// Initialize a list with cubits for updating search settings
      BlocProvider(create: (context) => SortCubit<Listing>()),

      BlocProvider(create: (context) => FilterCubit()),
      BlocProvider(create: (context) => PostResultFilterCubit()),
      BlocProvider(
          create: (context) => ListCubit<Listing>(
              kinds: Listing.kinds,
              sortCubit: context.read<SortCubit<Listing>>(),
              postResultFilterCubit: context.read<PostResultFilterCubit>(),
              filterCubit: context.read<FilterCubit>())
            ..next()),
    ], child: SearchView());
  }
}
