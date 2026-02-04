import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/auth/auth.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/requests/requests.dart';
import 'package:hostr/injection.dart';

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
          return StreamBuilder<SubscriptionStatus>(
            stream: nostrService.messaging.threads.status,
            builder: (context, snapshot) {
              // If this user is logged in, make sure we
              if (snapshot.data is SubscriptionStatusLive) {
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
