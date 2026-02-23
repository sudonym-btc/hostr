import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../../../../amount/amount_input.dart';
import '../../../../ui/asymptotic_progress_bar.dart';
import '../../../modal_bottom_sheet.dart';
import '../../payment_method/escrow_selector/escrow_selector.cubit.dart';
import '../../payment_method/escrow_selector/escrow_selector.dart';

class EscrowFundWidget extends StatefulWidget {
  final ProfileMetadata counterparty;
  final ReservationRequest reservationRequest;

  const EscrowFundWidget({
    super.key,
    required this.counterparty,
    required this.reservationRequest,
  });

  @override
  State<EscrowFundWidget> createState() => _EscrowFundWidgetState();
}

class _EscrowFundWidgetState extends State<EscrowFundWidget> {
  late final EscrowSelectorCubit _selectorCubit;
  EscrowFundOperation? _fundOperation;
  late final StreamSubscription<EscrowSelectorState> _selectorSub;

  @override
  void initState() {
    super.initState();
    _selectorCubit = EscrowSelectorCubit(
      counterparty: widget.counterparty,
      reservationRequest: widget.reservationRequest,
    )..load();
    _selectorSub = _selectorCubit.stream.listen(_onSelectorChanged);
  }

  void _onSelectorChanged(EscrowSelectorState state) {
    if (state is EscrowSelectorLoaded && state.selectedEscrow != null) {
      _createFundOperation(state.selectedEscrow!);
    }
  }

  void _createFundOperation(EscrowService escrow) {
    _fundOperation?.close();
    setState(() {
      _fundOperation = getIt<Hostr>().escrow.fund(
        EscrowFundParams(
          reservationRequest: widget.reservationRequest,
          amount: widget.reservationRequest.parsedContent.amount,
          sellerProfile: widget.counterparty,
          escrowService: escrow,
        ),
      );
    });
  }

  @override
  void dispose() {
    _selectorSub.cancel();
    _fundOperation?.close();
    _selectorCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _selectorCubit,
      child: BlocBuilder<EscrowSelectorCubit, EscrowSelectorState>(
        builder: (context, selectorState) {
          switch (selectorState) {
            case EscrowSelectorLoading():
              return ModalBottomSheet(
                type: ModalBottomSheetType.normal,
                title: 'Deposit Funds',
                content: Center(child: CircularProgressIndicator()),
              );
            case EscrowSelectorError():
              return ModalBottomSheet(
                type: ModalBottomSheetType.error,
                title: 'Deposit Funds',
                content: Text(selectorState.message),
              );
            case EscrowSelectorLoaded():
              if (_fundOperation == null) {
                return ModalBottomSheet(
                  type: ModalBottomSheetType.normal,
                  title: 'Deposit Funds',
                  content: Center(child: CircularProgressIndicator()),
                );
              }
              return BlocProvider<EscrowFundOperation>.value(
                value: _fundOperation!,
                child: BlocBuilder<EscrowFundOperation, EscrowFundState>(
                  builder: (context, fundState) {
                    switch (fundState) {
                      case EscrowFundInitialised():
                        return EscrowFundConfirmWidget(
                          onConfirm: () async {
                            await _selectorCubit.select();
                            _fundOperation!.execute();
                          },
                        );
                      case EscrowFundDepositing():
                        return EscrowFundDepositingWidget(fundState);
                      case EscrowFundSwapProgress():
                        return EscrowFundProgressWidget(fundState);
                      case EscrowFundCompleted():
                        return EscrowFundSuccessWidget(fundState);
                      case EscrowFundFailed():
                        return EscrowFundFailureWidget(fundState);
                    }
                  },
                ),
              );
            default:
              throw UnimplementedError();
          }
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
          SizedBox(height: 16),
          AmountWidget(
            amount: context.read<EscrowFundOperation>().params.amount,
            loading: _loading,
            feeWidget: FutureBuilder(
              future: context.read<EscrowFundOperation>().estimateFees(),
              builder: (context, snapshot) {
                final baseStyle = Theme.of(context).textTheme.bodySmall!;
                final subtleStyle = baseStyle.copyWith(
                  fontWeight: FontWeight.w400,
                  color: baseStyle.color?.withValues(alpha: 0.6),
                );

                if (snapshot.connectionState != ConnectionState.done) {
                  return Text('Estimating fees...', style: subtleStyle);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "+ ${formatAmount(snapshot.data!.estimatedGasFees.toAmount())} in gas",
                      style: subtleStyle,
                    ),
                    Text(
                      "+ ${formatAmount(snapshot.data!.estimatedSwapFees.totalFees.toAmount())} in swap fees",
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
  final EscrowFundSwapProgress progress;
  const EscrowFundProgressWidget(this.progress, {super.key});

  @override
  Widget build(BuildContext context) {
    return SwapInViewWidget(progress.swapState);
  }
}

class EscrowFundDepositingWidget extends StatelessWidget {
  final EscrowFundDepositing state;
  const EscrowFundDepositingWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: 'Depositing Funds',
      subtitle: state.txHash != null
          ? 'Waiting for on-chain confirmation...'
          : 'Submitting deposit transaction...',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24),
          AsymptoticProgressBar(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class EscrowFundTradeProgressWidget extends StatelessWidget {
  const EscrowFundTradeProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: 'Escrow Trade',
      subtitle: 'Escrow trade in progress...',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16),
          CircularProgressIndicator(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class EscrowFundSuccessWidget extends StatelessWidget {
  final EscrowFundCompleted state;
  const EscrowFundSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: 'Deposit Success',
      subtitle: 'Funds have been deposited into the escrow.',
      content: Container(),
    );
  }
}

class EscrowFundFailureWidget extends StatelessWidget {
  final EscrowFundFailed state;
  const EscrowFundFailureWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      title: 'Escrow Failed',
      content: Text(state.error.toString()),
    );
  }
}
