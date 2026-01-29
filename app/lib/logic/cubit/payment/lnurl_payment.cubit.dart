import 'package:hostr/data/sources/nostr/nostr/usecase/nwc/nwc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/workflows/lnurl_workflow.dart';
import 'package:hostr/main.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' hide Nwc;

class LnUrlPaymentParameters extends PaymentParameters {
  LnUrlPaymentParameters({super.amount, super.comment, required super.to});
}

// LnUrlResolvedDetails, LightningCallbackDetails, LightningCompletedDetails
// are now in lnurl_workflow.dart

@Injectable(env: Env.allButTestAndMock)
class LnUrlPaymentCubit
    extends
        PaymentCubit<
          LnUrlPaymentParameters,
          LnUrlResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  final LnUrlWorkflow _workflow;
  final Nwc nwc;

  LnUrlPaymentCubit({
    @factoryParam required super.params,
    required LnUrlWorkflow workflow,
    required this.nwc,
  }) : _workflow = workflow;

  @override
  Future<LnUrlResolvedDetails> resolver() async {
    return await _workflow.resolveLnUrl(to: params.to);
  }

  @override
  Future<LightningCallbackDetails> callback() async {
    if (state.resolvedDetails == null || state.params.amount == null) {
      throw Exception('Must resolve before callback');
    }

    _workflow.validateAmount(
      amount: state.params.amount!,
      minAmount: state.resolvedDetails!.minAmount,
      maxAmount: state.resolvedDetails!.maxAmount,
    );

    return await _workflow.fetchInvoice(
      callbackUrl: state.resolvedDetails!.callback,
      amount: state.params.amount!,
      comment: state.params.comment,
    );
  }

  @override
  Future<LightningCompletedDetails> complete() async {
    PayInvoiceResponse response = await nwc.payInvoice(
      nwc.connections[0].connection!,
      state.callbackDetails!.invoice.paymentRequest,
      null,
    );
    return LightningCompletedDetails(preimage: response.preimage!);
  }
}

// MockLnUrlPaymentCubit removed - use mocked LnUrlWorkflow in tests instead
