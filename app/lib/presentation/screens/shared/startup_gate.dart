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
/// Wraps the main app content and blocks rendering until the bootstrap
/// sequence completes (relay connect, metadata sync, etc.). On cold start
/// it runs automatically. After sign-in it detects the auth state transition
/// to [LoggedIn] and re-runs the bootstrap, showing the splash again while
/// syncing.
@RoutePage()
class StartupShellScreen extends StatefulWidget {
  const StartupShellScreen({super.key});

  @override
  State<StartupShellScreen> createState() => _StartupShellScreenState();
}

class _StartupShellScreenState extends State<StartupShellScreen> {
  late final StartupGateCubit _gateCubit;
  late final StreamSubscription<AuthState> _authSub;
  AuthState? _prevAuthState;

  @override
  void initState() {
    super.initState();
    _gateCubit = StartupGateCubit(hostr: getIt<Hostr>())..run();

    // Re-gate only on a genuine logout → login transition (i.e. sign-in),
    // not on the initial emission.
    _authSub = getIt<Hostr>().auth.authState.listen((authState) {
      final prev = _prevAuthState;
      _prevAuthState = authState;

      final isNewLogin =
          authState == const LoggedIn() &&
          prev != null &&
          prev != const LoggedIn();

      if (isNewLogin && _gateCubit.state is! StartupGateInProgress) {
        _gateCubit.reset();
        _gateCubit.run();
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _gateCubit.close();
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
  // Note: we deliberately do NOT re-check auth here.
  // Hostr.auth already transitioned to LoggedIn from the signin() call.
  // Re-checking could momentarily see stale state (timing-dependent),
  // which triggers the auth subscription → reset+run → double-Ready race.

  if (!state.isHost) return;

  try {
    await context.read<ModeCubit>().setHost();
  } catch (_) {}
}

final _gateLog = CustomLogger().scope('startup-gate');

/// Route names that live inside [TabShellRoute].
const _tabRouteNames = {
  SearchRoute.name,
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
void _consumeAndNavigate(BuildContext context) {
  final target = getIt<PendingNavigation>().consume();
  _gateLog.d(
    'StartupGate._consumeAndNavigate: target=${target?.routeName ?? 'null'}',
  );
  if (target != null) {
    context.router.root.navigate(wrapInTabShellIfNeeded(target));
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
    return BlocConsumer<StartupGateCubit, StartupGateState>(
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
          '(hasMetadata=${state.hasMetadata}, isHost=${state.isHost}, '
          'hasPending=${getIt<PendingNavigation>().hasPending})',
        );

        await _applyStartupReadyEffects(context, state);
        if (!mounted) return;

        if (!state.hasMetadata) {
          // Profile incomplete — navigate to edit-profile.
          // Using navigate() (not push()) so auto_route properly nests
          // EditProfileRoute under AppShellRoute in the route tree.
          // Set ProfileRoute as the pending target so that after save,
          // EditProfile.onSave consumes it and lands on the profile tab
          // instead of trying to pop into an empty stack.
          if (!getIt<PendingNavigation>().hasPending) {
            getIt<PendingNavigation>().set(ProfileRoute());
          }
          _gateLog.d(
            'StartupGate: navigating to EditProfileRoute (no metadata)',
          );
          context.router.navigate(EditProfileRoute());
          return;
        }

        // All prerequisites met — consume and navigate to the
        // pending destination (e.g. the listing from a reserve flow).
        _consumeAndNavigate(context);
      },
      builder: (context, state) {
        return switch (state) {
          StartupGateError(:final message) => _ErrorView(
            message: message,
            onRetry: () {
              context.read<StartupGateCubit>().reset();
              context.read<StartupGateCubit>().run();
            },
          ),
          StartupGateReady() => const AutoRouter(),
          StartupGateInProgress() => _SplashProgressView(state: state),
          _ => const _SplashProgressView(
            state: StartupGateInProgress(currentStep: StartupStep.relay),
          ),
        };
      },
    );
  }
}

// ─── Splash-style progress view ─────────────────────────────────────────────

/// Renders the app logo centred on the same background as the native splash,
/// with a single animated step label below it that switches between steps.
class _SplashProgressView extends StatelessWidget {
  final StartupGateInProgress state;
  const _SplashProgressView({required this.state});

  String _logoAssetForTheme(Brightness brightness) {
    return brightness == Brightness.dark
        ? 'assets/images/logo/generated/logo_startup_dark_512.png'
        : 'assets/images/logo/generated/logo_startup_light_512.png';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = state.currentStep.label;
    final key = state.currentStep.name;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo – same asset as the native splash.
            Image.asset(
              _logoAssetForTheme(theme.brightness),
              width: 180,
              height: 72,
              fit: BoxFit.contain,
            ),
            Gap.vertical.lg(),

            // Single animated step indicator that switches between steps.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                final slide =
                    Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _StepIndicator(
                key: ValueKey(key),
                label: label,
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _StepIndicator({super.key, required this.label, required this.theme});

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
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
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
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
