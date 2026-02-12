import 'package:hostr_sdk/usecase/payments/operations/pay_operation.dart';
import 'package:ndk/ndk.dart';

import 'pay_models.dart';

class ZapPayParameters extends PayParameters {
  String? a;
  String? e;

  ZapPayParameters({
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

class ZapPayOperation
    extends
        PayOperation<
          ZapPayParameters,
          LnUrlResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  final Zaps zaps;

  ZapPayOperation({
    required super.params,
    required this.zaps,
    required super.nwc,
  });

  @override
  Future<LightningCompletedDetails> completer() async {
    throw UnimplementedError('Zap completer not implemented yet');
    // ZapResponse response = await zaps.zap(
    //   nwcConnection: nwc.connections[0].connection!,
    //   lnurl: state.params.to,
    //   amountSats: state.params.amount!.getInSats.toInt(),
    // );
    // return LightningCompletedDetails(
    //   preimage: response.payInvoiceResponse!.preimage!,
    // );
  }

  @override
  Future<LightningCallbackDetails> finalizer() {
    // TODO: implement finalizer
    throw UnimplementedError();
  }

  @override
  Future<LnUrlResolvedDetails> resolver() {
    // TODO: implement resolver
    throw UnimplementedError();
  }
}
