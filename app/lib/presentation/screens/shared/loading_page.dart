import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// Wrapper that shows a global syncing indicator until initial data is ready.
class LoadingPage extends StatelessWidget {
  final Widget child;
  const LoadingPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final nostrService = getIt<Hostr>();
    return StreamBuilder<AuthState>(
      stream: getIt<Hostr>().auth.authState,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data is LoggedIn) {
          return StreamBuilder<StreamStatus>(
            stream: nostrService.messaging.threads.status,
            builder: (context, snapshot) {
              // If this user is logged in, make sure we
              if (snapshot.data is StreamStatusLive) {
                return child;
              }
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
            },
          );
        }
        return child;
      },
    );
  }
}
