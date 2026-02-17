import 'package:date_count_down/date_count_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/main.dart';
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
        return PaymentConfirmWidget(state: state);
    }
  }
}

class PaymentConfirmWidget extends StatelessWidget {
  final PayState state;
  const PaymentConfirmWidget({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      type: ModalBottomSheetType.normal,
      content: Builder(
        builder: (context) {
          Widget nwcInfo = NostrWalletConnectConnectionWidget();

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              nwcInfo,
              SizedBox(height: kDefaultPadding.toDouble() / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.params.to,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // todo: calc amount from invoice
                        Text(
                          formatAmount(
                            state.params.amount?.toAmount() ??
                                Amount(
                                  currency: Currency.BTC,
                                  value: BigInt.from(0),
                                ),
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  state is PayResolved
                      ? FilledButton(
                          child: Text(AppLocalizations.of(context)!.ok),
                          onPressed: () {
                            context.read<PayOperation>().finalize();
                          },
                        )
                      : (state is PayCallbackComplete
                            ? FilledButton(
                                child: Text(AppLocalizations.of(context)!.pay),
                                onPressed: () {
                                  context.read<PayOperation>().complete();
                                },
                              )
                            : SizedBox.shrink()),
                ],
              ),
            ],
          );
        },
      ),
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
      content: Center(child: CircularProgressIndicator()),
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
                    // CustomPadding(top: 1, bottom: 0),
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
                    CustomPadding(top: 0.2, bottom: 0),

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

                    CustomPadding(top: 1, bottom: 0),

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
                                  SizedBox(width: 12),
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
      content: Text(AppLocalizations.of(context)!.paymentCompleted),
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
      content: Text('Payment failed: ${state.error}'),
    );
  }
}
