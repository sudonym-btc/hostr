import 'package:flutter/material.dart';
import 'package:hostr/logic/main.dart';

class SearchBox extends StatelessWidget {
  CustomSearchController searchController;
  SearchBox({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: Icon(Icons.search),
        title: Text(
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.bold),
            'Where?'),
        subtitle: Text('When?'),
        trailing: Icon(Icons.filter_list));
  }
}
