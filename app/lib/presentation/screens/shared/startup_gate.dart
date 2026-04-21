import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/route/pending_navigation.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// The startup gate shell.
///
/// Wraps the main app content and blocks rendering until Hostr's startup
/// coordinator reports that the active public/user startup profile is ready.
@RoutePage()
class StartupShellScreen extends StatefulWidget {
  const StartupShellScreen({super.key});

  @override
  State<StartupShellScreen> createState() => _StartupShellScreenState();
}

class _StartupShellScreenState extends State<StartupShellScreen> {
  late final StartupGateCubit _gateCubit;

  @override
  void initState() {
    super.initState();
    _gateCubit = StartupGateCubit(startup: getIt<Hostr>().startup);
  }

  @override
  void dispose() {
    unawaited(_gateCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _gateCubit,
      child: const _StartupShellBody(),
    );
  }
}

Future<void> _applyStartupReadyEffects(
  BuildContext context,
  StartupGateReady state,
) async {
  // Mode is loaded from persisted storage by ModeCubit.load() — the
  // startup gate should not override the user's saved preference.
}

final _gateLog = CustomLogger().scope('startup-gate');

enum StartupReadyNavigationAction { editProfile, consumePending }

class StartupReadyNavigationPlan {
  final StartupReadyNavigationAction action;
  final bool seedProfilePendingRoute;

  const StartupReadyNavigationPlan({
    required this.action,
    this.seedProfilePendingRoute = false,
  });
}

StartupReadyNavigationPlan planStartupReadyNavigation({
  required bool hasMetadata,
  required bool hasPendingNavigation,
}) {
  if (!hasMetadata) {
    return StartupReadyNavigationPlan(
      action: StartupReadyNavigationAction.editProfile,
      seedProfilePendingRoute: !hasPendingNavigation,
    );
  }

  return const StartupReadyNavigationPlan(
    action: StartupReadyNavigationAction.consumePending,
  );
}

/// Route names that live inside [TabShellRoute].
const _tabRouteNames = {
  ExploreRoute.name,
  SignInRoute.name,
  ProfileRoute.name,
  TripsRoute.name,
  InboxRoute.name,
  MyListingsRoute.name,
  HostingsRoute.name,
};

/// Wraps [route] in [TabShellRoute] when it is a known tab-level route so
/// that [AppShellScreen] sees `topRouteName == TabShellRoute.name` and
/// renders the bottom navigation bar on compact viewports.
PageRouteInfo wrapInTabShellIfNeeded(PageRouteInfo route) {
  if (_tabRouteNames.contains(route.routeName)) {
    return TabShellRoute(children: [route]);
  }
  return route;
}

/// Consumes the [PendingNavigation] target (if any) and navigates there.
/// If nothing is pending, falls through to the default tab content.
void _consumeAndNavigate(StackRouter router) {
  final target = getIt<PendingNavigation>().consume();
  _gateLog.d(
    'StartupGate._consumeAndNavigate: target=${target?.routeName ?? 'null'}',
  );
  if (target != null) {
    router.root.navigate(wrapInTabShellIfNeeded(target));
  }
}

class _StartupShellBody extends StatefulWidget {
  const _StartupShellBody();

  @override
  State<_StartupShellBody> createState() => _StartupShellBodyState();
}

class _StartupShellBodyState extends State<_StartupShellBody> {
  /// Prevents the listener from handling the same [StartupGateReady]
  /// emission more than once (e.g. if the cubit replays or widget rebuilds).
  bool _handlingReady = false;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surfaceContainerLowest;
    return ColoredBox(
      color: background,
      child: BlocConsumer<StartupGateCubit, StartupGateState>(
        listener: (context, state) async {
          if (state is! StartupGateReady) {
            // Gate left Ready (reset → Initial/InProgress) — allow the
            // next Ready to be processed.
            _handlingReady = false;
            return;
          }
          if (_handlingReady) {
            _gateLog.d('StartupGate: skipping duplicate Ready');
            return;
          }
          _handlingReady = true;

          _gateLog.d(
            'StartupGate: Ready '
            '(hasMetadata=${state.hasMetadata}, '
            'hasPending=${getIt<PendingNavigation>().hasPending})',
          );
          final router = context.router;

          await _applyStartupReadyEffects(context, state);
          if (!mounted) return;

          final pendingNavigation = getIt<PendingNavigation>();
          final navigationPlan = planStartupReadyNavigation(
            hasMetadata: state.hasMetadata,
            hasPendingNavigation: pendingNavigation.hasPending,
          );

          if (
            navigationPlan.action == StartupReadyNavigationAction.editProfile
          ) {
            // Profile incomplete — navigate to edit-profile.
            // Using navigate() (not push()) so auto_route properly nests
            // EditProfileRoute under AppShellRoute in the route tree.
            // Set ProfileRoute as the pending target so that after save,
            // EditProfile.onSave consumes it and lands on the profile tab
            // instead of trying to pop into an empty stack.
            if (navigationPlan.seedProfilePendingRoute) {
              pendingNavigation.set(ProfileRoute());
            }
            _gateLog.d(
              'StartupGate: navigating to EditProfileRoute (no metadata)',
            );
            router.navigate(EditProfileRoute());
            return;
          }

          // All prerequisites met — consume and navigate to the
          // pending destination (e.g. the listing from a reserve flow).
          _consumeAndNavigate(router);
        },
        builder: (context, state) {
          final child = switch (state) {
            StartupGateError(:final message) => _ErrorView(
              key: const ValueKey('error'),
              message: message,
              onRetry: () {
                context.read<StartupGateCubit>().retry();
              },
            ),
            StartupGateReady() => const AutoRouter(key: ValueKey('ready')),
            StartupGateInProgress() => _SplashProgressView(
              key: ValueKey(state.items),
              state: state,
            ),
            _ => _SplashProgressView(
              key: const ValueKey('initial'),
              state: const StartupGateInProgress(
                items: startupGateInitialItems,
              ),
            ),
          };
          return child;
        },
      ),
    );
  }
}

// ─── Splash-style progress view ─────────────────────────────────────────────

/// Renders the app logo centred on the same background as the native splash,
/// with a single animated step label below it that switches between steps.
class _SplashProgressView extends StatelessWidget {
  final StartupGateInProgress state;
  const _SplashProgressView({super.key, required this.state});

  String _logoAssetForTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? 'assets/images/logo/generated/logo_base_1024.png'
        : 'assets/images/logo/generated/logo_base_1024.png';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = state.currentItem.label;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo – same asset as the native splash.
          Image.asset(
            _logoAssetForTheme(theme.brightness),
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          Gap.vertical.lg(),

          _StepIndicator(label: label, theme: theme),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _StepIndicator({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLoadingIndicator.small(),
        Gap.horizontal.custom(kSpace3),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Error view ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: CustomPadding.horizontal.lg(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: kIconHero,
              color: theme.colorScheme.error,
            ),
            Gap.vertical.md(),
            Text(
              AppLocalizations.of(context)!.somethingWentWrong,
              style: theme.textTheme.titleMedium,
            ),
            Gap.vertical.sm(),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Gap.vertical.custom(kSpace5),
            FilledButton.icon(
              onPressed: onRetry,
              style: AppButtonStyles.secondary(context),
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
