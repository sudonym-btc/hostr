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

/// Dedicated route page that runs the post-login onboarding sequence.
///
/// After sign-in / sign-up the app navigates here. The cubit walks through
/// relay list → connect → metadata → messages, then automatically navigates
/// to [HomeRoute] (or [EditProfileRoute] when no profile exists).
@RoutePage()
class OnboardingScreen extends StatelessWidget {
  final bool popOnComplete;
  const OnboardingScreen({super.key, this.popOnComplete = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(hostr: getIt<Hostr>())..run(),
      child: _OnboardingBody(popOnComplete: popOnComplete),
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  final bool popOnComplete;
  const _OnboardingBody({required this.popOnComplete});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) async {
        if (state is! OnboardingComplete) return;

        if (state.isHost) {
          try {
            await context.read<ModeCubit>().setHost();
          } catch (_) {}
        }

        if (!context.mounted) return;

        if (!state.hasMetadata) {
          if (popOnComplete) {
            context.router.popUntilRoot();
            context.router.replace(const HomeRoute());
          } else {
            context.router.replace(const HomeRoute());
          }
          context.router.push(EditProfileRoute());
          return;
        }

        if (popOnComplete) {
          context.router.popUntilRoot();
          context.router.replace(const HomeRoute());
        } else {
          context.router.replace(const HomeRoute());
        }
      },
      builder: (context, state) {
        return switch (state) {
          OnboardingError(:final message) => _ErrorView(
            message: message,
            onRetry: () => context.read<OnboardingCubit>().run(),
          ),
          OnboardingInProgress() => _ProgressView(state: state),
          _ => const _ProgressView(
            state: OnboardingInProgress(currentStep: OnboardingStep.relayList),
          ),
        };
      },
    );
  }
}

// ─── Progress view ──────────────────────────────────────────────────────────

class _ProgressView extends StatelessWidget {
  final OnboardingInProgress state;
  const _ProgressView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = OnboardingStep.values;

    return Scaffold(
      body: Center(
        child: CustomPadding.horizontal.lg(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
