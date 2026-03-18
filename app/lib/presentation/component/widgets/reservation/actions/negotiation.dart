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
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class NegotiationWidget extends StatelessWidget {
  final TradeReady tradeState;
  const NegotiationWidget({super.key, required this.tradeState});

  NegotiationStage get negotiationStage => tradeState.stage as NegotiationStage;
  NegotiationPolicy get policy => negotiationStage.policy;

  @override
  Widget build(BuildContext context) {
    final hasCancel = tradeState.actions.contains(TradeAction.cancel);
    final hasCounter = tradeState.actions.contains(TradeAction.counter);
    final hasPay = tradeState.actions.contains(TradeAction.pay);
    final hasAccept = tradeState.actions.contains(TradeAction.accept);
    final registry = getIt<Hostr>().escrowFundRegistry;
    return CustomPadding(
      top: 0,
      bottom: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      formatAmount(tradeState.amount!, exact: false),
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.6,
                    ),
                    child: StreamBuilder<EscrowFundOperation?>(
                      stream: registry.watchTrade(tradeState.tradeId),
                      initialData: registry.hasActiveFund(tradeState.tradeId)
                          ? null
                          : null,
                      builder: (context, snapshot) {
                        final activeOp = snapshot.data;
                        return Wrap(
                          spacing: kSpace2,
                          runSpacing: kSpace2,
                          alignment: WrapAlignment.end,
                          children: [
                            if (_statusMessage != null)
                              _statusChip(context, message: _statusMessage!),
                            if (hasCancel) _cancelButton(context),
                            if (hasCounter && activeOp == null)
                              _counterButton(context),
                            if (hasPay)
                              _payButton(context, activeOp: activeOp)
                            else if (hasAccept)
                              _acceptButton(context),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String? get _statusMessage {
    final latestOffer = policy.latestOffer;
    final listingPrice = policy.listingPrice;
    if (latestOffer == null || listingPrice == null) {
      return null;
    }

    final latestAmount = latestOffer.amount;
    final isBelowListing =
        latestAmount != null &&
        latestAmount.currency == listingPrice.currency &&
        latestAmount.value < listingPrice.value;
    final isAtListingPrice =
        latestAmount != null &&
        latestAmount.currency == listingPrice.currency &&
        latestAmount.value == listingPrice.value;

    switch (tradeState.role) {
      case TradeRole.guest:
        if (policy.latestOfferSentByUs && isBelowListing) {
          return 'Awaiting host response';
        }
        return null;
      case TradeRole.host:
        if (isAtListingPrice || policy.latestOfferAcceptsPrevious) {
          return 'Awaiting payment';
        }
        if (policy.latestOfferSentByUs) {
          return 'Awaiting guest response';
        }
        return null;
    }
  }

  Widget _statusChip(BuildContext context, {required String message}) {
    return AppSurface(
      steps: 1,
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // ─── Button helpers ────────────────────────────────────────────────

  Widget _cancelButton(BuildContext context) => OutlinedButton(
    key: const ValueKey('trade_action_cancel'),
    onPressed: () {
      showAppModal(
        context,
        builder: (_) => ModalBottomSheet(
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

  Widget _payButton(
    BuildContext context, {
    required EscrowFundOperation? activeOp,
  }) {
    if (activeOp != null) {
      return FilledButton(
        key: const ValueKey('trade_action_pay'),
        onPressed: () {
          showAppModal(
            context,
            builder: (_) => EscrowFundFlowWidget(cubit: activeOp),
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
              builder: (_) => EscrowFundWidget(
                counterparty: tradeState.hostProfile!,
                negotiateReservation: (tradeState.stage as NegotiationStage)
                    .reservationRequests
                    .last,
                listingName: tradeState.listing.title,
              ),
            ),
      child: const Text('Pay'),
    );
  }

  Widget _acceptButton(BuildContext context) => FutureButton.filled(
    key: const ValueKey('trade_action_accept'),
    onPressed: () => context.read<Trade>().execute(TradeAction.accept),
    child: const Text('Accept'),
  );

  Widget _counterButton(BuildContext context) => OutlinedButton(
    key: const ValueKey('trade_action_counter'),
    onPressed: () => _showCounterOfferSheet(context),
    child: const Text('Counter'),
  );

  void _showCounterOfferSheet(BuildContext context) {
    final submitCounter = context.read<Trade>().counter;
    showAppModal(
      context,
      builder: (_) => _CounterOfferSheet(
        initialAmount: policy.counterMin ?? tradeState.amount!,
        minAmount: policy.counterMin,
        maxAmount: policy.counterMax,
        onSubmit: submitCounter,
      ),
    );
  }
}

class _CounterOfferSheet extends StatefulWidget {
  final Amount initialAmount;
  final Amount? minAmount;
  final Amount? maxAmount;
  final Future<void> Function(Amount amount) onSubmit;

  const _CounterOfferSheet({
    required this.initialAmount,
    required this.onSubmit,
    this.minAmount,
    this.maxAmount,
  });

  @override
  State<_CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends State<_CounterOfferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountFieldKey = GlobalKey<FormFieldState<Amount>>();
  late Amount _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
  }

  bool get _isValid => _validateAmount(_amount) == null;

  String? _validateAmount(Amount? amount) {
    if (amount == null) {
      return 'Please enter a counter amount';
    }
    if (widget.minAmount != null && amount.value < widget.minAmount!.value) {
      return 'Amount must be at least ${formatAmount(widget.minAmount!)}';
    }
    if (widget.maxAmount != null && amount.value > widget.maxAmount!.value) {
      return 'Amount must be at most ${formatAmount(widget.maxAmount!)}';
    }
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    await widget.onSubmit(_amount);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      title: 'Counter offer',
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        onChanged: () {
          final amount = _amountFieldKey.currentState?.value;
          if (amount != null) {
            setState(() => _amount = amount);
          } else {
            setState(() {});
          }
        },
        child: AmountInputWidget(
          key: _amountFieldKey,
          initialValue: _amount,
          min: widget.minAmount,
          max: widget.maxAmount,
        ),
      ),
      buttons: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FutureButton.filled(
            onPressed: _isValid ? _submit : null,
            child: const Text('Counter'),
          ),
        ],
      ),
    );
  }
}
