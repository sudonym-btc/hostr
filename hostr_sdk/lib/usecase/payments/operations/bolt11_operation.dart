import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';

import 'pay_models.dart';
import 'pay_operation.dart';

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
    final preimage = await settleInvoice(
      callbackDetails!.invoice.paymentRequest,
    );
    if (preimage == null) {
      // settleInvoice already emitted PayExternalRequired; throw to
      // prevent complete() from emitting PayCompleted on top.
      throw StateError('External payment required');
    }
    return LightningCompletedDetails(preimage: preimage);
  }
}
