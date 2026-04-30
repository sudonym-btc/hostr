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

enum StartupReadyNavigationAction { none, editProfile, consumePending }

class StartupReadyNavigationPlan {
  final StartupReadyNavigationAction action;
  final bool seedProfilePendingRoute;

  const StartupReadyNavigationPlan({
    required this.action,
    this.seedProfilePendingRoute = false,
  });
}

StartupReadyNavigationPlan planStartupReadyNavigation({
  required StartupScope scope,
  required bool hasMetadata,
  required bool hasPendingNavigation,
}) {
  if (scope != StartupScope.user) {
    return const StartupReadyNavigationPlan(
      action: StartupReadyNavigationAction.none,
    );
  }

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

@visibleForTesting
bool shouldBlockStartupForBunker(BunkerSessionState? state) {
  return state is BunkerSessionRecoveryRequired ||
      state is BunkerSessionRestoring;
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

bool _isRouteActive(StackRouter router, String routeName) {
  return router.topRoute.name == routeName ||
      router.currentSegments.any((segment) => segment.name == routeName) ||
      router.root.topRoute.name == routeName ||
      router.root.currentSegments.any((segment) => segment.name == routeName);
}

/// Consumes the [PendingNavigation] target (if any) and navigates there.
/// If the user signed in from the plain sign-in screen, return them to the
/// default public tab so they do not remain on SignIn after auth succeeds.
void _consumeAndNavigate(StackRouter router) {
  final target = getIt<PendingNavigation>().consume();
  _gateLog.d(
    'StartupGate._consumeAndNavigate: target=${target?.routeName ?? 'null'}',
  );
  if (target != null) {
    router.root.navigate(wrapInTabShellIfNeeded(target));
  } else if (_isRouteActive(router, SignInRoute.name)) {
    router.root.navigate(wrapInTabShellIfNeeded(const ExploreRoute()));
  }
}

class _StartupShellBody extends StatefulWidget {
  const _StartupShellBody();

  @override
  State<_StartupShellBody> createState() => _StartupShellBodyState();
}

class _StartupShellBodyState extends State<_StartupShellBody> {
  /// Prevents the listener from handling the same [StartupGateReady] emission
  /// more than once while still allowing a new signed-in user to run through
  /// startup navigation in the same app session.
  String? _handledReadyKey;

  Future<void> _handleReadyState(StartupGateReady state) async {
    final pendingNavigation = getIt<PendingNavigation>();
    final authState = getIt<Hostr>().auth.authState.value;
    final authKey =
        state.pubkey ??
        switch (authState) {
          LoggedIn(:final pubkey) => pubkey ?? 'logged-in',
          _ => authState.runtimeType.toString(),
        };
    final readyKey =
        '${state.scope}:$authKey:${state.hasMetadata}:${pendingNavigation.hasPending}';

    _gateLog.d(
      'StartupGate: Ready '
      '(auth=$authKey, '
      'hasMetadata=${state.hasMetadata}, '
      'hasPending=${pendingNavigation.hasPending})',
    );
    final router = context.router;

    await _applyStartupReadyEffects(context, state);
    if (!mounted) return;

    final navigationPlan = planStartupReadyNavigation(
      scope: state.scope,
      hasMetadata: state.hasMetadata,
      hasPendingNavigation: pendingNavigation.hasPending,
    );

    final isDuplicateReady = _handledReadyKey == readyKey;
    if (isDuplicateReady) {
      final shouldRetryProfileNavigation =
          navigationPlan.action == StartupReadyNavigationAction.editProfile &&
          !_isRouteActive(router, EditProfileRoute.name);
      if (!shouldRetryProfileNavigation) {
        _gateLog.d('StartupGate: skipping duplicate Ready');
        return;
      }
      _gateLog.d('StartupGate: retrying EditProfileRoute navigation');
    } else {
      _handledReadyKey = readyKey;
    }

    if (navigationPlan.action == StartupReadyNavigationAction.none) {
      return;
    }

    if (navigationPlan.action == StartupReadyNavigationAction.editProfile) {
      // Profile incomplete — navigate to edit-profile.
      // Using navigate() (not push()) so auto_route properly nests
      // EditProfileRoute under AppShellRoute in the route tree.
      // Set ProfileRoute as the pending target so that after save,
      // EditProfile.onSave consumes it and lands on the profile tab
      // instead of trying to pop into an empty stack.
      if (navigationPlan.seedProfilePendingRoute) {
        pendingNavigation.set(ProfileRoute());
      }
      _gateLog.d('StartupGate: navigating to EditProfileRoute (no metadata)');
      router.navigate(EditProfileRoute());
      return;
    }

    // All prerequisites met — consume and navigate to the
    // pending destination (e.g. the listing from a reserve flow).
    _consumeAndNavigate(router);
  }

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surfaceContainerLowest;
    return ColoredBox(
      color: background,
      child: StreamBuilder<BunkerSessionState>(
        stream: getIt<Hostr>().auth.bunkerSessionState,
        initialData: getIt<Hostr>().auth.bunkerSessionState.value,
        builder: (context, bunkerSnapshot) {
          final bunkerState = bunkerSnapshot.data;
          if (shouldBlockStartupForBunker(bunkerState)) {
            return BunkerRecoveryView(
              state: bunkerState!,
              onRetry: () async {
                final gateCubit = context.read<StartupGateCubit>();
                final restored = await getIt<Hostr>().auth
                    .retryBunkerSessionRestore();
                if (!mounted || !restored) return;
                await gateCubit.retry();
              },
              onSignOut: () async {
                final gateCubit = context.read<StartupGateCubit>();
                await getIt<Hostr>().auth.logout();
                if (!mounted) return;
                await gateCubit.retry();
              },
            );
          }

          return BlocConsumer<StartupGateCubit, StartupGateState>(
            listener: (context, state) async {
              if (state is! StartupGateReady) {
                // Gate left Ready (reset → Initial/InProgress) — allow the
                // next Ready to be processed.
                _handledReadyKey = null;
                return;
              }
              await _handleReadyState(state);
            },
            builder: (context, state) {
              if (state is StartupGateReady) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  unawaited(_handleReadyState(state));
                });
              }
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
                  key: const ValueKey('progress'),
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
          );
        },
      ),
    );
  }
}

// ─── Splash-style progress view ─────────────────────────────────────────────

/// Renders the app logo centred on the same background as the native splash,
/// with an animated progress bar below it.
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

          _StartupProgressBar(
            progress: state.progress,
            completed: state.completedItemCount,
            total: state.totalItemCount,
          ),

          /*
          // Previous startup step label UI. Kept here so it can be restored
          // quickly if we want the gate to show the active startup item again.
          _StepIndicator(label: state.currentItem.label, theme: theme),
          */
        ],
      ),
    );
  }
}

class _StartupProgressBar extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const _StartupProgressBar({
    required this.progress,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: AppBorderRadii.full,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: clampedProgress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) {
                return LinearProgressIndicator(
                  value: animatedProgress,
                  minHeight: 4,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                );
              },
            ),
          ),

          /*
          Gap.vertical.sm(),
          Text(
            '$completed / $total',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          */
        ],
      ),
    );
  }
}

/*
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
*/

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

class BunkerRecoveryView extends StatefulWidget {
  final BunkerSessionState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onSignOut;

  const BunkerRecoveryView({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  State<BunkerRecoveryView> createState() => _BunkerRecoveryViewState();
}

class _BunkerRecoveryViewState extends State<BunkerRecoveryView> {
  bool _busy = false;

  bool get _isRestoring => widget.state is BunkerSessionRestoring;

  String get _detailMessage {
    final state = widget.state;
    if (state is BunkerSessionRecoveryRequired) return state.message;
    if (state is BunkerSessionRestoring) {
      return 'Trying to reconnect to the saved bunker session...';
    }
    return '';
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: CustomPadding.horizontal.lg(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phonelink_lock_outlined,
                size: kIconHero,
                color: colors.primary,
              ),
              Gap.vertical.md(),
              Text(
                'Reconnect your remote signer',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Gap.vertical.sm(),
              Text(
                'Hostr could not restore the saved bunker session. Open your Nostr signer, then retry. If that session was ended, sign out and connect again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Gap.vertical.sm(),
              Text(
                _detailMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.outline,
                ),
              ),
              Gap.vertical.custom(kSpace5),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: kSpace3,
                runSpacing: kSpace3,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('bunker_restore_retry_button'),
                    onPressed: (_busy || _isRestoring)
                        ? null
                        : () => _run(widget.onRetry),
                    icon: (_busy || _isRestoring)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('bunker_restore_sign_out_button'),
                    onPressed: (_busy || _isRestoring)
                        ? null
                        : () => _run(widget.onSignOut),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
