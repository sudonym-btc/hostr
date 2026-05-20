import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/route/pending_navigation.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

final _metadataGateLog = CustomLogger().scope('metadata-gate');

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
  if (hostr.auth.authState.value is LoggedIn) {
    await action();
    return;
  }

  _routeToSignIn(context, pendingRoute);
}

/// Executes [action] only after the user is authenticated and has published
/// profile metadata.
///
/// If logged out, the user is sent to sign-in. If logged in but no profile
/// metadata exists yet, the user is sent to edit-profile first. In both cases
/// [pendingRoute] is saved so the profile/sign-in flow can return the user to
/// the original surface before they retry the action.
Future<void> metadataGatedAction(
  BuildContext context, {
  required PageRouteInfo pendingRoute,
  required Future<void> Function() action,
}) async {
  final hostr = getIt<Hostr>();
  if (hostr.auth.authState.value is! LoggedIn) {
    _routeToSignIn(context, pendingRoute);
    return;
  }

  final activePubkey = hostr.auth.activePubkey;
  var hasMetadata = false;
  try {
    hasMetadata =
        activePubkey != null &&
        await hostr.metadata.loadMetadata(activePubkey) != null;
  } catch (error, stackTrace) {
    _metadataGateLog.w(
      'Profile metadata check failed before gated action',
      error: error,
      stackTrace: stackTrace,
    );
  }
  if (!context.mounted) return;

  if (!hasMetadata) {
    _routeToEditProfile(context, pendingRoute);
    return;
  }

  await action();
}

void _routeToSignIn(BuildContext context, PageRouteInfo pendingRoute) {
  if (!context.mounted) return;
  getIt<PendingNavigation>().set(pendingRoute);
  AutoRouter.of(context).push(SignInRoute());
}

void _routeToEditProfile(BuildContext context, PageRouteInfo pendingRoute) {
  if (!context.mounted) return;
  getIt<PendingNavigation>().set(pendingRoute);
  AutoRouter.of(context).navigate(EditProfileRoute());
}
