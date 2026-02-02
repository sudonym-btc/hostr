import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';

/// Wrapper that shows a global syncing indicator until initial data is ready.
class LoadingPage extends StatelessWidget {
  final Widget child;
  const LoadingPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final nostrService = getIt<Hostr>();

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is LoggedIn) {
          return StreamBuilder<ThreadsSyncStatus>(
            stream: nostrService.messaging.threads.syncStatusStream,
            builder: (context, snapshot) {
              final isCompleted = snapshot.data?.completed ?? false;
              if (!isCompleted) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Syncing messages...',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return child;
            },
          );
        }
        return child;
      },
    );
  }
}
