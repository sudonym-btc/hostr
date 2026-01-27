import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/logic/workflows/lnurl_workflow.dart';
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
  final NwcService nwcService;

  ZapPaymentCubit({required super.params, required this.nwcService});

  @override
  Future<LightningCompletedDetails> complete() async {
    ZapResponse response = await nwcService.zap(
      lnurl: state.params.to,
      amountSats: state.params.amount!.value * btcSatoshiFactor,
    );
    return LightningCompletedDetails(
      preimage: response.payInvoiceResponse!.preimage!,
    );
  }
}
