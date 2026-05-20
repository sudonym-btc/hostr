import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:injectable/injectable.dart' hide Order;

import '../../../injection.dart';
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
  Bolt11PayOperation({
    @factoryParam required super.params,
    required super.nwc,
    required super.logger,
  });

  @override
  Future<ResolvedDetails> resolver() async {
    Bolt11PaymentRequest pr = Bolt11PaymentRequest(params.to);

    // pr.amount is in BTC (Decimal). Convert to satoshis for internal use.
    final amountSats = (double.parse(pr.amount.toString()) * 1e8).round();

    return ResolvedDetails(
      minAmount: amountSats,
      maxAmount: amountSats,
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
