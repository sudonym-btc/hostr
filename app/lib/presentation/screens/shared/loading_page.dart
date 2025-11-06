import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/logic/main.dart';

/// Wrapper that shows a global syncing indicator until initial data is ready.
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
                const CircularProgressIndicator(),
                const SizedBox(height: DEFAULT_PADDING / 2.0),
                const Text('Synching...'),
              ]),
            ),
          );
        }
        return child;
      },
    );
  }
}
