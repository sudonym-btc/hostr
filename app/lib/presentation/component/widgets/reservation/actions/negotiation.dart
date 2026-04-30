import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/app_spacing_theme.dart';
import 'package:hostr/presentation/component/widgets/amount/amount_input.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/fund/escrow_fund.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_controls.dart';
import 'package:hostr/presentation/component/widgets/ui/app_button_styles.dart';
import 'package:hostr/presentation/component/widgets/ui/app_chip.dart';
import 'package:hostr/presentation/component/widgets/ui/future_button.dart';
import 'package:hostr/presentation/component/widgets/ui/gap.dart';
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
    final registry = getIt<Hostr>().swapInTracker;
    final spacing = AppSpacing.of(context);
    return Padding(
      padding: EdgeInsets.only(top: spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TradeMetaRail(
            amount: Row(
              children: [
                Text(
                  formatAmount(tradeState.amount!, exact: false),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_statusMessage != null) ...[
                  Gap.horizontal.md(),
                  _statusChip(context, message: _statusMessage!),
                ],
              ],
            ),
            actions: StreamBuilder<SwapInOperation?>(
              stream: registry.watchForParent(tradeState.tradeId),
              builder: (context, snapshot) {
                final activeSwap = snapshot.data;
                return TradeActionBar(
                  children: [
                    if (hasCancel)
                      KeyedSubtree(
                        key: const ValueKey('trade_request_cancel_button'),
                        child: _cancelButton(context),
                      ),
                    if (hasCounter && activeSwap == null)
                      KeyedSubtree(
                        key: const ValueKey('trade_action_counter'),
                        child: _counterButton(context),
                      ),
                    if (hasPay)
                      KeyedSubtree(
                        key: const ValueKey('trade_action_pay'),
                        child: _payButton(context, activeSwap: activeSwap),
                      )
                    else if (hasAccept)
                      _acceptButton(context),
                  ],
                );
              },
            ),
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
        latestAmount.denomination == listingPrice.denomination &&
        latestAmount.value < listingPrice.value;
    final isAtListingPrice =
        latestAmount != null &&
        latestAmount.denomination == listingPrice.denomination &&
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
    return AppChip.neutral.xs(label: Text(message));
  }

  // ─── Button helpers ────────────────────────────────────────────────

  Widget _cancelButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trade = context.read<Trade>();
    final destructiveStyle = AppButtonStyles.destructive(context);

    return TextButton(
      key: ValueKey('trade_request_cancel_button_${trade.tradeId}'),
      onPressed: () {
        showAppModal(
          context,
          builder: (modalContext) => ModalBottomSheet(
            title: l10n.cancelReservation,
            subtitle: l10n.areYouSure,
            content: const SizedBox.shrink(),
            buttons: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FutureButton.filled(
                  key: ValueKey(
                    'trade_request_cancel_confirm_button_${trade.tradeId}',
                  ),
                  style: destructiveStyle,
                  onPressed: () async {
                    await trade.execute(TradeAction.cancel);
                    if (modalContext.mounted) {
                      Navigator.of(modalContext).pop();
                    }
                  },
                  child: Text(l10n.ok),
                ),
              ],
            ),
          ),
        );
      },
      style: AppButtonStyles.text(context).copyWith(
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.error,
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Cancel'),
    );
  }

  Widget _payButton(
    BuildContext context, {
    required SwapInOperation? activeSwap,
  }) {
    final tradeId = context.read<Trade>().tradeId;
    if (activeSwap != null) {
      return FilledButton(
        key: ValueKey('trade_action_pay_$tradeId'),
        onPressed: () {
          showAppModal(
            context,
            builder: (_) => SwapInFlowWidget(cubit: activeSwap),
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
      key: ValueKey('trade_action_pay_$tradeId'),
      onPressed:
          tradeState.sellerProfile == null ||
              tradeState.sellerEvmAddress == null
          ? null
          : () => showAppModal(
              context,
              useRootNavigator: true,
              builder: (_) => EscrowFundWidget(
                counterparty: tradeState.sellerProfile!,
                sellerEvmAddress: tradeState.sellerEvmAddress!,
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
    key: ValueKey('trade_action_counter_${context.read<Trade>().tradeId}'),
    onPressed: () => _showCounterOfferSheet(context),
    child: const Text('Counter'),
  );

  void _showCounterOfferSheet(BuildContext context) {
    final trade = context.read<Trade>();
    final submitCounter = trade.counter;
    showAppModal(
      context,
      builder: (_) => _CounterOfferSheet(
        tradeId: trade.tradeId,
        initialAmount: policy.counterMin ?? tradeState.amount!,
        minAmount: policy.counterMin,
        maxAmount: policy.counterMax,
        onSubmit: submitCounter,
      ),
    );
  }
}

class _CounterOfferSheet extends StatefulWidget {
  final String tradeId;
  final DenominatedAmount initialAmount;
  final DenominatedAmount? minAmount;
  final DenominatedAmount? maxAmount;
  final Future<void> Function(DenominatedAmount amount) onSubmit;

  const _CounterOfferSheet({
    required this.tradeId,
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
  final _amountFieldKey = GlobalKey<FormFieldState<DenominatedAmount>>();
  late DenominatedAmount _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
  }

  bool get _isValid => _validateAmount(_amount) == null;

  List<DenominatedAmount> get _minimums => [
    if (widget.minAmount != null) widget.minAmount!,
    ...listingPricesMin,
  ];

  List<DenominatedAmount> get _maximums => [
    if (widget.maxAmount != null) widget.maxAmount!,
  ];

  String? _validateAmount(DenominatedAmount? amount) {
    if (amount == null) {
      return 'Please enter a counter amount';
    }
    final effectiveMin = highestComparableAmount(amount, _minimums);
    if (amountIsBelowLimit(amount, effectiveMin)) {
      return 'Amount must be at least ${formatAmount(effectiveMin!)}';
    }
    final effectiveMax = lowestComparableAmount(amount, _maximums);
    if (amountIsAboveLimit(amount, effectiveMax)) {
      return 'Amount must be at most ${formatAmount(effectiveMax!)}';
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
        child: KeyedSubtree(
          key: const ValueKey('trade_counter_amount_input'),
          child: KeyedSubtree(
            key: ValueKey('trade_counter_amount_input_${widget.tradeId}'),
            child: AmountInputWidget(
              key: _amountFieldKey,
              initialValue: _amount,
              min: _minimums,
              max: _maximums,
            ),
          ),
        ),
      ),
      buttons: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          KeyedSubtree(
            key: const ValueKey('trade_counter_submit_button'),
            child: FutureButton.filled(
              key: ValueKey('trade_counter_submit_button_${widget.tradeId}'),
              onPressed: _isValid ? _submit : null,
              child: const Text('Counter'),
            ),
          ),
        ],
      ),
    );
  }
}
