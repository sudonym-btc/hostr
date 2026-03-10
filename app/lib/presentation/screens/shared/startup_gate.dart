import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// The first screen on every cold start and post-sign-in flow.
///
/// Renders as an extended splash (centred logo, matching the native splash)
/// while the [StartupGateCubit] connects relays, syncs metadata and
/// messages, then automatically navigates to [AppShellRoute]
/// (or [EditProfileRoute] when no profile exists).
@RoutePage()
class StartupGateScreen extends StatelessWidget {
  final bool popOnComplete;
  const StartupGateScreen({super.key, this.popOnComplete = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StartupGateCubit(hostr: getIt<Hostr>())..run(),
      child: _StartupGateBody(popOnComplete: popOnComplete),
    );
  }
}

class _StartupGateBody extends StatelessWidget {
  final bool popOnComplete;
  const _StartupGateBody({required this.popOnComplete});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StartupGateCubit, StartupGateState>(
      listener: (context, state) async {
        if (state is! StartupGateReady) return;

        // Let the user see the "All Done!" state before navigating.
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!context.mounted) return;

        if (state.isHost) {
          try {
            await context.read<ModeCubit>().setHost();
          } catch (_) {}
        }

        if (!context.mounted) return;

        if (!state.hasMetadata) {
          if (popOnComplete) {
            context.router.popUntilRoot();
            context.router.replace(const AppShellRoute());
          } else {
            context.router.replace(const AppShellRoute());
          }
          context.router.push(EditProfileRoute());
          return;
        }

        if (popOnComplete) {
          context.router.popUntilRoot();
          context.router.replace(const AppShellRoute());
        } else {
          context.router.replace(const AppShellRoute());
        }
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
          StartupGateReady() => const _SplashProgressView(
            state: StartupGateInProgress(
              currentStep: StartupStep.messages,
              completedSteps: {
                StartupStep.relay,
                StartupStep.relayList,
                StartupStep.metadata,
                StartupStep.messages,
              },
            ),
            allDone: true,
          ),
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
  final bool allDone;
  const _SplashProgressView({required this.state, this.allDone = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = allDone ? 'All Done' : state.currentStep.label;
    final key = allDone ? 'done' : state.currentStep.name;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo – same asset as the native splash.
            Image.asset(
              'assets/images/logo/generated/logo_base_1024.png',
              width: 100,
              height: 100,
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
                isDone: allDone,
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
  final bool isDone;
  final ThemeData theme;

  const _StepIndicator({
    super.key,
    required this.label,
    required this.isDone,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDone)
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
            size: kIconMd,
          )
        else
          const AppLoadingIndicator.small(),
        Gap.horizontal.custom(kSpace3),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDone
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
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
