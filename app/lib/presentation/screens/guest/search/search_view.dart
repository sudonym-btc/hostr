import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/main.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchViewState();
  }
}

class _SearchViewState extends State<SearchView> {
  @override
  Widget build(BuildContext context) {
    return SearchResultsWidget();
  }
}
