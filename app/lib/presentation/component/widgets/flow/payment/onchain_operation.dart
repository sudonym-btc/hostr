import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr/presentation/component/widgets/ui/app_loading_indicator.dart';
import 'package:hostr/presentation/component/widgets/ui/asymptotic_progress_bar.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../ui/gap.dart';
import '../modal_bottom_sheet.dart';

// ── OnchainTransactionSheet ─────────────────────────────────────────────
//
// Single factory-constructor widget that controls the look of every
// on-chain transaction state. Update these factories to change the
// appearance of *all* transaction flows at once.

/// A [ModalBottomSheet] tailored for on-chain transaction states.
///
/// Use the named constructors ([loading], [broadcast], [swapProgress],
/// [success], [error]) to get sensible defaults.  Every parameter can be
/// overridden per-call to customise individual flows.
class OnchainTransactionSheet extends StatelessWidget {
  final ModalBottomSheetType type;
  final String? title;
  final String? subtitle;
  final Widget? content;
  final Widget? buttons;

  const OnchainTransactionSheet({
    super.key,
    this.type = ModalBottomSheetType.normal,
    this.title,
    this.subtitle,
    this.content,
    this.buttons,
  });

  /// Indeterminate loading / initialising state.
  factory OnchainTransactionSheet.loading({
    Key? key,
    String? title,
    String? subtitle,
  }) => OnchainTransactionSheet(
    key: key,
    title: title ?? 'Transaction Initialised',
    subtitle: subtitle,
    content: Center(child: AppLoadingIndicator.large()),
  );

  /// Transaction has been broadcast; awaiting on-chain confirmation.
  factory OnchainTransactionSheet.broadcast({
    Key? key,
    String? title,
    String? subtitle,
  }) => OnchainTransactionSheet(
    key: key,
    title: title ?? 'Transaction Broadcasted',
    subtitle: subtitle ?? 'Waiting for on-chain confirmation...',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gap.vertical.custom(kSpace5),
        AsymptoticProgressBar(),
        Gap.vertical.md(),
      ],
    ),
  );

  /// A nested swap-in is in progress.
  factory OnchainTransactionSheet.swapProgress(
    OnchainSwapProgress state, {
    Key? key,
  }) => OnchainTransactionSheet(
    key: key,
    content: SwapInViewWidget(state.swapState!),
  );

  /// Transaction confirmed on-chain.
  factory OnchainTransactionSheet.success({
    Key? key,
    String? title,
    String? subtitle,
  }) => OnchainTransactionSheet(
    key: key,
    type: ModalBottomSheetType.success,
    title: title ?? 'Transaction Success',
    subtitle: subtitle ?? 'Your transaction successfully confirmed onchain.',
    content: Container(),
  );

  /// Transaction failed.
  factory OnchainTransactionSheet.error(
    OnchainError state, {
    Key? key,
    String? title,
    String? subtitle,
  }) => OnchainTransactionSheet(
    key: key,
    type: ModalBottomSheetType.error,
    title: title ?? 'Transaction Failed',
    subtitle: subtitle,
    content: Text(state.error.toString()),
  );

  @override
  Widget build(BuildContext context) {
    // When the only content is a swap-in flow, render it directly without
    // the ModalBottomSheet chrome (SwapInViewWidget provides its own).
    if (content is SwapInViewWidget) return content!;

    return ModalBottomSheet(
      type: type,
      title: title,
      subtitle: subtitle,
      content: content,
      buttons: buttons,
    );
  }
}

// ── State → Widget builder callbacks ────────────────────────────────────

typedef OnchainStateWidgetBuilder<S extends OnchainOperationState> =
    Widget Function(S state);

bool shouldRenderSwapProgress(OnchainSwapProgress state) {
  return switch (state.swapState) {
    SwapInPaymentProgress(paymentState: PayExternalRequired()) => true,
    SwapInFailed() => true,
    _ => false,
  };
}

/// Whether a [OnchainSwapProgress] state should trigger a BlocBuilder
/// rebuild.  This is a superset of [shouldRenderSwapProgress]: it also
/// includes the claiming / confirmation phases so that the broadcast-style
/// "waiting for on-chain confirmation" UI can be shown instead of staying
/// stuck on a stale widget.
bool shouldRebuildForSwapProgress(OnchainSwapProgress state) {
  if (shouldRenderSwapProgress(state)) return true;
  return switch (state.swapState) {
    SwapInAwaitingOnChain() => true,
    SwapInInvoicePaid() => true,
    SwapInFunded() => true,
    SwapInClaimed() => true,
    SwapInClaimTxInMempool() => true,
    SwapInCompleted() => true,
    _ => false,
  };
}

// ── OnchainOperationViewWidget ──────────────────────────────────────────
//
// Exhaustive switch over [OnchainOperationState].  Each state has a
// sensible default via [OnchainTransactionSheet]; supply per-state builder
// callbacks to customise individual operations without duplicating the switch.

class OnchainOperationViewWidget extends StatelessWidget {
  final OnchainOperationState state;

  /// Optional per-state builder overrides.
  /// Return a widget to replace the default, or omit to keep it.
  final OnchainStateWidgetBuilder<OnchainInitialised>? initialisedBuilder;
  final OnchainStateWidgetBuilder<OnchainTxBroadcast>? broadcastBuilder;
  final OnchainStateWidgetBuilder<OnchainSwapProgress>? swapProgressBuilder;
  final OnchainStateWidgetBuilder<OnchainTxConfirmed>? confirmedBuilder;
  final OnchainStateWidgetBuilder<OnchainError>? errorBuilder;

  const OnchainOperationViewWidget(
    this.state, {
    super.key,
    this.initialisedBuilder,
    this.broadcastBuilder,
    this.swapProgressBuilder,
    this.confirmedBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      final OnchainInitialised s =>
        initialisedBuilder?.call(s) ?? OnchainTransactionSheet.loading(),
      final OnchainTxBroadcasting s =>
        broadcastBuilder?.call(OnchainTxBroadcast(s.data)) ??
            OnchainTransactionSheet.broadcast(),
      final OnchainTxBroadcast s =>
        broadcastBuilder?.call(s) ?? OnchainTransactionSheet.broadcast(),
      final OnchainTxSent s =>
        broadcastBuilder?.call(OnchainTxBroadcast(s.data)) ??
            OnchainTransactionSheet.broadcast(),
      final OnchainSwapProgress s =>
        shouldRenderSwapProgress(s)
            ? (swapProgressBuilder?.call(s) ??
                  OnchainTransactionSheet.swapProgress(s))
            : (broadcastBuilder?.call(OnchainTxBroadcast(s.data)) ??
                  OnchainTransactionSheet.broadcast()),
      final OnchainTxConfirmed s =>
        confirmedBuilder?.call(s) ?? OnchainTransactionSheet.success(),
      final OnchainError s =>
        errorBuilder?.call(s) ?? OnchainTransactionSheet.error(s),
    };
  }
}

// ── OnchainOperationFlowWidget ──────────────────────────────────────────

class OnchainOperationFlowWidget extends StatefulWidget {
  final OnchainOperation cubit;

  /// Optional per-state builder overrides forwarded to
  /// [OnchainOperationViewWidget].
  final OnchainStateWidgetBuilder<OnchainInitialised>? initialisedBuilder;
  final OnchainStateWidgetBuilder<OnchainTxBroadcast>? broadcastBuilder;
  final OnchainStateWidgetBuilder<OnchainSwapProgress>? swapProgressBuilder;
  final OnchainStateWidgetBuilder<OnchainTxConfirmed>? confirmedBuilder;
  final OnchainStateWidgetBuilder<OnchainError>? errorBuilder;

  const OnchainOperationFlowWidget({
    super.key,
    required this.cubit,
    this.initialisedBuilder,
    this.broadcastBuilder,
    this.swapProgressBuilder,
    this.confirmedBuilder,
    this.errorBuilder,
  });

  @override
  State<OnchainOperationFlowWidget> createState() =>
      _OnchainOperationFlowWidgetState();
}

class _OnchainOperationFlowWidgetState
    extends State<OnchainOperationFlowWidget> {
  @override
  void dispose() {
    // Allow in-flight swaps to complete before closing the cubit.
    widget.cubit.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<OnchainOperation, OnchainOperationState>(
        // Suppress intermediate swap states (e.g. SwapInInitialised,
        // SwapInRequestCreated) that flash briefly before the
        // payment-required UI is ready.  Claiming / confirmation phases
        // are allowed through so the broadcast fallback UI can render.
        buildWhen: (_, current) => switch (current) {
          final OnchainSwapProgress s => shouldRebuildForSwapProgress(s),
          _ => true,
        },
        builder: (context, state) {
          return OnchainOperationViewWidget(
            state,
            initialisedBuilder: widget.initialisedBuilder,
            broadcastBuilder: widget.broadcastBuilder,
            swapProgressBuilder: widget.swapProgressBuilder,
            confirmedBuilder: widget.confirmedBuilder,
            errorBuilder: widget.errorBuilder,
          );
        },
      ),
    );
  }
}
