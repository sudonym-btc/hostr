import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

/// Wrapper that shows a global syncing indicator until initial data is ready.
class LoadingPage extends StatelessWidget {
  final Widget child;
  const LoadingPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final nostrService = getIt<NostrService>();

    return StreamBuilder<ThreadsSyncStatus>(
      stream: nostrService.messaging.threads.syncStatusStream,
      initialData: ThreadsSyncStatus(syncing: false, threads: []),
      builder: (context, snapshot) {
        final isSyncing = snapshot.data?.syncing ?? false;
        if (isSyncing) {
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
}
