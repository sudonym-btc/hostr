import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  const _OnboardingBody({this.popOnComplete = false});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingComplete) {
          // Switch mode based on whether the user has listings.
          if (state.isHost) {
            context.read<ModeCubit>().setHost();
          } else {
            context.read<ModeCubit>().setGuest();
          }

          if (popOnComplete) {
            // Pop back to wherever the user was (e.g. listing page).
            context.router.maybePop();
            return;
          }

          if (!state.hasMetadata) {
            // New user with no profile → edit profile first.
            context.router.replaceAll([
              HomeRoute(children: [ProfileRoute()]),
              EditProfileRoute(),
            ]);
          } else {
            context.router.replaceAll([HomeRoute()]);
          }
        }
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          return switch (state) {
            OnboardingError(message: final msg) => _ErrorView(
              message: msg,
              onRetry: () {
                context.read<OnboardingCubit>().reset();
                context.read<OnboardingCubit>().run();
              },
            ),
            OnboardingInProgress() => _ProgressView(state: state),
            // Show the first-step spinner for initial / complete (brief flash
            // before the listener navigates away).
            _ => _ProgressView(
              state: const OnboardingInProgress(
                currentStep: OnboardingStep.relayList,
              ),
            ),
          };
        },
      ),
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
                child: CircularProgressIndicator(
                  value: state.progress,
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
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
              Text('Something went wrong', style: theme.textTheme.titleMedium),
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
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
