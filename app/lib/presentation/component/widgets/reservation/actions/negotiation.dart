import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/amount/amount_input.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/fund/escrow_fund.dart';
import 'package:hostr/presentation/component/widgets/ui/future_button.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class NegotiationWidget extends StatelessWidget {
  final TradeReady tradeState;
  const NegotiationWidget({super.key, required this.tradeState});

  @override
  Widget build(BuildContext context) {
    final hasCancel = tradeState.actions.contains(TradeAction.cancel);
    final hasCounter = tradeState.actions.contains(TradeAction.counter);
    final hasPay = tradeState.actions.contains(TradeAction.pay);
    final hasAccept = tradeState.actions.contains(TradeAction.accept);
    return CustomPadding(
      top: 0,
      bottom: 0.5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  formatAmount(tradeState.amount!, exact: false),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.6,
                ),
                child: Wrap(
                  spacing: kSpace2,
                  runSpacing: kSpace2,
                  alignment: WrapAlignment.end,
                  children: [
                    if (hasCancel) _cancelButton(context),
                    if (hasCounter) _counterButton(context),
                    if (hasPay)
                      _payButton(context)
                    else if (hasAccept)
                      _acceptButton(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Button helpers ────────────────────────────────────────────────

  void _showNotImplemented(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.actionNotImplementedYet),
        ),
      );

  Widget _cancelButton(BuildContext context) => OutlinedButton(
    key: const ValueKey('trade_action_cancel'),
    onPressed: () {
      showAppModal(
        context,
        child: ModalBottomSheet(
          title: AppLocalizations.of(context)!.cancelReservation,
          subtitle: AppLocalizations.of(context)!.areYouSure,
          content: const SizedBox.shrink(),
          buttons: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<Trade>().execute(TradeAction.cancel);
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        ),
      );
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
      side: BorderSide(color: Theme.of(context).colorScheme.error),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text('Cancel'),
  );

  Widget _payButton(BuildContext context) {
    final registry = getIt<Hostr>().escrowFundRegistry;
    return StreamBuilder<EscrowFundOperation?>(
      stream: registry.watchTrade(tradeState.tradeId),
      initialData: registry.hasActiveFund(tradeState.tradeId)
          ? null // will resolve on first stream emit
          : null,
      builder: (context, snapshot) {
        final activeOp = snapshot.data;
        if (activeOp != null) {
          return FilledButton(
            key: const ValueKey('trade_action_pay'),
            onPressed: () {
              showAppModal(
                context,
                child: EscrowFundFlowWidget(cubit: activeOp),
              );
            },
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          );
        }
        return FilledButton(
          key: const ValueKey('trade_action_pay'),
          onPressed: tradeState.hostProfile == null
              ? null
              : () => showAppModal(
                  context,
                  child: EscrowFundWidget(
                    counterparty: tradeState.hostProfile!,
                    negotiateReservation: (tradeState.stage as NegotiationStage)
                        .reservationRequests
                        .last,
                    listingName: tradeState.listing.title,
                  ),
                ),
          child: const Text('Pay'),
        );
      },
    );
  }

  Widget _acceptButton(BuildContext context) => FutureButton.outlined(
    key: const ValueKey('trade_action_accept'),
    onPressed: () => context.read<Trade>().execute(TradeAction.accept),
    child: const Text('Accept'),
  );

  Widget _counterButton(BuildContext context) => OutlinedButton(
    key: const ValueKey('trade_action_counter'),
    onPressed: () => _showNotImplemented(context),
    child: const Text('Counter'),
  );
}
