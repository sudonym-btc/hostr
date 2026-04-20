import 'package:date_count_down/date_count_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/forms/amount_field_controller.dart';
import 'package:hostr/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modal_bottom_sheet.dart';

class PaymentFlowWidget extends StatefulWidget {
  final PayOperation cubit;
  const PaymentFlowWidget({super.key, required this.cubit});

  @override
  State<PaymentFlowWidget> createState() => _PaymentFlowWidgetState();
}

class _PaymentFlowWidgetState extends State<PaymentFlowWidget> {
  @override
  void dispose() {
    // Allow in-flight payments to complete before closing the cubit.
    widget.cubit.detachOrClose(
      (s) => s is PayCompleted || s is PayFailed || s is PayCancelled,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<PayOperation, PayState>(
        builder: (context, state) {
          return PaymentViewWidget(state);
        },
      ),
    );
  }
}

class PaymentViewWidget extends StatelessWidget {
  final PayState state;
  final VoidCallback? onConfirm;
  const PaymentViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    switch (state) {
      case PayFailed():
        return PaymentFailureWidget(state as PayFailed);
      case PayInFlight():
        return PaymentProgressWidget(state);
      case PayExternalRequired():
        return PaymentExternalRequiredWidget(state);
      case PayCompleted():
        return PaymentSuccessWidget(state);
      case PayInitialised():
      case PayResolveInitiated():
        return PaymentResolveProgressWidget();
      case PayResolved():
      case PayCallbackComplete():
      default:
        return PaymentConfirmWidget();
    }
  }
}

class PaymentConfirmWidget extends StatefulWidget {
  const PaymentConfirmWidget({super.key});

  @override
  State<PaymentConfirmWidget> createState() => _PaymentConfirmWidgetState();
}

class _PaymentConfirmWidgetState extends State<PaymentConfirmWidget> {
  final _formController = _PaymentConfirmFormController();

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(BuildContext context, PayState state) async {
    final form = _formController.formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    form.save();

    final cubit = context.read<PayOperation>();
    if (state is PayResolved) {
      final amount = _formController.amount;
      if (amount != null) {
        cubit.updateAmount(rbtcFromSats(amount.value));
      }
      cubit.updateComment(_formController.comment);
      await cubit.finalize();
      if (cubit.state is PayFailed) return;
      await cubit.complete();
    } else if (state is PayCallbackComplete) {
      await cubit.complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PayOperation, PayState>(
      builder: (context, state) {
        _formController.syncFrom(state.params);

        return ModalBottomSheet(
          type: ModalBottomSheetType.normal,
          title: AppLocalizations.of(context)!.paymentTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder(
                stream: getIt<Hostr>().nwc.connectionsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return CustomPadding.only(
                    bottom: kSpace4,
                    child: NostrWalletConnectConnectionWidget(),
                  );
                },
              ),
              _PaymentConfirmForm(
                controller: _formController,
                state: state,
                onSubmit: () => _handleSubmit(context, state),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PaymentResolveProgressWidget extends StatelessWidget {
  const PaymentResolveProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: AppLocalizations.of(context)!.paymentTitle,
      subtitle: AppLocalizations.of(context)!.loading,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap.vertical.md(),
          const AppLoadingIndicator.large(),
          Gap.vertical.md(),
        ],
      ),
    );
  }
}

class _PaymentConfirmFormController {
  final formKey = GlobalKey<FormState>();
  final AmountFieldController amountController = AmountFieldController();
  final TextEditingController commentController = TextEditingController();
  PayParameters? _params;

  DenominatedAmount? get amount => amountController.amount;

  String? get comment {
    final trimmed = commentController.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void syncFrom(PayParameters params) {
    if (_params == params) {
      return;
    }
    _params = params;
    amountController.setState(
      _normaliseToBtcSats(
        params.amount?.toDenominated() ??
            DenominatedAmount(
              denomination: 'BTC',
              value: BigInt.zero,
              decimals: 8,
            ),
      ),
    );
    commentController.text = params.comment ?? '';
  }

  void dispose() {
    amountController.dispose();
    commentController.dispose();
  }

  static DenominatedAmount _normaliseToBtcSats(DenominatedAmount raw) =>
      raw.decimals != 8 ? raw.rescale(8) : raw;
}

class _PaymentConfirmForm extends StatelessWidget {
  final _PaymentConfirmFormController controller;
  final PayState state;
  final Future<void> Function() onSubmit;

  const _PaymentConfirmForm({
    required this.controller,
    required this.state,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = state is PayResolved ? state as PayResolved : null;
    final effectiveMin = resolved?.effectiveMinAmount ?? 0;
    final effectiveMax = resolved?.effectiveMaxAmount ?? 0;
    final isReady = state is PayResolved;
    final isCallbackComplete = state is PayCallbackComplete;
    final isLoading = state is PayCallbackInitiated || state is PayInFlight;
    final isEditable = resolved != null && effectiveMin < effectiveMax;
    final commentAllowed = resolved?.details.commentAllowed ?? 0;
    final minAmount = effectiveMin > 0
        ? _satsAmount(_msatsToSats(effectiveMin))
        : null;
    final maxAmount = effectiveMax > 0
        ? _satsAmount(effectiveMax ~/ 1000)
        : null;

    return Form(
      key: controller.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.params.to.isNotEmpty) ...[
            Text(
              state.params.to,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.vertical.sm(),
          ],
          AmountTapInput(
            controller: controller.amountController,
            hintText: 'Amount',
            min: minAmount,
            max: maxAmount,
            required: true,
            enabled: isReady && !isLoading,
            editable: isEditable,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (amount) {
              if (amount == null || !isReady) {
                return;
              }
              context.read<PayOperation>().updateAmount(
                rbtcFromSats(amount.value),
              );
            },
          ),
          if (commentAllowed > 0) ...[
            Gap.vertical.sm(),
            _PaymentCommentFormField(
              controller: controller,
              maxLength: commentAllowed,
              enabled: isReady && !isLoading,
            ),
          ],
          Gap.vertical.sm(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: isLoading || (!isReady && !isCallbackComplete)
                    ? null
                    : onSubmit,
                child: isLoading
                    ? AppLoadingIndicator.small(
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _msatsToSats(int msats) => (msats + 999) ~/ 1000;

  DenominatedAmount _satsAmount(int sats) => DenominatedAmount(
    denomination: 'BTC',
    value: BigInt.from(sats),
    decimals: 8,
  );
}

class _PaymentCommentFormField extends StatelessWidget {
  final _PaymentConfirmFormController controller;
  final int maxLength;
  final bool enabled;

  const _PaymentCommentFormField({
    required this.controller,
    required this.maxLength,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller.commentController,
      enabled: enabled,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      minLines: 1,
      maxLines: 2,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: l10n.paymentCommentLabel,
        hintText: l10n.paymentCommentHint,
      ),
      validator: (value) {
        if ((value?.length ?? 0) > maxLength) {
          return 'Comment must be $maxLength characters or fewer';
        }
        return null;
      },
    );
  }
}

class PaymentProgressWidget extends StatelessWidget {
  final PayState state;
  const PaymentProgressWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: AppLocalizations.of(context)!.paymentTitle,
      subtitle: AppLocalizations.of(context)!.processingPayment,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap.vertical.md(),
          const AppLoadingIndicator.large(),
          Gap.vertical.md(),
        ],
      ),
    );
  }
}

class PaymentExternalRequiredWidget extends StatelessWidget {
  final PayState state;
  const PaymentExternalRequiredWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      title: AppLocalizations.of(context)!.payInvoiceTitle,
      subtitle: AppLocalizations.of(context)!.payInvoiceSubtitle,
      content: Builder(
        builder: (context) {
          switch (state.callbackDetails) {
            case LightningCallbackDetails():
              final invoice =
                  (state.callbackDetails! as LightningCallbackDetails).invoice;
              final pr = invoice.paymentRequest;
              final unixUntilExpired =
                  invoice.timestamp.toInt() +
                  invoice.tags.where((e) => e.type == 'expiry').first.data;
              final uri = Uri.parse('lightning:$pr');

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CountDownText(
                    due: DateTime.fromMillisecondsSinceEpoch(
                      (unixUntilExpired * 1000).toInt(),
                    ),
                    finishedText: AppLocalizations.of(context)!.invoiceExpired,
                    showLabel: false,
                    longDateName: true,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error.withAlpha(150),
                    ),
                  ),
                  Gap.vertical.custom(6),

                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final maxHeight = constraints.hasBoundedHeight
                            ? constraints.maxHeight
                            : maxWidth;
                        final side = maxWidth < maxHeight
                            ? maxWidth
                            : maxHeight;

                        return SizedBox.square(
                          dimension: side,

                          // @todo: QRImageView package paints outside of its boundary. Nothing we can do but ensure it has default 10px padding.
                          child: QrImageView(
                            backgroundColor: Colors.transparent,
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            data: pr,
                          ),
                        );
                      },
                    ),
                  ),

                  Gap.vertical.lg(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text:
                                  (state.callbackDetails!
                                          as LightningCallbackDetails)
                                      .invoice
                                      .paymentRequest,
                            ),
                          );
                        },
                        style: AppButtonStyles.secondary(context),
                        child: Text(AppLocalizations.of(context)!.copy),
                      ),
                      FutureBuilder(
                        future: canLaunchUrl(uri),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data == true) {
                            return Row(
                              children: [
                                Gap.horizontal.custom(kSpace3),
                                FilledButton(
                                  onPressed: () async {
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  style: AppButtonStyles.secondary(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.openWallet,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Container();
                        },
                      ),
                    ],
                  ),
                ],
              );
            default:
              return Text(
                AppLocalizations.of(context)!.completePaymentInConnectedWallet,
              );
          }
        },
      ),
    );
  }
}

class PaymentSuccessWidget extends StatelessWidget {
  final PayState state;
  const PaymentSuccessWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.success,
      title: AppLocalizations.of(context)!.paymentCompleteTitle,
      subtitle: AppLocalizations.of(context)!.paymentCompleted,
      content: Container(),
    );
  }
}

class PaymentFailureWidget extends StatelessWidget {
  final PayFailed state;
  const PaymentFailureWidget(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.error,
      title: AppLocalizations.of(context)!.paymentFailedTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.paymentFailed),
          if (state.error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              state.error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
