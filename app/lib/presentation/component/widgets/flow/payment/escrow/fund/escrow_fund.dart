import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/onchain_operation.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../../../../amount/amount_input.dart';
import '../../../modal_bottom_sheet.dart';
import '../../payment_method/escrow_selector/escrow_selector.cubit.dart';
import '../../payment_method/escrow_selector/escrow_selector.dart';

// ── EscrowFundWidget ────────────────────────────────────────────────────
//
// Manages the [EscrowSelectorCubit] and the current [EscrowFundPreparer].
// When the user picks a different escrow, the preparer is recreated.
//
// Flow:
// 1. User selects escrow → [EscrowFundPreparer] is created
// 2. Confirm screen shows fees → user taps "Confirm"
// 3. [EscrowFundPreparer.prepare()] builds [SwapInParams]
// 4. A [SwapInOperation] is created (self-registers in [SwapInTracker])
// 5. The widget transitions to [SwapInFlowWidget]

class EscrowFundWidget extends StatefulWidget {
  final ProfileMetadata counterparty;
  final Reservation negotiateReservation;
  final String? listingName;

  const EscrowFundWidget({
    super.key,
    required this.counterparty,
    required this.negotiateReservation,
    this.listingName,
  });

  @override
  State<EscrowFundWidget> createState() => _EscrowFundWidgetState();
}

class _EscrowFundWidgetState extends State<EscrowFundWidget> {
  late final EscrowSelectorCubit _selectorCubit;
  EscrowFundPreparer? _preparer;

  /// Once the user confirms, this holds the live swap operation.
  SwapInOperation? _swapOperation;

  @override
  void initState() {
    super.initState();
    _selectorCubit = EscrowSelectorCubit(
      counterparty: widget.counterparty,
      negotiateReservation: widget.negotiateReservation,
    )..load();
  }

  void _createPreparer(EscrowService escrow) {
    _preparer = getIt<Hostr>().escrow.fund(
      EscrowFundParams(
        negotiateReservation: widget.negotiateReservation,
        amount: widget.negotiateReservation.amount!,
        sellerProfile: widget.counterparty,
        escrowService: escrow,
        listingName: widget.listingName,
      ),
    );
  }

  Future<void> _onConfirm() async {
    final preparer = _preparer;
    if (preparer == null) return;

    await _selectorCubit.select();

    // Build the SwapInParams (resolves signer, estimates gas, etc.).
    final swapParams = await preparer.prepare();

    // Create the swap operation (self-registers in SwapInTracker).
    final swapOp = preparer.configuredChain.swapIn(
      auth: getIt<Hostr>().auth,
      logger: preparer.logger,
      params: swapParams,
    );

    // Transition to swap flow and auto-execute — the user already confirmed
    // in EscrowFundConfirmWidget so there is no need to show the
    // SwapInConfirmWidget again.
    if (mounted) {
      setState(() => _swapOperation = swapOp);
      unawaited(swapOp.execute());
    }
  }

  @override
  void dispose() {
    _selectorCubit.close();
    // If there's a live swap, let it continue (the registry holds it).
    // detachOrClose is handled by SwapInFlowWidget.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Once a swap has been created, show the swap-in flow.
    final swap = _swapOperation;
    if (swap != null) {
      return SwapInFlowWidget(cubit: swap);
    }

    return BlocProvider.value(
      value: _selectorCubit,
      child: BlocConsumer<EscrowSelectorCubit, EscrowSelectorState>(
        listener: (context, state) {
          if (state is EscrowSelectorLoaded && state.selectedEscrow != null) {
            setState(() => _createPreparer(state.selectedEscrow!));
          }
        },
        builder: (context, selectorState) {
          if (selectorState is EscrowSelectorError) {
            return ModalBottomSheet(
              type: ModalBottomSheetType.error,
              title: 'Deposit Funds',
              content: Text(selectorState.message),
            );
          }

          final preparer = _preparer;
          if (selectorState is! EscrowSelectorLoaded || preparer == null) {
            return OnchainTransactionSheet.loading(title: 'Deposit Funds');
          }

          return EscrowFundConfirmWidget(
            key: ObjectKey(preparer),
            preparer: preparer,
            onConfirm: _onConfirm,
          );
        },
      ),
    );
  }
}

class EscrowFundConfirmWidget extends StatefulWidget {
  final EscrowFundPreparer preparer;
  final Future<void> Function() onConfirm;
  const EscrowFundConfirmWidget({
    required this.preparer,
    required this.onConfirm,
    super.key,
  });

  @override
  State<EscrowFundConfirmWidget> createState() =>
      _EscrowFundConfirmWidgetState();
}

class _EscrowFundConfirmWidgetState extends State<EscrowFundConfirmWidget> {
  bool _loading = false;
  late final Future<FeeBreakdown> _feeEstimate;

  @override
  void initState() {
    super.initState();
    _feeEstimate = widget.preparer.estimateFees();
  }

  Future<void> _handleConfirm() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onConfirm();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: 'Deposit Funds',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap.vertical.md(),
          EscrowSelectorWidget(),
          Gap.vertical.md(),
          AmountWidget(
            amount: widget.preparer.params!.amount,
            loading: _loading,
            feeWidget: FutureBuilder<FeeBreakdown>(
              future: _feeEstimate,
              builder: (context, snapshot) {
                final baseStyle = Theme.of(context).textTheme.bodySmall!;
                final subtleStyle = baseStyle.copyWith(
                  fontWeight: FontWeight.w400,
                  color: baseStyle.color?.withValues(alpha: 0.6),
                );

                if (snapshot.connectionState != ConnectionState.done) {
                  return Text(
                    AppLocalizations.of(context)!.estimatingFees,
                    style: subtleStyle,
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return Text('Unable to estimate fees', style: subtleStyle);
                }

                final fees = snapshot.data!;
                final chainConfig = widget.preparer.configuredChain.config;
                final escrowDenom = chainConfig
                    .tokenByAddress(fees.escrowFee.token.address)
                    ?.denomination;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "+ ${formatTokenAmount(fees.gasFee, denomination: chainConfig.nativeDenomination)} in network fees"
                      "${fees.gasSponsored ? ' (gas sponsored)' : ''}",
                      style: subtleStyle,
                    ),
                    Text(
                      "+ ${formatAmount(fees.swapFee)} in swap fees",
                      style: subtleStyle,
                    ),
                    Text(
                      "+ ${formatTokenAmount(fees.escrowFee, denomination: escrowDenom)} in escrow fees",
                      style: subtleStyle,
                    ),
                  ],
                );
              },
            ),
            onConfirm: _handleConfirm,
          ),
        ],
      ),
    );
  }
}

class EscrowFundProgressWidget extends StatelessWidget {
  final OnchainSwapProgress progress;
  const EscrowFundProgressWidget(this.progress, {super.key});

  @override
  Widget build(BuildContext context) {
    final swapState = progress.swapState;
    if (swapState == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return OnchainTransactionSheet.swapProgress(progress);
  }
}
