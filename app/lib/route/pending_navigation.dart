import 'package:auto_route/auto_route.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

/// Centralized store for a single pending navigation target.
///
/// When a user tries to reach a guarded route (e.g. tapping Reserve while
/// logged out), the target route is stored here before redirecting to sign-in.
/// After authentication (and profile completion if needed), the startup gate
/// consumes the pending route and navigates there.
///
/// **Writers:** [AuthGuard] and [authGatedAction] — exactly two places.
/// **Consumer:** The startup gate listener — exactly one place.
@singleton
class PendingNavigation {
  final _log = CustomLogger();
  PageRouteInfo? _route;

  /// Whether a pending destination exists.
  bool get hasPending => _route != null;

  /// Store a route the user wants to reach after authentication.
  ///
  /// Overwrites any previously stored route (only one pending target
  /// at a time makes sense — the most recent intent wins).
  void set(PageRouteInfo route) {
    _log.d('PendingNavigation.set: ${route.routeName}');
    _route = route;
  }

  /// Pop and return the pending route, clearing it from the store.
  ///
  /// Returns `null` if nothing was pending.
  PageRouteInfo? consume() {
    final r = _route;
    _route = null;
    _log.d('PendingNavigation.consume: ${r?.routeName ?? 'null'}');
    return r;
  }

  /// Discard any pending route without navigating to it.
  void clear() {
    _log.d('PendingNavigation.clear (was: ${_route?.routeName ?? 'null'})');
    _route = null;
  }
}
