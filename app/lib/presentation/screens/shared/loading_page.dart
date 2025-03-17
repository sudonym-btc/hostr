import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/logic/main.dart';

class LoadingPage extends StatelessWidget {
  final Widget child;
  const LoadingPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlobalGiftWrapCubit, ListCubitState>(
      builder: (context, state) {
        if (state.synching) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                SizedBox(height: DEFAULT_PADDING / 2.0),
                Text(
                  "Synching...",
                )
              ]),
            ),
          );
        }
        return child;
      },
    );
  }
}
