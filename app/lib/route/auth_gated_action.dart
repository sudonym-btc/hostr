import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/route/pending_navigation.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// Executes [action] immediately if the user is authenticated.
/// Otherwise stores the [pendingRoute] in [PendingNavigation] and
/// pushes the sign-in screen.
///
/// After authentication (and profile completion if needed), the startup
/// gate will consume the pending route and navigate there.
///
/// Usage:
/// ```dart
/// authGatedAction(context, pendingRoute: ListingRoute(...), action: () async {
///   await doSomethingThatRequiresAuth();
/// });
/// ```
Future<void> authGatedAction(
  BuildContext context, {
  required PageRouteInfo pendingRoute,
  required Future<void> Function() action,
}) async {
  final hostr = getIt<Hostr>();
  if (hostr.auth.authState.value == const LoggedIn()) {
    await action();
    return;
  }

  if (!context.mounted) return;
  getIt<PendingNavigation>().set(pendingRoute);
  AutoRouter.of(context).push(SignInRoute());
}
