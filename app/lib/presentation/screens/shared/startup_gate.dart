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
/// with an animated progress ring and step list that fade in below the logo
/// once the first step begins.
class _SplashProgressView extends StatelessWidget {
  final StartupGateInProgress state;
  final bool allDone;
  const _SplashProgressView({required this.state, this.allDone = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = StartupStep.values;

    return Scaffold(
      // Match native splash background.
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: CustomPadding.horizontal.lg(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo – same asset as the native splash.
              Image.asset(
                'assets/images/logo/generated/logo_base_1024.png',
                width: 200,
                height: 200,
              ),
              Gap.vertical.lg(),

              // Animated progress ring
              SizedBox(
                width: 64,
                height: 64,
                child: AppLoadingIndicator.progress(
                  value: state.progress,
                  size: 64,
                  strokeWidth: 4,
                ),
              ),
              Gap.vertical.lg(),

              // Step checklist
              ...steps.map((step) {
                final isDone = state.completedSteps.contains(step);
                final isCurrent = step == state.currentStep;

                return CustomPadding.vertical.xs(
                  child: Row(
                    children: [
                      if (isDone)
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: kIconMd,
                        )
                      else if (isCurrent)
                        const AppLoadingIndicator.small()
                      else
                        Icon(
                          Icons.radio_button_unchecked,
                          color: theme.colorScheme.outline,
                          size: kIconMd,
                        ),
                      Gap.horizontal.custom(kSpace3),
                      Text(
                        step.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDone
                              ? theme.colorScheme.primary
                              : isCurrent
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                          fontWeight: isCurrent ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // "All Done!" indicator
              if (allDone) ...[
                Gap.vertical.sm(),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: kIconMd,
                    ),
                    Gap.horizontal.custom(kSpace3),
                    Text(
                      'All Done!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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
