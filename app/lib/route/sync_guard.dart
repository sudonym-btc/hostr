import 'package:auto_route/auto_route.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

/// Guard that prevents navigation to logged-in routes until messages are synced.
///
/// When a user tries to access a logged-in route while messages are still syncing,
/// this guard will block the navigation. The [LoadingPage] overlay will display
/// a loading indicator until syncing is complete.
class SyncGuard extends AutoRouteGuard {
  CustomLogger logger = CustomLogger();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    logger.d('SyncGuard checking message sync status');
    final nostrService = getIt<Hostr>();

    // If messages are syncing, don't allow navigation - LoadingPage will show an overlay
    if (nostrService.messaging.threads.subscriptionCompleted == false) {
      logger.d('SyncGuard: Messages still syncing, blocking navigation');
      // Don't call resolver.next() to block navigation
      return;
    }

    logger.d('SyncGuard: Messages synced, allowing navigation');
    resolver.next(true);
  }
}
