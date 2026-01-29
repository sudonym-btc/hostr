import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/workflows/lnurl_workflow.dart';
import 'package:hostr/main.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

class Bolt11PaymentParameters extends PaymentParameters {
  Bolt11PaymentParameters({super.amount, super.comment, required super.to});
}

@Injectable(env: Env.allButTestAndMock)
class Bolt11PaymentCubit
    extends
        PaymentCubit<
          Bolt11PaymentParameters,
          ResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  final Hostr hostr;
  final LnUrlWorkflow workflow;

  Bolt11PaymentCubit({
    @factoryParam required super.params,
    required this.hostr,
    required this.workflow,
  });

  @override
  Future<ResolvedDetails> resolver() async {
    Bolt11PaymentRequest pr = Bolt11PaymentRequest(params.to);

    return ResolvedDetails(
      minAmount: pr.amount.toBigInt().toInt(),
      maxAmount: pr.amount.toBigInt().toInt(),
      commentAllowed: 0,
    );
  }

  @override
  Future<LightningCallbackDetails> callback() async {
    return LightningCallbackDetails(invoice: Bolt11PaymentRequest(params.to));
  }

  @override
  Future<LightningCompletedDetails> complete() async {
    PayInvoiceResponse response = await hostr.nwc.payInvoice(
      state.callbackDetails!.invoice.paymentRequest,
      null,
    );
    return LightningCompletedDetails(preimage: response.preimage!);
  }
}
