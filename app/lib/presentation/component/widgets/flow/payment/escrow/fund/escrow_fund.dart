import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/onchain_operation.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../../../../amount/amount_input.dart';
import '../../../modal_bottom_sheet.dart';
import '../../payment_method/escrow_selector/escrow_selector.cubit.dart';
import '../../payment_method/escrow_selector/escrow_selector.dart';

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
  EscrowFundOperation? _fundOperation;

  @override
  void initState() {
    super.initState();
    _selectorCubit = EscrowSelectorCubit(
      counterparty: widget.counterparty,
      negotiateReservation: widget.negotiateReservation,
    )..load();
  }

  void _createFundOperation(EscrowService escrow) {
    _fundOperation?.close();
    _fundOperation = getIt<Hostr>().escrow.fund(
      EscrowFundParams(
        negotiateReservation: widget.negotiateReservation,
        amount: widget.negotiateReservation.amount!,
        sellerProfile: widget.counterparty,
        escrowService: escrow,
        listingName: widget.listingName,
      ),
    );
  }

  @override
  void dispose() {
    _selectorCubit.close();
    _fundOperation?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _selectorCubit,
      child: BlocConsumer<EscrowSelectorCubit, EscrowSelectorState>(
        listener: (context, state) {
          if (state is EscrowSelectorLoaded && state.selectedEscrow != null) {
            setState(() => _createFundOperation(state.selectedEscrow!));
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

          final op = _fundOperation;
          if (selectorState is! EscrowSelectorLoaded || op == null) {
            return OnchainTransactionSheet.loading(title: 'Deposit Funds');
          }

          return BlocProvider<EscrowFundOperation>.value(
            value: op,
            child: BlocBuilder<EscrowFundOperation, OnchainOperationState>(
              builder: (context, fundState) => switch (fundState) {
                OnchainInitialised() => EscrowFundConfirmWidget(
                  key: ObjectKey(op),
                  onConfirm: () async {
                    await _selectorCubit.select();
                    op.execute();
                  },
                ),
                _ => EscrowFundFlowWidget(cubit: op),
              },
            ),
          );
        },
      ),
    );
  }
}

class EscrowFundConfirmWidget extends StatefulWidget {
  final Future<void> Function() onConfirm;
  const EscrowFundConfirmWidget({required this.onConfirm, super.key});

  @override
  State<EscrowFundConfirmWidget> createState() =>
      _EscrowFundConfirmWidgetState();
}

class _EscrowFundConfirmWidgetState extends State<EscrowFundConfirmWidget> {
  bool _loading = false;
  late final Future _feeEstimate;

  @override
  void initState() {
    super.initState();
    _feeEstimate = context.read<EscrowFundOperation>().estimateFees();
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
          EscrowSelectorWidget(),
          Gap.vertical.md(),
          AmountWidget(
            amount: context.read<EscrowFundOperation>().params!.amount,
            loading: _loading,
            feeWidget: FutureBuilder(
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "+ ${formatAmount(snapshot.data!.networkFees.toAmount())} in network fees",
                      style: subtleStyle,
                    ),
                    Text(
                      "+ ${formatAmount(snapshot.data!.estimatedEscrowFees.toAmount())} in escrow fees",
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

/// Lightweight flow widget that renders the state of an already-running
/// [EscrowFundOperation]. Unlike [EscrowFundWidget], no escrow selector or
/// confirm step is shown — only in-progress / success / failure UI.
///
/// Use this when re-attaching to an operation obtained from
/// [EscrowFundRegistry] (e.g. when the user navigated away and came back).
class EscrowFundFlowWidget extends StatelessWidget {
  final EscrowFundOperation cubit;
  const EscrowFundFlowWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return OnchainOperationFlowWidget(
      cubit: cubit,
      broadcastBuilder: (s) => OnchainTransactionSheet.broadcast(
        title: 'Depositing Funds',
        subtitle: s.data.txHash != null
            ? 'Waiting for on-chain confirmation...'
            : 'Submitting deposit transaction...',
      ),
      confirmedBuilder: (_) => OnchainTransactionSheet.success(
        title: 'Deposit Success',
        subtitle: 'Funds have been deposited into the escrow.',
      ),
      errorBuilder: (s) =>
          OnchainTransactionSheet.error(s, title: 'Escrow Failed'),
    );
  }
}
