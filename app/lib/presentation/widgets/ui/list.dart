import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';

class ListWidget extends StatelessWidget {
  const ListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListCubit, ListCubitState>(
      builder: (context, state) {
        // if (state.) {
        return ListView.builder(
          itemCount: state.results.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(state.results[index].toString()),
            );
          },
        );
        // }
        // return Center(child: CircularProgressIndicator());
      },
    );
  }
}
