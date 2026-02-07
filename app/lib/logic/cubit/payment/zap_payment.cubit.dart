import 'package:hostr/main.dart';
import 'package:ndk/ndk.dart';

class ZapPaymentParameters extends PaymentParameters {
  String? a;
  String? e;

  ZapPaymentParameters({
    super.amount,
    super.comment,
    required super.to,
    this.a,
    this.e,
  });
}

class ZapResolvedDetails extends ResolvedDetails {
  final String callback;

  ZapResolvedDetails({
    required super.minAmount,
    required super.maxAmount,
    required super.commentAllowed,
    required this.callback,
  });
}

// Callback/completed details are defined in LnUrlWorkflow

class ZapPaymentCubit
    extends
        PaymentCubit<
          ZapPaymentParameters,
          LnUrlResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  final Hostr hostr;

  ZapPaymentCubit({required super.params, required this.hostr});

  @override
  Future<LightningCompletedDetails> complete() async {
    ZapResponse response = await hostr.zaps.zap(
      lnurl: state.params.to,
      amountSats: state.params.amount!.getInSats.toInt(),
    );
    return LightningCompletedDetails(
      preimage: response.payInvoiceResponse!.preimage!,
    );
  }
}
