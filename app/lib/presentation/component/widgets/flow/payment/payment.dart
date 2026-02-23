import 'package:date_count_down/date_count_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/amount/amount.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_operation.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:models/main.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modal_bottom_sheet.dart';

class PaymentFlowWidget extends StatelessWidget {
  final PayOperation cubit;
  const PaymentFlowWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
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
      case PayResolved():
      case PayCallbackComplete():
      default:
        return PaymentConfirmWidget();
    }
  }
}

class PaymentConfirmWidget extends StatelessWidget {
  const PaymentConfirmWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PayOperation, PayState>(
      builder: (context, state) {
        final resolved = state is PayResolved ? state : null;
        final effectiveMin = resolved?.effectiveMinAmount ?? 0;
        final effectiveMax = resolved?.effectiveMaxAmount ?? 0;
        final isEditable = resolved != null && effectiveMin < effectiveMax;
        final currentAmount =
            state.params.amount?.toAmount() ??
            Amount(currency: Currency.BTC, value: BigInt.from(0));

        final isReady = state is PayResolved;
        final isCallbackComplete = state is PayCallbackComplete;
        final isLoading = state is PayCallbackInitiated || state is PayInFlight;

        return ModalBottomSheet(
          type: ModalBottomSheetType.normal,
          title: 'Payment',
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
              AmountWidget(
                to: state.params.to,
                amount: currentAmount,
                loading: isLoading,
                onAmountTap: isEditable
                    ? () async {
                        final minSats = (effectiveMin + 999) ~/ 1000;
                        final maxSats = effectiveMax ~/ 1000;
                        final result = await AmountEditorBottomSheet.show(
                          context,
                          initialAmount: currentAmount,
                          minAmount: Amount(
                            currency: Currency.BTC,
                            value: BigInt.from(minSats),
                          ),
                          maxAmount: Amount(
                            currency: Currency.BTC,
                            value: BigInt.from(maxSats),
                          ),
                        );
                        if (result != null && context.mounted) {
                          context.read<PayOperation>().updateAmount(
                            BitcoinAmount.fromAmount(result),
                          );
                        }
                      }
                    : null,
                onConfirm: () async {
                  if (isReady) {
                    final cubit = context.read<PayOperation>();
                    await cubit.finalize();
                    await cubit.complete();
                  } else if (isCallbackComplete) {
                    context.read<PayOperation>().complete();
                  }
                },
              ),
            ],
          ),
        );
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
      title: 'Payment',
      subtitle: 'Processing payment...',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap.vertical.md(),
          const CircularProgressIndicator(),
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
      title: 'Pay Invoice',
      subtitle: 'Pay this lightning invoice to continue',
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
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CountDownText(
                      due: DateTime.fromMillisecondsSinceEpoch(
                        (unixUntilExpired * 1000).toInt(),
                      ),
                      finishedText: "Expired",
                      showLabel: false,
                      longDateName: true,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withAlpha(150),
                      ),
                    ),
                    Gap.vertical.custom(6),

                    Expanded(
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
                          child: Text('Copy'),
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
                                      } else {
                                        // Optionally show a message or fallback
                                      }
                                    },
                                    child: Text('Open wallet'),
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
                ),
              );
            default:
              return Text(
                'Please complete the payment in your connected wallet',
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
      title: 'Payment Complete',
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
      title: 'Payment Failed',
      content: Text(state.error.toString()),
    );
  }
}
