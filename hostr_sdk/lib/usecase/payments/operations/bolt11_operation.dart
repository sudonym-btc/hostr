import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' hide Nwc;

import 'pay_models.dart';
import 'pay_operation.dart';

class Bolt11PayParameters extends PayParameters {
  Bolt11PayParameters({super.amount, super.comment, required super.to});
}

@Injectable(env: Env.allButTestAndMock)
class Bolt11PayOperation
    extends
        PayOperation<
          Bolt11PayParameters,
          ResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  Bolt11PayOperation({@factoryParam required super.params, required super.nwc});

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
  Future<LightningCallbackDetails> finalizer() async {
    return LightningCallbackDetails(invoice: Bolt11PaymentRequest(params.to));
  }

  @override
  Future<LightningCompletedDetails> completer() async {
    PayInvoiceResponse response = await nwc.payInvoice(
      nwc.connections[0].connection!,
      callbackDetails!.invoice.paymentRequest,
    );
    return LightningCompletedDetails(preimage: response.preimage!);
  }
}
