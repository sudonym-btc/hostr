import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/main.dart';

class ListWidget extends StatelessWidget {
  final Widget Function(dynamic) builder;
  const ListWidget({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListCubit<Listing>, ListCubitState>(
      builder: (context, state) {
        // if (state.) {
        return ListView.builder(
            itemCount: state.results.length,
            itemBuilder: (context, index) => builder(state.results[index]));
        // }
        // return Center(child: CircularProgressIndicator());
      },
    );
  }
}
