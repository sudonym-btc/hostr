import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/main.dart';
import 'package:ndk/ndk.dart';

class ZapPaymentParameters extends PaymentParameters {
  String? a;
  String? e;

  ZapPaymentParameters(
      {super.amount, super.comment, required super.to, this.a, this.e});
}

class ZapResolvedDetails extends ResolvedDetails {
  final String callback;

  ZapResolvedDetails(
      {required super.minAmount,
      required super.maxAmount,
      required super.commentAllowed,
      required this.callback});
}

class LightningCallbackDetails extends CallbackDetails {
  final Bolt11PaymentRequest invoice;
  LightningCallbackDetails({required this.invoice});
}

class LightningCompletedDetails extends CompletedDetails {
  final String preimage;
  LightningCompletedDetails({required this.preimage});
}

class ZapPaymentCubit extends PaymentCubit<ZapPaymentParameters,
    LnUrlResolvedDetails, LightningCallbackDetails, LightningCompletedDetails> {
  ZapPaymentCubit({required super.params});

  @override
  Future<LightningCompletedDetails> complete() async {
    ZapResponse response = await getIt<NwcService>().zap(
        lnurl: state.params.to,
        amountSats: state.params.amount!.value * btcSatoshiFactor);
    return LightningCompletedDetails(
        preimage: response.payInvoiceResponse!.preimage);
  }
}
