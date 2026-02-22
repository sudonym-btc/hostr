import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// Executes [action] immediately if the user is authenticated.
/// Otherwise pushes the sign-in → onboarding flow and then
/// executes [action] once complete.
///
/// The current page stays in the navigation stack so the user
/// returns to it naturally after authenticating.
///
/// Usage:
/// ```dart
/// authGatedAction(context, () async {
///   await doSomethingThatRequiresAuth();
/// });
/// ```
Future<void> authGatedAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  final hostr = getIt<Hostr>();
  if (hostr.auth.authState.value == const LoggedIn()) {
    await action();
    return;
  }

  // User is not authenticated — push sign-in.
  // The listing / current page stays in the stack.
  if (!context.mounted) return;
  AutoRouter.of(context).push(
    SignInRoute(
      onSuccess: () {
        // After sign-in, replace sign-in with onboarding.
        // Onboarding will pop back when `popOnComplete` is true,
        // returning the user to their original page.
        AutoRouter.of(context).replace(OnboardingRoute(popOnComplete: true));
      },
    ),
  );
}
